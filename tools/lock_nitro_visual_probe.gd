extends Node
func _ready()->void:call_deferred("run")
func key(code:Key,pressed:bool)->void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e)
func run()->void:
	for start in [1100.0]:
		var d=load("res://scenes/amsterdam_preview.tscn").instantiate();d.workshop_vehicle="kombi"
		d.workshop_upgrades={"engine":2,"nitro":1,"tank":1,"tires":0,"armor":0,"weapon":0}
		get_tree().root.add_child(d);await get_tree().physics_frame
		var w=d.wagon;var c=d.course;var takeoff:=-1.0;var reserve:=-1.0
		for frame in range(7000):
			var meter:float=w.position.x/36
			key(KEY_W,true);key(KEY_SPACE,meter>=start)
			var error:float=wrapf(w.rotation-c.slope_at(w.position.x),-PI,PI)
			var unsteady:bool=w.airborne or w.front_spring.is_colliding()!=w.rear_spring.is_colliding() or absf(error)>.35
			key(KEY_D,unsteady and error<-.10);key(KEY_A,unsteady and error>.10)
			await get_tree().physics_frame
			if c._lock_launched and takeoff<0:takeoff=c._lock_flight_speed/36*3.6;reserve=w.nitro
			if d._finished:break
		for code in [KEY_W,KEY_SPACE,KEY_A,KEY_D]:key(code,false)
		print("LOCK_TIMING start=",start," takeoff=",takeoff," nitro=",reserve," water=",c._lock_water_entered," distance=",d.distance_m," health=",w.durability)
		assert(d.distance_m>=1800 and not c._lock_water_entered,"Early-held nitro must remain a genuinely playable full drive.")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/lock-nitro-early-fixed.png")
		d.queue_free();await get_tree().process_frame
	print("EARLY_NITRO_FULL_DRIVE_OK")
	get_tree().quit()
