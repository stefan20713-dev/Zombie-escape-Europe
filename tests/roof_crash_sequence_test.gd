extends Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var preview = load("res://scenes/amsterdam_preview.tscn").instantiate()
	preview.workshop_vehicle = "kombi"
	preview.workshop_upgrades = {"engine": 1, "tires": 1, "tank": 1, "armor": 1}
	get_tree().root.add_child(preview)
	await get_tree().process_frame
	await get_tree().physics_frame
	preview.set_physics_process(false)
	preview.course.set_physics_process(false)
	var wagon = preview.wagon
	wagon.freeze = true
	var world_x: float = 300.0 * 36.0
	var road: float = preview.course.height_at(world_x)
	var angle: float = preview.course.slope_at(world_x)
	wagon.rotation = angle + PI
	var rect: RectangleShape2D = wagon.chassis_shape.shape
	var offset: float = wagon.chassis_shape.position.rotated(wagon.rotation).y + absf(cos(wagon.rotation)) * rect.size.y * 0.5 + absf(sin(wagon.rotation)) * rect.size.x * 0.5
	wagon.position = Vector2(world_x, road - offset - 250.0)
	wagon.update_overturn_state(0.7, road, angle)
	assert(not wagon.overturned, "An airborne roll must remain recoverable.")
	wagon.position.y = road - offset
	wagon.update_overturn_state(0.6, road, angle)
	assert(wagon.overturned, "Settled roof contact must be detected.")
	preview._run_started = true
	preview._physics_process(0.016)
	assert(preview._roof_crash_time_s == 0.0 and not preview._finished)
	assert(wagon.freeze)
	preview.camera.position = wagon.position + Vector2(278.0, -75.0)
	preview.camera.reset_smoothing()
	preview._physics_process(0.8)
	assert(wagon.roof_crash_time_s < 1.5 and not preview._finished)
	await _capture("rauch")
	preview._physics_process(1.9)
	assert(wagon.roof_crash_time_s > 2.4 and not preview._finished)
	await _capture("feuer")
	preview._physics_process(1.2)
	assert(preview._finished)
	var buttons: Array[Button] = []
	for node in preview._pause_overlay.find_children("*", "Button", true, false):
		buttons.append(node)
	assert(buttons.size() == 2 and buttons[0].text == "NEUSTART" and buttons[1].text == "ZUR WERKSTATT")
	await _capture("game-over")
	buttons[0].pressed.emit()
	assert(not preview._finished and preview._roof_crash_time_s < 0.0 and wagon.roof_crash_time_s < 0.0)
	assert(not is_instance_valid(preview._pause_overlay))
	preview.set_physics_process(false)
	for variant in [3, 4, 5]:
		for index in range(4):
			var frame = preload("res://scripts/zombie_data.gd").heavy_walk_frame(variant, index)
			assert(frame.size.x > 0.0 and frame.size.y > 0.0)
	preview._begin_roof_crash()
	preview._physics_process(4.0)
	for button in preview._pause_overlay.find_children("*", "Button", true, false):
		if button.text == "ZUR WERKSTATT":
			button.pressed.emit()
	for frame in range(4):
		await get_tree().process_frame
	assert(get_tree().current_scene != null and get_tree().current_scene.screen_state == "GARAGE", "Workshop action must actually open the garage.")
	print("ROOF_CRASH_OK airborne_recoverable=true smoke_then_fire=true delayed_game_over=true restart_resets=true workshop_button=true heavy_frames=12")
	get_tree().quit()

func _capture(stage: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for frame in range(8):
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/dachlandung-" + stage + ".png")

