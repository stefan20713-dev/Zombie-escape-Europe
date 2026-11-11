extends Node
var records:Array[Dictionary]=[]
func _ready()->void:call_deferred("run")
func key(code:Key,pressed:bool)->void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e)
func run()->void:
	for name in ["abschluss","abschluss-unruhiger","komfort"]:
		var d=load("res://scenes/amsterdam_preview.tscn").instantiate()
		d.workshop_vehicle="kombi"
		var levels:Dictionary={"engine":0,"tires":0,"tank":0,"armor":0,"nitro":0,"weapon":0}
		if name=="motor1-nitro2":levels={"engine":1,"tires":1,"tank":1,"armor":1,"nitro":2,"weapon":0}
		elif name.begins_with("abschluss"):levels={"engine":2,"tires":0,"tank":1,"armor":0,"nitro":1,"weapon":0}
		if name=="komfort":levels={"engine":2,"tires":1,"tank":1,"armor":1,"nitro":1,"weapon":0}
		d.workshop_upgrades=levels
		get_tree().root.add_child(d)
		await get_tree().physics_frame
		var w=d.wagon;var c=d.course;var frames:=0;var pauses:=0
		while not d._finished and frames<9000:
			var meter:float=w.position.x/36.0
			# The second completion drive includes a real brief brake before a straight,
			# and less precise air corrections, never a forced landing or damage refund.
			var brake:bool=name=="abschluss-unruhiger" and meter>970 and pauses<30
			if brake:pauses+=1
			key(KEY_W,not brake);key(KEY_S,brake)
			key(KEY_SPACE,meter>=c.LOCK_START_M-75 and meter<c.LOCK_REJOIN_M)
			var error:float=wrapf(w.rotation-c.slope_at(w.position.x),-PI,PI)
			var unsteady:bool=w.airborne or w.front_spring.is_colliding()!=w.rear_spring.is_colliding() or absf(error)>.35
			var threshold:float=.20 if name=="abschluss-unruhiger" else .10
			key(KEY_D,unsteady and error < -threshold);key(KEY_A,unsteady and error>threshold)
			await get_tree().physics_frame;frames+=1
			if frames%600==0:print("MINIMAL_PROGRESS profile=",name," m=",d.distance_m," fuel=",w.fuel," health=",w.durability)
		for code in [KEY_W,KEY_S,KEY_SPACE,KEY_A,KEY_D]:key(code,false)
		assert(d._finished)
		var earned:int=floori(minf(d.distance_m,1800.0)/16.0)+d._zombie_coins+d._preview_bonus_coins
		var result:Dictionary={"profile":name,"levels":levels,"distance":d.distance_m,"seconds":d.elapsed_s,"fuel":w.fuel,"fuel_percent":w.fuel/w.fuel_capacity*100,"health":w.durability,"income":earned,"lock_water":c._lock_water_entered}
		records.append(result);print("MINIMAL_RESULT ",JSON.stringify(result))
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/balance-minimal-"+name+".png")
		d.queue_free();await get_tree().process_frame
	var file:=FileAccess.open("res://.local_probe/balance-minimal-results.json",FileAccess.WRITE);file.store_string(JSON.stringify(records,"\t"));file.close()
	assert(float(records[0].distance)>=1800 and float(records[1].distance)>=1800,"Both completion drives must succeed.")
	print("MINIMAL_FOUR_DRIVES_OK")
	get_tree().quit()
