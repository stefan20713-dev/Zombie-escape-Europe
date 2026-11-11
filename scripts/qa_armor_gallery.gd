extends Node2D

const WAGON_SCENE: PackedScene = preload("res://scenes/wagon.tscn")
const LABELS: Array[String] = ["SERIE", "STUFE 1 · FRONTKEIL", "STUFE 2 · GITTER + SCHIEBER", "STUFE 3 · SEITENPLATTEN"]
const CAR_X_POSITIONS: Array[float] = [152.0, 470.0, 788.0, 1106.0]
const ARMOR_LEVELS: Array[int] = [0, 1, 2, 3]

func _ready() -> void:
	for car_index in range(ARMOR_LEVELS.size()):
		var wagon: EscapeWagon = WAGON_SCENE.instantiate() as EscapeWagon
		add_child(wagon)
		wagon.configure({
			"engine": 0, "tires": 0, "tank": 0, "armor": ARMOR_LEVELS[car_index],
			"suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0
		}, "kombi")
		wagon.freeze = true
		wagon.position = Vector2(CAR_X_POSITIONS[car_index], 430.0)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var screenshot: Image = get_viewport().get_texture().get_image()
	var output_path: String = ProjectSettings.globalize_path("res://build/armor_visual_review_0.5.43.png")
	var output_directory: String = output_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(output_directory)
	var save_error: Error = screenshot.save_png(output_path)
	if save_error != OK:
		push_error("Could not save armor stage preview: %s" % output_path)
		get_tree().quit(1)
		return
	print("KOMBI_ARMOR_GALLERY_OK path=%s size=%dx%d" % [output_path, screenshot.get_width(), screenshot.get_height()])
	get_tree().quit(0)

func _draw() -> void:
	var view_size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view_size), Color8(28, 40, 38))
	draw_rect(Rect2(0.0, 0.0, view_size.x, 75.0), Color8(20, 30, 28))
	draw_rect(Rect2(0.0, 490.0, view_size.x, 230.0), Color8(38, 49, 45))
	draw_line(Vector2(0.0, 490.0), Vector2(view_size.x, 490.0), Color8(198, 159, 94), 3.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 48.0), "ZOMBIE ESCAPE EUROPE · PANZERUNGSSTUFEN", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26, Color8(241, 225, 190))
	for car_index in range(LABELS.size()):
		var x: float = CAR_X_POSITIONS[car_index]
		draw_rect(Rect2(x - 142.0, 515.0, 284.0, 60.0), Color8(20, 30, 28, 225))
		draw_rect(Rect2(x - 142.0, 515.0, 284.0, 60.0), Color8(135, 108, 66), false, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(x - 126.0, 551.0), LABELS[car_index], HORIZONTAL_ALIGNMENT_LEFT, 252.0, 16, Color8(235, 207, 151))
