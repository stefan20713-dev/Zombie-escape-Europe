extends Node
func _ready() -> void:
	call_deferred("_run")
func key(code: Key,pressed: bool)->void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e)
func _run()->void:
	for boost in [false,true]:
		var d=load("res://scenes/amsterdam_preview.tscn").instantiate()
		d.workshop_vehicle="kombi";d.workshop_upgrades={"engine":2,"tires":2,"tank":3,"armor":2,"suspension":1,"nitro":1}
		if not boost: d.workshop_upgrades["engine"]=0
		get_tree().root.add_child(d)
		await get_tree().physics_frame
		var w=d.wagon;var c=d.course
		for event in c._encounters:event.done=true
		w.reset_at((350.0 if boost else 390.0)*36,c);w.linear_velocity.x=(22.0 if boost else 5.0)*36;w.freeze=false;d._run_started=true
		for frame in range(1600):
			key(KEY_W,true);key(KEY_SPACE,boost)
			await get_tree().physics_frame
			if d._finished or w.position.x>548*36:break
		key(KEY_W,false);key(KEY_SPACE,false)
		print("UPPER_WHEEL_EDGE boost=",boost," chosen=",c._upper_route_chosen," missed=",c._upper_missed_edge," end=",w.position.x/36)
		assert(c._upper_route_chosen if boost else not c._upper_route_chosen)
		assert(w.position.x>540*36 and not d._finished,"Both successful and missed jumps must continue without snagging.")
		d.queue_free();await get_tree().process_frame
	print("UPPER_BRIDGE_REAL_EDGE_OK fast_deck=true slow_lower_road=true")
	get_tree().quit()
