extends Node
func _ready() -> void:
	call_deferred("_run")
func shot(label: String) -> void:
	for frame in range(8):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/instrumente-"+label+".png")
func _run() -> void:
	var d=load("res://scenes/amsterdam_preview.tscn").instantiate()
	d.workshop_vehicle="kombi"
	d.workshop_upgrades={"engine":2,"tires":2,"tank":3,"armor":2,"nitro":1,"weapon":1}
	get_tree().root.add_child(d)
	await get_tree().physics_frame
	d.set_physics_process(false);d.course.set_physics_process(false)
	var w=d.wagon
	w.reset_at(1480*36,d.course)
	d.camera.position=w.position+Vector2(285,-75);d.camera.force_update_scroll()
	d.distance_m=1473;d._run_started=true
	w.linear_velocity.x=135.0/3.6*36;w.fuel=w.fuel_capacity*0.72;w.nitro=w.nitro_capacity*0.58;w.durability=83
	d._update_hud(false,false,false)
	await shot("normal")
	w.fuel=w.fuel_capacity*0.08;w.nitro=w.nitro_capacity*0.17;w.durability=14;w.boost_active=true
	await shot("reserve")
	w.nitro_level=0;w.nitro=0;w.nitro_capacity=0;w.linear_velocity=Vector2.ZERO
	await shot("ohne-nitro")
	get_tree().root.size=Vector2i(1920,864)
	w.nitro_level=1;w.nitro_capacity=120;w.nitro=85;w.fuel=w.fuel_capacity;w.durability=100;w.boost_active=false
	await shot("breit")
	print("INSTRUMENTS_GALLERY_OK live_values=true reserve_empty_uninstalled_wide=true")
	get_tree().quit()
