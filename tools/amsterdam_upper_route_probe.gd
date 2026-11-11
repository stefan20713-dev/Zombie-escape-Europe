extends Node

const PREVIEW_SCENE: PackedScene = preload("res://scenes/amsterdam_preview.tscn")
const PIXELS_PER_METER: float = 36.0
const MAX_KOMBI_LEVELS: Dictionary = {
	"engine": 3, "tires": 3, "tank": 3, "armor": 3,
	"suspension": 3, "efficiency": 3, "brakes": 3, "nitro": 3, "weapon": 1
}

var _keys_down: Dictionary = {}

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	print("AMSTERDAM_UPPER_ROUTE_PROBE_STARTED")
	# Keep the full-course probe at normal time so physics, boost timing and the
	# 120 km/h fork are evaluated like a real player run rather than time-scaled.
	Engine.time_scale = 1.0
	var preview: Node2D = PREVIEW_SCENE.instantiate() as Node2D
	get_tree().root.add_child(preview)
	await get_tree().process_frame
	await get_tree().physics_frame
	var wagon: EscapeWagon = preview.get_node("Wagon") as EscapeWagon
	var course: AmsterdamPreviewCourse = preview.get_node("Course") as AmsterdamPreviewCourse
	wagon.configure(MAX_KOMBI_LEVELS, "kombi")
	wagon.set_weapon_active(true)
	wagon.reset_at(7.0 * PIXELS_PER_METER, course)
	course.reset_test_run(wagon)
	preview.set("_start_x", wagon.position.x)
	preview.set("_run_started", false)
	preview.set("_finished", false)
	preview.set("elapsed_s", 0.0)
	preview.set("distance_m", 0.0)
	preview.set("_impact_count", 0)
	preview.set("_landing_count", 0)
	_press_key(KEY_W, true)
	var boost_started: bool = false
	var boost_released: bool = false
	var boost_state_reported: bool = false
	var balance_key: Key = KEY_NONE
	var branch_speed_kmh: float = -1.0
	var frames: int = 0
	var highest_route_position_m: float = 0.0
	var bridge_surface_contact_frames: int = 0
	var bridge_first_contact_m: float = -1.0
	var bridge_body: StaticBody2D = course.get_node("UpperCanalBridgeCollision") as StaticBody2D
	var stalled_frames: int = 0
	var approach_capture_written: bool = false
	var deck_capture_written: bool = false
	var camera: Camera2D = preview.get_viewport().get_camera_2d()
	var previous_camera: Vector2 = camera.get_screen_center_position()
	var max_camera_step_px: float = 0.0
	var review: Image = Image.create_empty(1280, 1080, false, Image.FORMAT_RGB8)
	var review_index: int = 0
	while not bool(preview.get("_finished")) and frames < 7200:
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
		frames += 1
		var distance_m: float = float(preview.get("distance_m"))
		# Save the boost for the approach so it carries the wagon through the
		# opening contacts and into the 120 km/h route gate.
		if distance_m >= 310.0 and not boost_started:
			_press_key(KEY_SPACE, true)
			boost_started = true
		if boost_started and not boost_state_reported and distance_m >= 355.0:
			print("AMSTERDAM_UPPER_ROUTE_BOOST nitro_level=%d nitro=%.1f active=%s speed_kmh=%.1f" % [wagon.nitro_level, wagon.nitro, str(wagon.boost_active), absf(wagon.linear_velocity.x / PIXELS_PER_METER) * 3.6])
			boost_state_reported = true
		if bool(course.get("_upper_launch_triggered")):
			if branch_speed_kmh < 0.0:
				branch_speed_kmh = absf(wagon.linear_velocity.x / PIXELS_PER_METER) * 3.6
				print("AMSTERDAM_UPPER_ROUTE_LAUNCH x_m=%.1f speed_kmh=%.1f vertical_px_s=%.1f chassis_y=%.1f deck_y=%.1f" % [wagon.position.x / PIXELS_PER_METER, branch_speed_kmh, wagon.linear_velocity.y, wagon.position.y, course.UPPER_BRIDGE_Y])
			if not boost_released:
				_press_key(KEY_SPACE, false)
				boost_released = true
		if bool(course.get("_upper_route_chosen")):
			var route_meter: float = wagon.position.x / PIXELS_PER_METER
			highest_route_position_m = maxf(highest_route_position_m, route_meter)
			var front_on_deck: bool = wagon.front_spring.is_colliding() and wagon.front_spring.get_collider() == bridge_body
			var rear_on_deck: bool = wagon.rear_spring.is_colliding() and wagon.rear_spring.get_collider() == bridge_body
			if route_meter >= course.UPPER_BRIDGE_START_M and route_meter <= course.UPPER_BRIDGE_END_M and not wagon.airborne and (front_on_deck or rear_on_deck):
				bridge_surface_contact_frames += 1
				if bridge_first_contact_m < 0.0:
					bridge_first_contact_m = route_meter
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
			print("AMSTERDAM_UPPER_ROUTE_STALL distance_m=%.1f fuel=%.1f durability=%.1f" % [distance_m, wagon.fuel, wagon.durability])
			break
		if DisplayServer.get_name() != "headless" and route_meter_in_range(wagon, 432.0, 438.0) and not approach_capture_written:
			var image: Image = get_viewport().get_texture().get_image()
			var error: Error = image.save_png("res://build/amsterdam_upper_route_approach_0.5.58.png")
			print("AMSTERDAM_UPPER_ROUTE_IMAGE path=build/amsterdam_upper_route_approach_0.5.58.png error=%d" % error)
			approach_capture_written = true
		if DisplayServer.get_name() != "headless" and bool(course.get("_upper_route_chosen")) and route_meter_in_range(wagon, course.UPPER_BRIDGE_START_M, course.UPPER_BRIDGE_END_M) and not deck_capture_written:
			var image: Image = get_viewport().get_texture().get_image()
			var error: Error = image.save_png("res://build/amsterdam_upper_route_deck_0.5.58.png")
			print("AMSTERDAM_UPPER_ROUTE_IMAGE path=build/amsterdam_upper_route_deck_0.5.58.png error=%d" % error)
			deck_capture_written = true
	if balance_key != KEY_NONE:
		_press_key(balance_key, false)
	_press_key(KEY_W, false)
	_press_key(KEY_SPACE, false)
	if review_index > 0:
		review.save_png("res://build/amsterdam-review-upper_route.png")
	print("AMSTERDAM_CAMERA max_step_px=%.2f" % max_camera_step_px)
	var distance_done: float = float(preview.get("distance_m"))
	var route_complete: bool = bool(preview.get("_finished")) and distance_done >= course.preview_length_m()
	var upper_route: bool = bool(course.get("_upper_route_chosen"))
	var landing_count: int = int(preview.get("_landing_count"))
	var impact_count: int = int(preview.get("_impact_count"))
	print("AMSTERDAM_UPPER_ROUTE_RESULT complete=%s distance_m=%.1f elapsed_s=%.2f branch_kmh=%.1f upper=%s launched=%s bridge_contact_frames=%d bridge_first_contact_m=%.1f highest_route_m=%.1f landings=%d impacts=%d overturned=%s fuel=%.1f durability=%.1f frames=%d" % [
		str(route_complete), distance_done, float(preview.get("elapsed_s")), branch_speed_kmh,
		str(upper_route), str(course.get("_upper_launch_triggered")), bridge_surface_contact_frames,
		bridge_first_contact_m, highest_route_position_m, landing_count, impact_count, str(wagon.overturned), wagon.fuel,
		wagon.durability, frames
	])
	var passed: bool = route_complete and upper_route and branch_speed_kmh >= course.BRANCH_MIN_SPEED_KMH and bool(course.get("_upper_launch_triggered")) and highest_route_position_m >= course.UPPER_BRIDGE_START_M and bridge_surface_contact_frames >= 4 and landing_count >= 1 and impact_count >= 4 and not wagon.overturned
	if not passed:
		push_error("Amsterdam's high-speed bridge route did not complete with a controlled launch and landing.")
		Engine.time_scale = 1.0
		get_tree().quit(1)
		return
	print("AMSTERDAM_UPPER_ROUTE_OK complete=true physical_gap=true bridge_deck_contact=true landing=true")
	Engine.time_scale = 1.0
	get_tree().quit(0)

func route_meter_in_range(wagon: EscapeWagon, start_m: float, end_m: float) -> bool:
	var route_meter: float = wagon.position.x / PIXELS_PER_METER
	return route_meter >= start_m and route_meter <= end_m

func _press_key(keycode: Key, pressed: bool) -> void:
	if bool(_keys_down.get(keycode, false)) == pressed:
		return
	_keys_down[keycode] = pressed
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
