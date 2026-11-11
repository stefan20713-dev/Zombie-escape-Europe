extends Node
func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	var preview = load("res://scenes/amsterdam_preview.tscn").instantiate()
	preview.workshop_vehicle = "kombi"
	preview.workshop_upgrades = {"engine": 3, "tires": 3, "tank": 3, "armor": 3, "suspension": 3, "nitro": 3}
	get_tree().root.add_child(preview)
	await get_tree().physics_frame
	preview.set_physics_process(false)
	var wagon = preview.wagon
	var course = preview.course
	var wall_gap: Vector2 = course.quay_visible_gap_world_bounds(course.LOCK_LIP_M * 36.0)
	assert(is_equal_approx(wall_gap.x, course.LOCK_LIP_M * 36.0) and is_equal_approx(wall_gap.y, course.LOCK_LANDING_M * 36.0), "Masonry must remain under both bridges, stopping only at the lock opening.")
	var piece: Transform2D = course.lock_piece_transform(Vector2.ZERO, Vector2(504.0, -15.0), Vector2(125.0, 435.0), Vector2(2165.0, 240.0))
	assert(is_equal_approx(piece.x.length(), piece.y.length()) and absf(piece.x.dot(piece.y)) < 0.00001, "Bridge artwork must use uniform scale without shear.")
	assert((piece * Vector2(2165.0, 240.0)).distance_to(Vector2(504.0, -15.0)) < 0.001)
	for speed in [100.0, 109.0, 110.0, 111.0, 135.0]:
		course.set_physics_process(false)
		course.reset_test_run(wagon)
		course._upper_launch_triggered = true
		course._branch_decided = true
		for event in course._encounters:
			event["done"] = true
		wagon.reset_at((course.LOCK_START_M - 4.0) * 36.0, course)
		wagon.rotation = 0.0
		wagon.linear_velocity = Vector2(speed * 10.0, 0.0)
		wagon.angular_velocity = 0.0
		wagon.freeze = false
		course._update_lock_crossing(0.0)
		var lift: float = 0.0
		var launch_reported := false
		course.set_physics_process(true)
		var landed := false
		var max_x := 0.0
		for frame in range(600):
			await get_tree().physics_frame
			if not course.lock_flight_active:
				wagon.simulate(1.0 / 60.0, false, false, false, clampf(-wagon.rotation * 4.0, -1.0, 1.0) if wagon.airborne else 0.0, course.slope_at(wagon.position.x))
			if not course._lock_launched:
				wagon.linear_velocity.x = speed * 10.0
			elif not launch_reported:
				print("LOCK_REAL_TAKEOFF requested=", speed, " actual_kmh=", wagon.speed_mps * 3.6, " y=", wagon.position.y, " lip_y=", course.lock_surface_y(course.LOCK_LIP_M), " angle=", wagon.rotation)
				launch_reported = true
			if course.lock_flight_active and course._lock_missed:
				var gravity: float = 350.0 * wagon.gravity_scale
				var expected_y: float = course.lock_surface_y(course.LOCK_LIP_M) - course._lock_release_clearance + 0.5 * gravity * course._lock_flight_time * course._lock_flight_time
				assert(absf(wagon.position.y - expected_y) < 0.02, "A miss must continue the same gravity trajectory without a downward push.")
			max_x = maxf(max_x, wagon.position.x / 36.0)
			if wagon.position.x / 36.0 > course.LOCK_REJOIN_M + 5.0 and not wagon.airborne:
				landed = true
				break
			if course._lock_water_entered:
				break
		assert(landed and not course._lock_water_entered if speed >= 110.0 else not landed and course._lock_water_entered, "Only a sufficient geometric jump should reach the far platform.")
		print("LOCK_BALLISTIC speed=", speed, " gap_m=", course.LOCK_GAP_M, " lift_px_s=", lift, " landed=", landed, " water=", course._lock_water_entered, " x=", max_x, " y=", wagon.position.y, " rotation=", wagon.rotation)
	assert(is_equal_approx(course.LOCK_LIP_M - course.START_M, 1280.0))
	preview._water_crash_time_s = -1.0
	preview._finished = false
	preview._on_lock_water_entered()
	preview._physics_process(1.3)
	assert(preview._finished and is_instance_valid(preview._pause_overlay))
	preview._start_test_run()
	assert(preview._water_crash_time_s < 0.0 and not course.lock_flight_active and wagon.modulate.a == 1.0)
	print("AMSTERDAM_LOCK_BRIDGE_OK displayed_lip_m=1280 gap_m=26.56 slow_water=true speed110_lands=true water_game_over=true restart=true")
	get_tree().quit()
