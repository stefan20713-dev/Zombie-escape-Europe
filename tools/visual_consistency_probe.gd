extends Node
var output: String = "res://build/visual-audit-before"
func _ready() -> void:
	call_deferred("_run")
func _shot(name: String) -> Image:
	for item in get_tree().root.find_children("*", "CanvasItem", true, false):
		item.queue_redraw()
	for frame in range(5):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(output + "/" + name + ".png")
	return image
func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 1:
		output = args[1]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var game = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.first_drive_tutorial_completed = true
	game.open_main_menu()
	game.get_node("HUDLayer/HUD").queue_redraw()
	await _shot("menu")
	game.to_garage()
	await _shot("werkstatt-serie")
	game.upgrades = {"engine": 3, "tires": 3, "tank": 3, "armor": 3, "nitro": 3, "weapon": 1, "suspension": 3}
	game.vehicle_upgrades["kombi"] = game.upgrades.duplicate(true)
	game.to_garage()
	game.get_node("HUDLayer/HUD").queue_redraw()
	await _shot("werkstatt-ausgebaut")
	for vehicle in ["lieferwagen", "offroad_pickup"]:
		game.selected_vehicle = vehicle
		game.vehicle_upgrades[vehicle] = game.upgrades.duplicate(true)
		game.to_garage()
		game.get_node("HUDLayer/HUD").queue_redraw()
		await _shot("fahrzeug-" + vehicle)
	game.selected_vehicle = "kombi"
	game.to_garage()
	for durability in [35.0, 0.0]:
		game.wagon.durability = durability
		game.wagon.queue_redraw()
		await _shot("schaden-%03d" % int(durability))
	game.to_garage()
	var hud = game.get_node("HUDLayer/HUD")
	hud._garage_settings_open = true
	hud.queue_redraw()
	await _shot("einstellungen")
	hud._garage_settings_open = false
	DisplayServer.window_set_size(Vector2i(1600, 720))
	await _shot("werkstatt-breit")
	game.open_main_menu()
	await _shot("menu-breit")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	game.to_garage()
	game.open_world_map()
	game.get_node("HUDLayer/HUD").queue_redraw()
	await _shot("karte")
	game.queue_free()
	await get_tree().process_frame
	var preview = load("res://scenes/amsterdam_preview.tscn").instantiate()
	preview.workshop_vehicle = "kombi"
	preview.workshop_upgrades = {"engine": 2, "tires": 2, "tank": 3, "armor": 2, "nitro": 3, "weapon": 1, "suspension": 1}
	get_tree().root.add_child(preview)
	await get_tree().physics_frame
	preview.set_physics_process(false)
	preview.course.set_physics_process(false)
	var course = preview.course
	var wagon = preview.wagon
	var review := Image.create_empty(1600, 720, false, Image.FORMAT_RGB8)
	var index := 0
	for meter in [7.0, 100.0, 200.0, 300.0, 400.0, 480.0, 570.0, 670.0, 760.0, 840.0, 910.0, 1020.0, 1150.0, 1240.0, 1283.0, 1322.0, 1420.0, 1530.0, 1650.0, 1760.0]:
		course._upper_route_chosen = meter == 480.0
		wagon.reset_at(meter * 36.0, course)
		preview.distance_m = maxf(0.0, meter - 7.0)
		preview._update_hud(false, false, false)
		preview.camera.position = wagon.position + Vector2(278.0, -75.0)
		preview.camera.zoom = Vector2.ONE * (0.85 if meter in [400.0, 480.0, 1283.0, 1322.0] else 1.5)
		preview.camera.reset_smoothing()
		course.queue_redraw()
		var image: Image = await _shot("strecke-%04d" % int(meter))
		image.resize(320, 180, Image.INTERPOLATE_LANCZOS)
		image.convert(Image.FORMAT_RGB8)
		review.blit_rect(image, Rect2i(0, 0, 320, 180), Vector2i(index % 5 * 320, index / 5 * 180))
		index += 1
	review.save_png(output + "/streckenuebersicht.png")
	print("VISUAL_AUDIT_CAPTURE_OK screens=31 route_m=1800 output=", output)
	get_tree().quit()
