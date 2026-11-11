extends Node

const PREVIEW_SCENE: PackedScene = preload("res://scenes/amsterdam_preview.tscn")
const PPM: float = 36.0
const TARGET_DISTANCE_M: float = 620.0
const UPPER_ROUTE_MIN_SPEED_MPS: float = 120.0 / 3.6

var _keys_down: Dictionary = {}

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	print("AMSTERDAM_UNDERPASS_PROBE_STARTED")
	Engine.time_scale = 1.0
	var preview: Node2D = PREVIEW_SCENE.instantiate() as Node2D
	get_tree().root.add_child(preview)
	await get_tree().process_frame
	await get_tree().physics_frame
	var wagon: EscapeWagon = preview.get_node("Wagon") as EscapeWagon
	var course: AmsterdamPreviewCourse = preview.get_node("Course") as AmsterdamPreviewCourse
	_press_key(KEY_W, true)
	var balance_key: Key = KEY_NONE
	var branch_speed_mps: float = -1.0
	var frames: int = 0
	var stalled_frames: int = 0
	var last_tick_usec: int = Time.get_ticks_usec()
	var frame_gap_samples_ms: Array[float] = []
	var obstacle_frame_gap_samples_ms: Array[float] = []
	var max_process_ms: float = 0.0
	var max_physics_ms: float = 0.0
	var max_draw_calls: int = 0
	var min_fps: float = INF
	while float(preview.get("distance_m")) < TARGET_DISTANCE_M and frames < 7200:
		await get_tree().physics_frame
		var now_usec: int = Time.get_ticks_usec()
		var frame_gap_ms: float = float(now_usec - last_tick_usec) / 1000.0
		last_tick_usec = now_usec
		frames += 1
		var distance_m: float = float(preview.get("distance_m"))
		frame_gap_samples_ms.append(frame_gap_ms)
		if distance_m >= 450.0 and distance_m <= 510.0:
			obstacle_frame_gap_samples_ms.append(frame_gap_ms)
		max_process_ms = maxf(max_process_ms, float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
		max_physics_ms = maxf(max_physics_ms, float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0)
		max_draw_calls = maxi(max_draw_calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		min_fps = minf(min_fps, float(Performance.get_monitor(Performance.TIME_FPS)))
		if bool(course.get("_upper_launch_triggered")) and branch_speed_mps < 0.0:
			branch_speed_mps = wagon.speed_mps
		var road_error: float = wrapf(wagon.global_rotation - course.slope_at(wagon.position.x), -PI, PI)
		var unstable_wheels: bool = wagon.front_spring.is_colliding() != wagon.rear_spring.is_colliding()
		var wanted_key: Key = KEY_NONE
		if wagon.airborne or unstable_wheels or absf(road_error) > 0.35:
			wanted_key = KEY_D if road_error < -0.10 else KEY_A if road_error > 0.10 else KEY_NONE
		if wanted_key != balance_key:
			if balance_key != KEY_NONE:
				_press_key(balance_key, false)
			balance_key = wanted_key
			if balance_key != KEY_NONE:
				_press_key(balance_key, true)
		if absf(wagon.speed_mps) < 0.18 and not wagon.airborne and distance_m > 100.0:
			stalled_frames += 1
		else:
			stalled_frames = 0
		if stalled_frames >= 60:
			break
	if balance_key != KEY_NONE:
		_press_key(balance_key, false)
	_press_key(KEY_W, false)
	var distance_done: float = float(preview.get("distance_m"))
	var branch_decided: bool = bool(course.get("_branch_decided"))
	var upper_route: bool = bool(course.get("_upper_route_chosen"))
	var underpass_x: float = 480.0 * PPM
	var road_y: float = course._base_height_at(underpass_x)
	var bridge_underside_y: float = course.UPPER_BRIDGE_Y + 69.0
	var clearance_px: float = road_y - bridge_underside_y
	var crossed_underpass: bool = distance_done >= TARGET_DISTANCE_M and branch_decided and not upper_route
	var speed_selected_lower: bool = branch_speed_mps >= 0.0 and branch_speed_mps < UPPER_ROUTE_MIN_SPEED_MPS
	print("AMSTERDAM_UNDERPASS_RESULT distance_m=%.1f branch_kmh=%.1f upper_route=%s clearance_px=%.1f crossed=%s frames=%d" % [
		distance_done,
		branch_speed_mps * 3.6,
		str(upper_route),
		clearance_px,
		str(crossed_underpass),
		frames
	])
	print("AMSTERDAM_PERF_TOTAL wall_p95_ms=%.2f wall_max_ms=%.2f" % [
		_percentile(frame_gap_samples_ms, 0.95),
		_max_value(frame_gap_samples_ms)
	])
	print("AMSTERDAM_PERF_OBSTACLES wall_p95_ms=%.2f wall_max_ms=%.2f frames=%d" % [
		_percentile(obstacle_frame_gap_samples_ms, 0.95),
		_max_value(obstacle_frame_gap_samples_ms),
		obstacle_frame_gap_samples_ms.size()
	])
	print("AMSTERDAM_PERF_ENGINE min_fps=%.1f process_max_ms=%.2f physics_max_ms=%.2f" % [
		min_fps,
		max_process_ms,
		max_physics_ms
	])
	print("AMSTERDAM_PERF_RENDER draw_calls_max=%d" % max_draw_calls)
	if not crossed_underpass or not speed_selected_lower or clearance_px < 105.0 or wagon.overturned:
		push_error("Amsterdam's below-120-km/h underpass route did not remain passable.")
		get_tree().quit(1)
		return
	print("AMSTERDAM_UNDERPASS_OK below_120=true lower_route=true bridge_clearance=true")
	get_tree().quit(0)

func _max_value(values: Array[float]) -> float:
	var result: float = 0.0
	for value in values:
		result = maxf(result, value)
	return result

func _percentile(values: Array[float], percentile: float) -> float:
	if values.is_empty():
		return 0.0
	var ordered: Array[float] = values.duplicate()
	ordered.sort()
	var index: int = clampi(int(ceil(float(ordered.size()) * percentile)) - 1, 0, ordered.size() - 1)
	return ordered[index]

func _press_key(keycode: Key, pressed: bool) -> void:
	if bool(_keys_down.get(keycode, false)) == pressed:
		return
	_keys_down[keycode] = pressed
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
