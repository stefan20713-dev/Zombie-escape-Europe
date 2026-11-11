extends Node
var shaken := 0
func _ready() -> void:
	call_deferred("_run")
func key(code: Key, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = pressed
	Input.parse_input_event(e)
func _run() -> void:
	var d = load("res://scenes/amsterdam_preview.tscn").instantiate()
	d.workshop_vehicle = "kombi"
	d.workshop_upgrades = {"engine": 2, "tires": 2, "tank": 3, "armor": 2, "nitro": 3, "suspension": 1}
	get_tree().root.add_child(d)
	await get_tree().physics_frame
	var w = d.wagon
	d.course._upper_launch_triggered = true
	d.course._branch_decided = true
	w.reset_at(300.0 * 36.0, d.course)
	w.freeze = false
	w.linear_velocity.x = 25.0 * 36.0
	d._run_started = true
	w.zombies_shaken.connect(func(count: int): shaken += count)
	w.add_zombie_latch(12.0, 1.0, 0, 1)
	for frame in range(180):
		key(KEY_W, frame < 20 or frame >= 55)
		key(KEY_S, frame >= 20 and frame < 55)
		key(KEY_SPACE, frame >= 55 and frame < 140)
		await get_tree().physics_frame
		if frame in [20, 54, 100]:
			print("SHAKE_INPUT_PROGRESS frame=", frame, " speed=", w.speed_mps * 3.6, " ready=", w._shake_ready_s, " airborne=", w.airborne, " latches=", w.zombie_latches.size())
	for code in [KEY_W, KEY_S, KEY_SPACE]:
		key(code, false)
	assert(shaken == 1 and w.zombie_latches.is_empty(), "Real brake/throttle maneuver must shake the zombie off.")
	print("SHAKE_REAL_INPUT_OK count=", shaken)
	get_tree().quit()
