extends Node
func _ready()->void:call_deferred("_run")
func _run()->void:
	var d=load("res://scenes/amsterdam_preview.tscn").instantiate()
	d.workshop_vehicle="kombi";d.workshop_upgrades={"engine":2,"tires":2,"tank":3,"armor":2,"nitro":1,"weapon":1}
	get_tree().root.add_child(d)
	await get_tree().physics_frame
	var c=d.course;var w=d.wagon
	var line:float=(c.START_M+c.AMSTERDAM_LENGTH_M)*36
	w.reset_at(line-350,c);w.linear_velocity.x=25*36;w.freeze=false;d._run_started=true;c._harbor_ramp_triggered=true
	d.camera.position=w.position+Vector2(250,-75);d.camera.force_update_scroll()
	var offsets:Array[float]=[-190,-80,0,80,190,280]
	var capture:=0
	for frame in range(300):
		var key:=InputEventKey.new();key.keycode=KEY_W;key.physical_keycode=KEY_W;key.pressed=true;Input.parse_input_event(key)
		await get_tree().physics_frame
		if capture<offsets.size() and w.position.x>=line+offsets[capture]:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/ziellinie-ohne-tor-%d.png"%capture)
			capture+=1
		if d._finished:break
	var key:=InputEventKey.new();key.keycode=KEY_W;key.physical_keycode=KEY_W;key.pressed=false;Input.parse_input_event(key)
	assert(capture>=5)
	assert(c.get_node_or_null("HarborExitForeground")==null)
	print("FINISH_WITHOUT_GATE_OK captured=",capture," gate_absent=true")
	get_tree().quit()
