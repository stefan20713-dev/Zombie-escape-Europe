extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	call_deferred("_run_probe")

func _run_probe() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.first_drive_tutorial_completed = true
	game.selected_vehicle = "kombi"
	game.selected_world_index = 0
	game.campaign_meter = 0.0
	game.upgrades = {"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0}
	game._begin_run(false)

	var gas := InputEventKey.new()
	gas.keycode = KEY_W
	gas.pressed = true
	Input.parse_input_event(gas)
	var fastest_speed_kmh: float = 0.0
	var start_usec: int = Time.get_ticks_usec()
	var gas_frames: int = 0
	var boost_frames: int = 0
	for frame_index in range(2160):
		var boost_pressed: bool = frame_index < 90 or (frame_index >= 1800 and frame_index < 2007)
		var boost_event := InputEventKey.new()
		boost_event.keycode = KEY_SPACE
		boost_event.pressed = boost_pressed
		Input.parse_input_event(boost_event)
		await get_tree().physics_frame
		if game.screen_state != "RUN":
			break
		fastest_speed_kmh = maxf(fastest_speed_kmh, absf(game.wagon.speed_mps) * 3.6)
		gas_frames += 1 if Input.is_key_pressed(KEY_W) else 0
		boost_frames += 1 if game.wagon.boost_active else 0

	gas.pressed = false
	Input.parse_input_event(gas)
	var boost_release := InputEventKey.new()
	boost_release.keycode = KEY_SPACE
	boost_release.pressed = false
	Input.parse_input_event(boost_release)
	var elapsed_s: float = float(Time.get_ticks_usec() - start_usec) / 1000000.0
	var zombie_count: int = 0
	var authored_hazard_count: int = 0
	for entity in game.terrain.entities:
		if float(entity.get("meter", 9999.0)) <= 670.0 and String(entity.get("kind", "")) == "zombie":
			zombie_count += 1
		if float(entity.get("meter", 9999.0)) <= 670.0 and String(entity.get("kind", "")) == "setpiece":
			authored_hazard_count += 1
	print("PC_PREVIEW_DRIVE_RESULT duration=%.2fs gas_frames=%d boost_frames=%d speed_cap_kmh=%.1f peak_kmh=%.1f distance_m=%.1f zombie_groups=%d zombie_contacts=%d hazards=%d hazard_hits=%d durability=%.1f fuel=%.1f fps=%d" % [
		elapsed_s,
		gas_frames,
		boost_frames,
		game.wagon._max_speed_pixels_s / game.wagon.PIXELS_PER_METER * 3.6,
		fastest_speed_kmh,
		game.run_distance,
		zombie_count,
		game.run_zombie_contacts,
		authored_hazard_count,
		game.run_hazard_hits,
		game.wagon.durability,
		game.wagon.fuel,
		Engine.get_frames_per_second()
	])
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()
