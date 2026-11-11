extends Node2D

const WAGON_SCENE: PackedScene = preload("res://scenes/wagon.tscn")
const FIRST_CAPTURE_PATH: String = "res://build/pc_preview_zombie_latched_kombi.png"
const SECOND_CAPTURE_PATH: String = "res://build/pc_preview_zombie_latched_kombi_motion.png"

func _ready() -> void:
	var wagon: EscapeWagon = WAGON_SCENE.instantiate() as EscapeWagon
	add_child(wagon)
	wagon.configure({
		"engine": 0, "tires": 0, "tank": 0, "armor": 0,
		"suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0
	}, "kombi")
	wagon.freeze = true
	wagon.position = Vector2(640.0, 475.0)
	wagon.zombie_latches.clear()
	assert(wagon.add_zombie_latch(30.0, 1.4, 1, 1, 0.7), "The Amsterdam preview needs a normal zombie holding onto the roof.")
	queue_redraw()
	for _frame_index in range(3):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var first_error: Error = get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(FIRST_CAPTURE_PATH))
	assert(first_error == OK, "The zombie latch image must save successfully.")
	for frame_index in range(24):
		wagon._update_vehicle_feedback(1.0 / 60.0, false)
		if frame_index % 2 == 0:
			wagon.queue_redraw()
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var second_error: Error = get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(SECOND_CAPTURE_PATH))
	assert(second_error == OK, "The moving zombie latch image must save successfully.")
	print("ZOMBIE_LATCH_GALLERY_OK variant=1 hold_s=30.0 images=2 animated_pose=true")
	get_tree().quit(0)

func _draw() -> void:
	var view_size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view_size), Color8(101, 123, 119))
	for band_index in range(4):
		var band_y: float = 125.0 + float(band_index) * 80.0
		draw_rect(Rect2(0.0, band_y, view_size.x, 80.0), Color8(105 + band_index * 5, 126 + band_index * 4, 120 + band_index * 3))
	# A neutral city silhouette frames the sprite and long stock Kombi.
	for building in [
		{"x": 55.0, "w": 92.0, "h": 120.0}, {"x": 185.0, "w": 76.0, "h": 164.0},
		{"x": 975.0, "w": 104.0, "h": 182.0}, {"x": 1110.0, "w": 92.0, "h": 130.0}
	]:
		var building_x: float = float(building["x"])
		var building_w: float = float(building["w"])
		var building_h: float = float(building["h"])
		draw_rect(Rect2(building_x, 475.0 - building_h, building_w, building_h), Color8(63, 80, 76, 175))
		draw_rect(Rect2(building_x + 12.0, 487.0 - building_h, 5.0, 6.0), Color8(193, 170, 119, 160))
		draw_rect(Rect2(building_x + building_w - 19.0, 487.0 - building_h, 5.0, 6.0), Color8(193, 170, 119, 160))
	draw_rect(Rect2(0.0, 515.0, view_size.x, 205.0), Color8(44, 55, 52))
	draw_line(Vector2(0.0, 515.0), Vector2(view_size.x, 515.0), Color8(203, 165, 99), 4.0, true)
	draw_line(Vector2(0.0, 536.0), Vector2(view_size.x, 536.0), Color8(117, 128, 113), 2.0, true)
	draw_line(Vector2(0.0, 549.0), Vector2(view_size.x, 549.0), Color8(31, 41, 38), 3.0, true)
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 46.0), "AMSTERDAM · KOPPEL JE LOS!", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 25, Color8(239, 221, 185))
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 78.0), "NORMALE ZOMBIE · GREIFT MIT ZWEI HÄNDEN", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color8(229, 207, 164))
