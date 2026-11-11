extends SceneTree
func _initialize() -> void:
	var icons=load("res://scripts/workshop_icons.gd")
	for part in icons.TEXTURES:
		var texture:Texture2D=icons.TEXTURES[part]
		var image:Image=texture.get_image()
		assert(image.get_width()<=512 and image.get_height()<=512)
		for corner in [Vector2i.ZERO,Vector2i(image.get_width()-1,0),image.get_size()-Vector2i.ONE,Vector2i(0,image.get_height()-1)]:
			assert(image.get_pixelv(corner).a<0.01,"Icon background must be transparent: "+part)
		var used:Rect2=icons.source(part)
		assert(used.size.x>20 and used.size.y>20)
		print("WORKSHOP_ART ",part," size=",image.get_size()," bounds=",used," mipmaps=",image.has_mipmaps())
	print("WORKSHOP_ART_OK six_isolated_icons=true mobile_import_limit=512")
	quit()
