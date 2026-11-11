extends Node
func _ready() -> void:
	call_deferred("_run")
func _key(pressed: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = KEY_W
	e.physical_keycode = KEY_W
	e.pressed = pressed
	Input.parse_input_event(e)
func _run() -> void:
	var d = load("res://scenes/amsterdam_preview.tscn").instantiate()
	d.workshop_vehicle = "kombi"
	d.workshop_upgrades = {"tank": 3}
	get_tree().root.add_child(d)
	await get_tree().physics_frame
	d.course._upper_launch_triggered = true
	d.course._branch_decided = true
	for event in d.course._encounters:
		for member in event.members_data:
			member.hit = true
		event.done = true
	var w = d.wagon
	w.reset_at(1008.0 * 36.0,d.course)
	w.durability = 60.0
	w.add_zombie_latch(20.0, 0.5, 1, 3)
	w.freeze = false
	w.linear_velocity.x = 10.0 * 36.0
	d._run_started = true
	d.camera.position = w.position + Vector2(278,-75)
	d.camera.zoom = Vector2.ONE * 1.5
	_key(true)
	for frame in range(160):
		await get_tree().physics_frame
		if frame in [60,120,159]:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/contact-standard-%d.png" % frame)
	_key(false)
	print("STANDARD_CONTACT_DRIVE_OK position=",w.position," health=",w.durability," grip=",w.zombie_latches[0].anchor)
	get_tree().quit()
