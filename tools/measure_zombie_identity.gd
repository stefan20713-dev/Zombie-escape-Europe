extends SceneTree
func _initialize() -> void:
	var im := Image.load_from_file("res://assets/zombie_attachment_identity_v4.png")
	print("ATLAS_SIZE ",im.get_size()," alpha_corner=",im.get_pixel(0,0).a)
	for row in range(5):
		for col in range(4):
			var cell := Rect2i(col*im.get_width()/4,row*im.get_height()/5,im.get_width()/4,im.get_height()/5)
			var low := cell.end
			var high := cell.position
			for y in range(cell.position.y,cell.end.y):
				for x in range(cell.position.x,cell.end.x):
					if im.get_pixel(x,y).a > 0.5:
						low=low.min(Vector2i(x,y)); high=high.max(Vector2i(x,y))
			var used := Rect2i(low,high-low+Vector2i.ONE)
			print("IDENTITY_BOUNDS ",row," ",col," ",used)
			if col < 2:
				var total := Vector2.ZERO
				var count := 0
				for y in range(used.position.y,used.end.y):
					for x in range(used.position.x,used.end.x):
						var pos := Vector2(x-used.position.x,y-used.position.y)
						var in_grip: bool = pos.y < used.size.y*0.12 if col==0 else pos.x>used.size.x*0.83 and pos.y<used.size.y*0.60
						if in_grip and im.get_pixel(x,y).a>0.8:
							total+=pos;count+=1
				print("IDENTITY_GRIP ",row," ",col," ",total/maxi(1,count))
	quit()

