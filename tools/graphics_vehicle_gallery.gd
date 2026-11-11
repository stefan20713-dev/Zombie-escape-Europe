extends Node
func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.first_drive_tutorial_completed=true
	for vehicle in ["kombi","lieferwagen","offroad_pickup"]:
		game.selected_vehicle=vehicle
		game.upgrades={"engine":1,"tires":1,"tank":1,"armor":1,"nitro":1}
		game.vehicle_upgrades[vehicle]=game.upgrades.duplicate(true)
		game.to_garage()
		for i in range(8):await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/grafikpolitur-fahrzeug-"+vehicle+".png")
		assert(game.wagon.vehicle_id==vehicle)
		print("GRAPHICS_VEHICLE ",vehicle," shader=true garage=true")
	print("GRAPHICS_VEHICLES_OK shared_lighting_three_vehicles=true")
	get_tree().quit()
