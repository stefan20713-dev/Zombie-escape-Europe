extends Node2D

const WAGON_SCENE: PackedScene = preload("res://scenes/wagon.tscn")
const TIRE_LEVELS: Array[int] = [0, 1, 2, 3]
const CAR_X_POSITIONS: Array[float] = [152.0, 470.0, 788.0, 1106.0]
const LABELS: Array[String] = [
	"SERIE · KLEINER STRASSENREIFEN",
	"STUFE 1 · GELÄNDEPROFIL",
	"STUFE 2 · ORANGE STAHLFELGE",
	"STUFE 3 · SCHWERES PROFIL"
]
const ARMOR_LEVEL: int = 3

func _ready() -> void:
	var previous_radius: float = -1.0
	var reference_front_x: float = 0.0
	var reference_rear_x: float = 0.0
	var texture_paths: Array[String] = []
	for index in range(TIRE_LEVELS.size()):
		var tire_level: int = TIRE_LEVELS[index]
		var wagon: EscapeWagon = WAGON_SCENE.instantiate() as EscapeWagon
		add_child(wagon)
		wagon.configure({
			"engine": 0, "tires": tire_level, "tank": 0, "armor": ARMOR_LEVEL,
			"suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0
		}, "kombi")
		wagon.freeze = true
		wagon.scale = Vector2.ONE * 1.32
		wagon.position = Vector2(CAR_X_POSITIONS[index], 418.0)
		wagon.queue_redraw()
		var radius: float = wagon.wheel_visual_radius()
		var texture_path: String = wagon.kombi_tire_texture(tire_level).resource_path
		if radius <= previous_radius or texture_paths.has(texture_path):
			push_error("Tire progression must use four unique assets and grow at each upgrade.")
			get_tree().quit(1)
			return
		if index == 0:
			reference_front_x = wagon.front_wheel_x
			reference_rear_x = wagon.rear_wheel_x
		elif not is_equal_approx(wagon.front_wheel_x, reference_front_x) or not is_equal_approx(wagon.rear_wheel_x, reference_rear_x):
			push_error("Tire stages moved the factory axle positions.")
			get_tree().quit(1)
			return
		texture_paths.append(texture_path)
		previous_radius = radius

	if not _check_armor_independence():
		get_tree().quit(1)
		return

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var screenshot: Image = get_viewport().get_texture().get_image()
	var output_path: String = ProjectSettings.globalize_path("res://build/tire_visual_review_0.7.2.png")
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var save_error: Error = screenshot.save_png(output_path)
	if save_error != OK:
		push_error("Could not save tire stage preview: %s" % output_path)
		get_tree().quit(1)
		return
	print("KOMBI_TIRE_GALLERY_OK path=%s size=%dx%d" % [output_path, screenshot.get_width(), screenshot.get_height()])
	get_tree().quit(0)

func _check_armor_independence() -> bool:
	var stock_wagon: EscapeWagon = WAGON_SCENE.instantiate() as EscapeWagon
	var armored_wagon: EscapeWagon = WAGON_SCENE.instantiate() as EscapeWagon
	add_child(stock_wagon)
	add_child(armored_wagon)
	stock_wagon.visible = false
	armored_wagon.visible = false
	stock_wagon.configure({"tires": 0, "armor": 0}, "kombi")
	armored_wagon.configure({"tires": 0, "armor": 3}, "kombi")
	var unchanged: bool = is_equal_approx(stock_wagon.wheel_visual_radius(), armored_wagon.wheel_visual_radius())
	unchanged = unchanged and is_equal_approx(stock_wagon.rear_wheel_x, armored_wagon.rear_wheel_x)
	unchanged = unchanged and is_equal_approx(stock_wagon.front_wheel_x, armored_wagon.front_wheel_x)
	var stock_radius: float = stock_wagon.wheel_visual_radius()
	var stock_rear_x: float = stock_wagon.rear_wheel_x
	var stock_front_x: float = stock_wagon.front_wheel_x
	stock_wagon.queue_free()
	armored_wagon.queue_free()
	if not unchanged:
		push_error("Armor changed the stock tire size or axle position.")
		return false
	print("TIRE_ARMOR_INDEPENDENCE_OK radius=%.1f rear_x=%.1f front_x=%.1f" % [stock_radius, stock_rear_x, stock_front_x])
	return true

func _draw() -> void:
	var view_size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view_size), Color8(31, 39, 36))
	draw_rect(Rect2(0.0, 0.0, view_size.x, 76.0), Color8(20, 30, 28))
	draw_rect(Rect2(0.0, 490.0, view_size.x, 230.0), Color8(38, 49, 45))
	draw_line(Vector2(0.0, 490.0), Vector2(view_size.x, 490.0), Color8(198, 159, 94), 3.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 49.0), "ZOMBIE ESCAPE EUROPE · REIFENSTUFEN · PANZERUNG STUFE 3", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 25, Color8(241, 225, 190))
	for index in range(LABELS.size()):
		var x: float = CAR_X_POSITIONS[index]
		draw_rect(Rect2(x - 142.0, 515.0, 284.0, 70.0), Color8(20, 30, 28, 230))
		draw_rect(Rect2(x - 142.0, 515.0, 284.0, 70.0), Color8(135, 108, 66), false, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(x - 129.0, 546.0), LABELS[index], HORIZONTAL_ALIGNMENT_LEFT, 258.0, 15, Color8(235, 207, 151))
		draw_string(ThemeDB.fallback_font, Vector2(x - 129.0, 570.0), "REIFENSTUFE %d" % index, HORIZONTAL_ALIGNMENT_LEFT, 258.0, 14, Color8(194, 199, 171))
