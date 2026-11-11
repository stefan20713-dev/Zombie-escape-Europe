extends Node

const PREVIEW_SCENE: PackedScene = preload("res://scenes/amsterdam_preview.tscn")
const PPM: float = 36.0

var _keys_down: Dictionary = {}

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	print("AMSTERDAM_PREVIEW_PROBE_STARTED")
	Engine.time_scale = 1.0
	var preview: Node2D = PREVIEW_SCENE.instantiate() as Node2D
	preview.set("workshop_vehicle", "kombi")
	preview.set("workshop_upgrades", {"engine": 2, "tires": 2, "tank": 2, "armor": 2, "suspension": 1, "nitro": 2, "weapon": 1})
	get_tree().root.add_child(preview)
	await get_tree().process_frame
	await get_tree().physics_frame
	var wagon: EscapeWagon = preview.get_node("Wagon") as EscapeWagon
	var course: AmsterdamPreviewCourse = preview.get_node("Course") as AmsterdamPreviewCourse
	var capture_written: bool = false
	var action_capture_written: bool = false
	var obstacle_capture_written: bool = false
	var finish_capture_written: bool = false
	var saw_airborne: bool = false
	var did_manual_balance: bool = false
	var active_balance_key: Key = KEY_NONE
	var branch_speed_kmh: float = -1.0
	var frame_count: int = 0
	var stalled_frames: int = 0
	var stall_reported: bool = false
	_press_key(KEY_W, true)
	var camera: Camera2D = preview.get_viewport().get_camera_2d()
	var previous_camera: Vector2 = camera.get_screen_center_position()
	var max_camera_step_px: float = 0.0
	var review: Image = Image.create_empty(1280, 1080, false, Image.FORMAT_RGB8)
	var review_index: int = 0
	while not bool(preview.get("_finished")) and frame_count < 7200:
		await get_tree().physics_frame
		var camera_center: Vector2 = camera.get_screen_center_position()
		max_camera_step_px = maxf(max_camera_step_px, camera_center.distance_to(previous_camera) * camera.zoom.x)
		previous_camera = camera_center
		if DisplayServer.get_name() != "headless" and review_index < 24 and float(preview.get("distance_m")) >= float(review_index) * course.preview_length_m() / 24.0:
			var sample: Image = get_viewport().get_texture().get_image()
			sample.resize(320, 180, Image.INTERPOLATE_LANCZOS)
			sample.convert(Image.FORMAT_RGB8)
			review.blit_rect(sample, Rect2i(0, 0, 320, 180), Vector2i((review_index % 4) * 320, floori(review_index / 4.0) * 180))
			review_index += 1
		frame_count += 1
		var distance_m: float = float(preview.get("distance_m"))
		if DisplayServer.get_name() != "headless" and not finish_capture_written and distance_m >= course.preview_length_m() - 5.0:
			finish_capture_written = true
			var finish_image: Image = get_viewport().get_texture().get_image()
			var finish_error: Error = finish_image.save_png("res://build/amsterdam-zieleinlauf.png")
			print("AMSTERDAM_FINISH_IMAGE error=%d front_contact=%s rear_contact=%s" % [finish_error, wagon.front_spring.is_colliding(), wagon.rear_spring.is_colliding()])
		if branch_speed_kmh < 0.0 and bool(course.get("_upper_launch_triggered")):
			branch_speed_kmh = absf(wagon.speed_mps) * 3.6
		if frame_count % 120 == 0:
			print("AMSTERDAM_PROBE_PROGRESS frames=%d distance_m=%.1f speed_mps=%.2f branch=%s" % [frame_count, distance_m, wagon.speed_mps, str(course.get("_branch_decided"))])
		# Capture the opening encounter just before the first timber barrier. This
		# makes the reference comparison show the wagon, an approaching obstacle
		# and the first animated zombie encounter together, instead of a post-hit
		# frame where the barrier has already disappeared.
		if DisplayServer.get_name() != "headless" and distance_m >= 80.0 and distance_m < 83.5 and not action_capture_written:
			var action_image: Image = get_viewport().get_texture().get_image()
			var action_error: Error = action_image.save_png("res://build/amsterdam_reference_comparison.png")
			print("AMSTERDAM_PREVIEW_REFERENCE_IMAGE path=build/amsterdam_reference_comparison.png error=%d" % action_error)
			action_capture_written = true
		if DisplayServer.get_name() != "headless" and distance_m >= 171.0 and distance_m < 174.0 and not obstacle_capture_written:
			var obstacle_image: Image = get_viewport().get_texture().get_image()
			var obstacle_error: Error = obstacle_image.save_png("res://build/amsterdam_obstacle_review_0.5.57.png")
			print("AMSTERDAM_PREVIEW_OBSTACLE_IMAGE path=build/amsterdam_obstacle_review_0.5.57.png error=%d" % obstacle_error)
			obstacle_capture_written = true
		if DisplayServer.get_name() != "headless" and distance_m >= 420.0 and distance_m < 435.0 and not capture_written:
			var viewport_image: Image = get_viewport().get_texture().get_image()
			var image_error: Error = viewport_image.save_png("res://build/amsterdam_preview_strecke.png")
			print("AMSTERDAM_PREVIEW_IMAGE path=build/amsterdam_preview_strecke.png error=%d" % image_error)
			capture_written = true
		var road_error: float = wrapf(wagon.global_rotation - course.slope_at(wagon.position.x), -PI, PI)
		var unstable_wheels: bool = wagon.front_spring.is_colliding() != wagon.rear_spring.is_colliding()
		if wagon.airborne or unstable_wheels or absf(road_error) > 0.35:
			saw_airborne = true
			var wanted_key: Key = KEY_D if road_error < -0.10 else KEY_A if road_error > 0.10 else KEY_NONE
			if wanted_key != KEY_NONE:
				did_manual_balance = true
			if wanted_key != active_balance_key:
				if active_balance_key != KEY_NONE:
					_press_key(active_balance_key, false)
				active_balance_key = wanted_key
				if active_balance_key != KEY_NONE:
					_press_key(active_balance_key, true)
		elif active_balance_key != KEY_NONE:
			_press_key(active_balance_key, false)
			active_balance_key = KEY_NONE
		if absf(wagon.speed_mps) < 0.18 and not wagon.airborne and distance_m > 100.0:
			stalled_frames += 1
			if not stall_reported:
				print("AMSTERDAM_PROBE_STALL_STATE x=%.1f y=%.1f road_y=%.1f angle=%.2f airborne=%s fuel=%.1f damage=%.1f latches=%d" % [wagon.position.x, wagon.position.y, course.height_at(wagon.position.x), wagon.global_rotation, str(wagon.airborne), wagon.fuel, wagon.durability, wagon.zombie_latches.size()])
				stall_reported = true
		else:
			stalled_frames = 0
		if stalled_frames >= 60:
			print("AMSTERDAM_PROBE_STOPPED_STALL distance_m=%.1f fuel=%.1f" % [distance_m, wagon.fuel])
			break
	if active_balance_key != KEY_NONE:
		_press_key(active_balance_key, false)
	_press_key(KEY_W, false)
	if review_index > 0:
		review.save_png("res://build/amsterdam-review-preview.png")
	print("AMSTERDAM_CAMERA max_step_px=%.2f" % max_camera_step_px)
	var distance_done: float = float(preview.get("distance_m"))
	var travel_time: float = float(preview.get("elapsed_s"))
	var upper_route: bool = bool(course.get("_upper_route_chosen"))
	var landings: int = int(preview.get("_landing_count"))
	var impacts: int = int(preview.get("_impact_count"))
	var coins: int = int(preview.get("_preview_bonus_coins"))
	var speed_peak_kmh: float = float(preview.get("_speed_peak_kmh"))
	var route_complete: bool = bool(preview.get("_finished")) and distance_done >= course.preview_length_m()
	var branch_choice_matches_speed: bool = branch_speed_kmh >= 0.0 and upper_route == (branch_speed_kmh >= course.BRANCH_MIN_SPEED_KMH)
	print("AMSTERDAM_PREVIEW_RESULT build=tuned route=%s branch_kmh=%.1f distance_m=%.1f time_s=%.2f impacts=%d airborne=%s landings=%d coins=%d peak_kmh=%.1f complete=%s frames=%d balanced=%s overturned=%s fuel=%.1f durability=%.1f speed_mps=%.2f position_m=%.1f latches=%d" % [
		"upper" if upper_route else "lower",
		branch_speed_kmh,
		distance_done,
		travel_time,
		impacts,
		str(saw_airborne),
		landings,
		coins,
		speed_peak_kmh,
		str(route_complete),
		frame_count,
		str(did_manual_balance),
		str(wagon.overturned),
		wagon.fuel,
		wagon.durability,
		wagon.speed_mps,
		wagon.position.x / PPM,
		wagon.zombie_latches.size()
	])
	var time_window_ok: bool = travel_time >= 55.0 and travel_time <= 105.0
	if not route_complete or not branch_choice_matches_speed or not saw_airborne or landings < 1 or impacts < 3 or not time_window_ok:
		push_error("Amsterdam preview did not complete its route, landing, collision or 55–105 second checks.")
		get_tree().quit(1)
		return
	print("AMSTERDAM_PREVIEW_MILESTONE_OK route=%s branch_kmh=%.1f landing=true impact_count=%d time_s=%.2f" % ["upper" if upper_route else "lower", branch_speed_kmh, impacts, travel_time])
	get_tree().quit(0)

func _press_key(keycode: Key, pressed: bool) -> void:
	if bool(_keys_down.get(keycode, false)) == pressed:
		return
	_keys_down[keycode] = pressed
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
