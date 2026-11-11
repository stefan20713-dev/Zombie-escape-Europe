extends Node
const DATA = preload("res://scripts/zombie_data.gd")
func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	var wagon = load("res://scenes/wagon.tscn").instantiate()
	add_child(wagon)
	wagon.configure({}, "kombi")
	for variant in range(1, 6):
		wagon.zombie_latches.clear()
		wagon.add_zombie_latch(20.0, 0.5, 1, variant)
		for step in range(100):
			wagon.linear_velocity.x = 20.0 * 36.0
			wagon.update_zombie_latches(0.05)
		var anchor: Vector2 = wagon.zombie_latches[0].anchor
		assert(anchor.x + float(DATA.profile(variant).visual_height) * 0.5 <= 18.01, "Hands must not crawl out beyond the roof.")
		assert(is_equal_approx(anchor.y, wagon.KOMBI_ROOF_SURFACE_Y))
		var image: Image = DATA.CRAWL_TEXTURES[variant].get_image()
		if image.is_compressed():
			image.decompress()
		for frame in range(4):
			var source: Rect2 = DATA.crawl_frame(variant, frame)
			var solid := false
			for x in range(int(source.position.x), int(source.end.x)):
				if image.get_pixel(x, int(source.end.y) - 1).a > 0.2:
					solid = true
					break
			assert(solid, "Sprite baseline must contain visible hands or knees, not transparent margin.")
		print("ROOF_CONTACT variant=",variant," front=",anchor.x + float(DATA.profile(variant).visual_height)*0.5," roof_y=",anchor.y)
	print("ROOF_CONTACT_OK types=5 frames=20")
	get_tree().quit()
