extends Node
var drive: Node
func _ready() -> void:
	call_deferred("_run")
func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/action-" + label + ".png")
func _run() -> void:
	drive = load("res://scenes/amsterdam_preview.tscn").instantiate()
	drive.workshop_vehicle = "kombi"
	drive.workshop_upgrades = {"engine": 2, "tires": 2, "tank": 3, "armor": 2, "suspension": 1, "nitro": 3, "weapon": 1}
	get_tree().root.add_child(drive)
	await get_tree().physics_frame
	var w = drive.wagon
	var c = drive.course
	c._upper_launch_triggered = true
	c._branch_decided = true
	# Isolated approach; from here the route is driven with genuine inputs.
	w.reset_at(1015.0 * 36.0, c)
	w.linear_velocity = Vector2(27.0 * 36.0, 0)
	w.freeze = false
	drive._run_started = true
	var capture := 0
	var points := [1031.0, 1065.0, 1087.0, 1100.0, 1130.0]
	for frame in range(1500):
		var meter: float = w.position.x / 36.0
		key(KEY_W, true)
		key(KEY_S, meter >= 1035.0 and meter < 1039.0)
		key(KEY_SPACE, meter > 1061.0 and meter < 1127.0)
		var error: float = wrapf(w.rotation - (0.0 if w.airborne else c.slope_at(w.position.x)), -PI, PI)
		key(KEY_D, false)
		key(KEY_A, false)
		await get_tree().physics_frame
		if frame % 90 == 0:
			print("ACTION_ROUTE_PROGRESS m=", meter, " y=", w.position.y, " speed=", w.speed_mps * 3.6)
		if capture < points.size() and meter > points[capture]:
			await shot("continuous-road-%d" % capture)
			capture += 1
		if drive._finished or meter > 1130.0:
			break
	for code in [KEY_W, KEY_S, KEY_SPACE, KEY_A, KEY_D]:
		key(code, false)
	print("CONTINUOUS_ROAD_RESULT m=", w.position.x / 36.0, " finished=", drive._finished)
	assert(w.position.x / 36.0 > 1130.0 and not drive._finished, "Restored road must remain driveable even when braking at the former fork.")
	# Fresh isolated approach avoids carrying a moving RigidBody's prior integration state.
	drive.queue_free()
	await get_tree().process_frame
	drive = load("res://scenes/amsterdam_preview.tscn").instantiate()
	drive.workshop_vehicle = "kombi"
	drive.workshop_upgrades = {"engine": 2, "tires": 2, "tank": 3, "armor": 2, "nitro": 3, "suspension": 1}
	get_tree().root.add_child(drive)
	await get_tree().physics_frame
	w = drive.wagon
	c = drive.course
	c._upper_launch_triggered = true
	c._branch_decided = true
	c._lock_launched = true
	w.reset_at(1402.0 * 36.0, c)
	w.freeze = false
	w.linear_velocity.x = 18.0 * 36.0
	drive.camera.position = w.position + Vector2(285.0, -75.0)
	drive.camera.zoom = Vector2.ONE * 1.5
	drive.camera.force_update_scroll()
	drive._run_started = true
	key(KEY_W, true)
	for frame in range(65):
		await get_tree().physics_frame
		if frame == 20:
			await shot("crane-warning")
	await shot("crane")
	key(KEY_W, false)
	print("ACTION_CRANE_STATE m=", w.position.x / 36.0, " freeze=", w.freeze, " finished=", drive._finished, " roof=", drive._roof_crash_time_s, " lock=", c.lock_flight_active)
	print("ACTION_DRIVE_OK")
	get_tree().quit()


