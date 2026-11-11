extends SceneTree

func _initialize() -> void:
	var image := Image.load_from_file("res://assets/amsterdam_obstacle_atlas_0.5.58.png")
	print("IMAGE mode=%s size=%s" % [str(image.get_format()), str(image.get_size())])
	for point in [Vector2i(0, 0), Vector2i(760, 10), Vector2i(1500, 1000), Vector2i(1300, 20), Vector2i(100, 900)]:
		if point.x < image.get_width() and point.y < image.get_height():
			print("PIXEL %s %s" % [str(point), str(image.get_pixelv(point))])
	quit()
