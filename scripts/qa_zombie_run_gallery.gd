extends Node2D

const TERRAIN_SCENE: PackedScene = preload("res://scenes/terrain.tscn")

func _ready() -> void:
	var background_layer := CanvasLayer.new()
	background_layer.layer = -1
	add_child(background_layer)
	var sky := ColorRect.new()
	sky.color = Color8(88, 110, 108)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_layer.add_child(sky)
	var title_layer := CanvasLayer.new()
	title_layer.layer = 10
	add_child(title_layer)
	var title := Label.new()
	title.text = "AMSTERDAM · LAUFANIMATION"
	title.position = Vector2(28.0, 18.0)
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color8(239, 221, 185))
	title_layer.add_child(title)
	var camera := Camera2D.new()
	camera.enabled = true
	add_child(camera)
	var terrain: EscapeTerrain = TERRAIN_SCENE.instantiate() as EscapeTerrain
	add_child(terrain)
	terrain.configure_world(0)
	var zombie_route_x: float = terrain.route_meter_to_world_x(965.0)
	var road_y: float = terrain.height_at(zombie_route_x)
	camera.global_position = Vector2(zombie_route_x, road_y - 300.0)
	terrain.queue_redraw()
	for _frame_index in range(4):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var screenshot: Image = get_viewport().get_texture().get_image()
	var output_path: String = ProjectSettings.globalize_path("res://build/zombie_run_visual_review_0.5.44.png")
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var save_error: Error = screenshot.save_png(output_path)
	if save_error != OK:
		push_error("Could not save zombie run animation preview: %s" % output_path)
		get_tree().quit(1)
		return
	print("ZOMBIE_RUN_GALLERY_OK path=%s size=%dx%d" % [output_path, screenshot.get_width(), screenshot.get_height()])
	get_tree().quit(0)
