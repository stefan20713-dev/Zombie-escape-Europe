extends Node

const TEST_SCENE: PackedScene = preload("res://scenes/driving_test.tscn")

var _active_keys: Dictionary = {}

func _ready() -> void:
	call_deferred("_run_probe")

func _run_probe() -> void:
	var test_scene: Node2D = TEST_SCENE.instantiate() as Node2D
	add_child(test_scene)
	await get_tree().process_frame
	await get_tree().physics_frame
	var wagon: EscapeWagon = test_scene.get_node("Wagon") as EscapeWagon
	var speed_after_accelerating: float = 0.0
	var speed_after_coasting: float = 0.0
	var speed_after_braking: float = 0.0
	var boost_peak_mps: float = 0.0
	_set_key(KEY_W, true)
	for _frame in range(120):
		await get_tree().physics_frame
	speed_after_accelerating = absf(wagon.speed_mps)
	_set_key(KEY_W, false)
	for _frame in range(42):
		await get_tree().physics_frame
	speed_after_coasting = absf(wagon.speed_mps)
	_set_key(KEY_S, true)
	for _frame in range(48):
		await get_tree().physics_frame
	speed_after_braking = absf(wagon.speed_mps)
	_set_key(KEY_S, false)
	_set_key(KEY_W, true)
	_set_key(KEY_SPACE, true)
	var boost_active_seen: bool = false
	for _frame in range(180):
		await get_tree().physics_frame
		boost_active_seen = boost_active_seen or wagon.boost_active
		boost_peak_mps = maxf(boost_peak_mps, absf(wagon.speed_mps))
	_set_key(KEY_W, false)
	_set_key(KEY_SPACE, false)
	var boost_faster_than_braking: bool = boost_peak_mps > speed_after_braking + 3.0
	var normal_limit_mps: float = wagon._max_speed_pixels_s / wagon.PIXELS_PER_METER
	var collision_test_speed_mps: float = 18.0
	wagon.airborne = false
	wagon.linear_velocity = Vector2(collision_test_speed_mps * wagon.PIXELS_PER_METER, 0.0)
	wagon.durability = 100.0
	var light_impact: Dictionary = wagon.hit_weighted_obstacle(0.28, true)
	wagon.linear_velocity = Vector2(collision_test_speed_mps * wagon.PIXELS_PER_METER, 0.0)
	wagon.durability = 100.0
	var heavy_impact: Dictionary = wagon.hit_weighted_obstacle(0.95, true)
	wagon.configure({"engine": 2, "tires": 2, "tank": 1, "armor": 2, "suspension": 1, "efficiency": 1, "brakes": 1, "nitro": 3}, "kombi")
	wagon.linear_velocity = Vector2(collision_test_speed_mps * wagon.PIXELS_PER_METER, 0.0)
	wagon.durability = 100.0
	var tuned_heavy_impact: Dictionary = wagon.hit_weighted_obstacle(0.95, true)
	var heavy_costs_more_than_light: bool = float(heavy_impact.get("speed_loss_kmh", 0.0)) > float(light_impact.get("speed_loss_kmh", 0.0)) and float(heavy_impact.get("damage", 0.0)) > float(light_impact.get("damage", 0.0))
	var tuned_armor_reduces_impact: bool = float(tuned_heavy_impact.get("damage", 999.0)) < float(heavy_impact.get("damage", 0.0))
	var tuned_tires_reduce_speed_loss: bool = float(tuned_heavy_impact.get("speed_loss_kmh", 999.0)) < float(heavy_impact.get("speed_loss_kmh", 0.0))
	wagon.airborne = true
	wagon.durability = 100.0
	wagon.hit_zombie(6.0, 0.85, 0.0, true)
	var confirmed_airborne_contact_applies_damage: bool = wagon.durability < 100.0
	test_scene.call("_start_test_run")
	_set_key(KEY_W, true)
	var saw_airborne: bool = false
	var did_manual_balance: bool = false
	var boost_used_on_route: bool = false
	var balance_key: Key = KEY_NONE
	var frame_count: int = 0
	while not bool(test_scene.get("_finished")) and frame_count < 4800:
		await get_tree().physics_frame
		frame_count += 1
		var distance: float = float(test_scene.get("distance_m"))
		if distance >= 112.0 and distance <= 115.0 and not boost_used_on_route:
			_set_key(KEY_SPACE, true)
			boost_used_on_route = true
		elif boost_used_on_route and Input.is_key_pressed(KEY_SPACE) and distance >= 127.0:
			_set_key(KEY_SPACE, false)
		if wagon.airborne:
			saw_airborne = true
			var road_error: float = wrapf(wagon.global_rotation - test_scene.get_node("Course").slope_at(wagon.position.x), -PI, PI)
			var wanted_key: Key = KEY_D if road_error < -0.10 else KEY_A if road_error > 0.10 else KEY_NONE
			if wanted_key != KEY_NONE:
				did_manual_balance = true
			if wanted_key != balance_key:
				if balance_key != KEY_NONE:
					_set_key(balance_key, false)
				balance_key = wanted_key
				if balance_key != KEY_NONE:
					_set_key(balance_key, true)
		elif balance_key != KEY_NONE:
			_set_key(balance_key, false)
			balance_key = KEY_NONE
	_set_key(KEY_W, false)
	_set_key(KEY_SPACE, false)
	if balance_key != KEY_NONE:
		_set_key(balance_key, false)
	var test_seconds: float = float(test_scene.get("elapsed_s"))
	var route_distance_m: float = float(test_scene.get("distance_m"))
	var impact_count: int = int(test_scene.get("_impact_count"))
	var landing_count: int = int(test_scene.get("_landing_count"))
	var route_complete: bool = bool(test_scene.get("_finished")) and route_distance_m >= DrivingTestCourse.COURSE_LENGTH_M
	var route_time_ok: bool = test_seconds >= 44.0 and test_seconds <= 62.0
	print("DRIVING_TEST_RESULT accelerate_2s=%.2fmps coast_0.7s=%.2fmps brake_0.8s=%.2fmps boost_peak=%.2fmps stock_limit=%.2fmps boost_active=%s boost_faster_than_braking=%s light_loss=%.1f heavy_loss=%.1f heavy_damage=%.1f tuned_heavy_damage=%.1f heavy_more_costly=%s tuned_armor_help=%s tuned_tires_help=%s airborne_contact_damage=%s route=%.1fm time=%.2fs impacts=%d airborne=%s manual_balance=%s landings=%d complete=%s time_window=%s" % [
		speed_after_accelerating, speed_after_coasting, speed_after_braking, boost_peak_mps, normal_limit_mps,
		str(boost_active_seen), str(boost_faster_than_braking),
		float(light_impact.get("speed_loss_kmh", 0.0)), float(heavy_impact.get("speed_loss_kmh", 0.0)),
		float(heavy_impact.get("damage", 0.0)), float(tuned_heavy_impact.get("damage", 0.0)),
		str(heavy_costs_more_than_light), str(tuned_armor_reduces_impact), str(tuned_tires_reduce_speed_loss),
		str(confirmed_airborne_contact_applies_damage), route_distance_m, test_seconds, impact_count,
		str(saw_airborne), str(did_manual_balance), landing_count, str(route_complete), str(route_time_ok)
	])
	var acceleration_ok: bool = speed_after_accelerating > 3.0 and speed_after_coasting > 0.0 and speed_after_coasting < speed_after_accelerating
	var braking_ok: bool = speed_after_braking < speed_after_coasting
	if not acceleration_ok or not braking_ok or not boost_active_seen or not boost_faster_than_braking or not heavy_costs_more_than_light or not tuned_armor_reduces_impact or not tuned_tires_reduce_speed_loss or not confirmed_airborne_contact_applies_damage or not saw_airborne or landing_count < 1 or not route_complete or not route_time_ok or impact_count < 4 or not did_manual_balance:
		push_error("Driving milestone failed: one or more real-input, collision, boost, route-time, or landing checks did not complete.")
		test_scene.queue_free()
		await get_tree().process_frame
		get_tree().quit(1)
		return
	print("DRIVING_MILESTONE_1_OK scripted_key_events=true collision_zombies=true light_heavy_impacts=true ramp_landing=true time_s=%.2f" % test_seconds)
	test_scene.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _set_key(keycode: Key, pressed: bool) -> void:
	if keycode == KEY_NONE or bool(_active_keys.get(keycode, false)) == pressed:
		return
	_active_keys[keycode] = pressed
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	Input.parse_input_event(event)
