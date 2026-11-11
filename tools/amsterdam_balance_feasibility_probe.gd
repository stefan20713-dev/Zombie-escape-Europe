extends Node
var _preview: Node
var _fps: Array[int] = []
func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	_preview = load("res://scenes/amsterdam_preview.tscn").instantiate()
	_preview.workshop_vehicle = "kombi"
	_preview.workshop_upgrades = {"engine": 2, "tires": 2, "tank": 2, "armor": 2, "suspension": 0, "nitro": 1, "weapon": 0}
	get_tree().root.add_child(_preview)
	await get_tree().physics_frame
	var wagon = _preview.wagon
	var course = _preview.course
	# Isolated feasibility experiment only: no project balancing values or saves changed.
	wagon._fuel_use_multiplier *= 0.88
	var capture := 0
	var points: Array[float] = [120.0, 420.0, 830.0, 1290.0, 1760.0]
	var frames := 0
	while not _preview._finished and frames < 7500:
		_key(KEY_W, true)
		var meter: float = wagon.position.x / 36.0
		_key(KEY_SPACE, meter >= course.LOCK_START_M - 75.0 and meter < course.LOCK_REJOIN_M)
		var road_error: float = wrapf(wagon.rotation - course.slope_at(wagon.position.x), -PI, PI)
		var unsteady: bool = wagon.airborne or wagon.front_spring.is_colliding() != wagon.rear_spring.is_colliding() or absf(road_error) > 0.35
		_key(KEY_D, unsteady and road_error < -0.10)
		_key(KEY_A, unsteady and road_error > 0.10)
		await get_tree().physics_frame
		frames += 1
		if frames % 120 == 0:
			if frames > 480:
				_fps.append(Engine.get_frames_per_second())
			print("BALANCE_FUEL_CANDIDATE_PROGRESS distance=", int(_preview.distance_m), " speed_kmh=", int(absf(wagon.speed_mps) * 3.6), " fps=", Engine.get_frames_per_second())
		if DisplayServer.get_name() != "headless" and capture < points.size() and _preview.distance_m > points[capture]:
			get_viewport().get_texture().get_image().save_png("res://build/balance-fuel-candidate-%04d.png" % int(points[capture]))
			capture += 1
	for key in [KEY_W, KEY_SPACE, KEY_A, KEY_D]:
		_key(key, false)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/balance-fuel-candidate-ergebnis.png")
	_fps.sort()
	var median: int = _fps[_fps.size() / 2] if not _fps.is_empty() else 0
	print("BALANCE_FUEL_CANDIDATE_RESULT distance=", _preview.distance_m, " complete=", _preview.distance_m >= 1800.0, " time_s=", _preview.elapsed_s, " fps_median=", median, " fps_min=", _fps[0] if not _fps.is_empty() else 0, " fuel=", wagon.fuel, " durability=", wagon.durability)
	assert(_preview._finished, "Measure the actual result without forcing a finish.")
	get_tree().quit()
func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

