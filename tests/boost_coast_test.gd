extends Node2D
func height_at(_x:float)->float:return 500.0
func slope_at(_x:float)->float:return 0.0
func _ready()->void:call_deferred("run")
func run()->void:
	for vehicle in ["kombi","lieferwagen","offroad_pickup"]:
		var w=load("res://scenes/wagon.tscn").instantiate();add_child(w)
		await get_tree().physics_frame
		w.configure({"engine":2,"nitro":1},vehicle);w.freeze=true
		var base:float=w._max_speed_pixels_s
		w.linear_velocity=Vector2(base*1.10,0)
		w.simulate(1.0/60,true,false,true,0)
		var before:float=w.linear_velocity.x
		w.simulate(1.0/60,true,false,false,0)
		assert(w.linear_velocity.x>base*1.05,"Releasing boost must not instantly erase momentum: "+vehicle)
		assert(before-w.linear_velocity.x<20.0)
		w.reset_at(0,self)
		assert(not w._boost_coasting and not w.boost_active)
		w.nitro=0;w.boost_active=true;w.linear_velocity=Vector2(base*1.10,0)
		w.simulate(1.0/60,true,false,true,0)
		assert(w.linear_velocity.x>base*1.05 and w.nitro==0,"Empty held boost must coast without giving free nitro.")
		w.configure({"engine":2,"nitro":0},vehicle);w.linear_velocity=Vector2(base*1.10,0)
		w.simulate(1.0/60,true,false,false,0)
		assert(w.linear_velocity.x<=base+.1,"Unboosted motor speed band must remain unchanged.")
		print("BOOST_COAST_OK vehicle=",vehicle)
		w.queue_free();await get_tree().process_frame
	get_tree().quit()
