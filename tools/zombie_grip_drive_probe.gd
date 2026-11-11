extends Node
func _ready() -> void:
	call_deferred("_run")
func key(code: Key, pressed: bool) -> void:
	var e:=InputEventKey.new()
	e.keycode=code;e.physical_keycode=code;e.pressed=pressed
	Input.parse_input_event(e)
func _run() -> void:
	var d=load("res://scenes/amsterdam_preview.tscn").instantiate()
	d.workshop_vehicle="kombi"
	d.workshop_upgrades={"engine":2,"tires":1,"armor":2,"tank":3,"nitro":1}
	get_tree().root.add_child(d)
	await get_tree().physics_frame
	var w=d.wagon
	w.reset_at(350.0*36,d.course)
	w.freeze=false
	w.linear_velocity.x=24*36
	d._run_started=true
	w.add_zombie_latch(20.0,0.5,0,3,0.0,2)
	w.add_zombie_latch(20.0,0.5,1,1)
	d.camera.position=w.position+Vector2(285,-75)
	d.camera.force_update_scroll()
	var release_seen:=false
	var turn_frames:=0
	var after_release:=0
	for frame in range(800):
		key(KEY_W,true);key(KEY_SPACE,true)
		if w.airborne or turn_frames>0:turn_frames+=1
		key(KEY_D,turn_frames>0 and not release_seen)
		await get_tree().physics_frame
		if not w._released_zombies.is_empty():release_seen=true
		if release_seen:
			after_release+=1
			if after_release in [1,20,50] and DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://build/grips-live-fall-%d.png" % after_release)
		if after_release>90 or d._finished:break
	for code in [KEY_W,KEY_SPACE,KEY_D]:key(code,false)
	print("LIVE_GRIP_ROTATION release_seen=",release_seen," remaining=",w.zombie_latches.size()," angle=",w.rotation," roof_crash=",d._roof_crash_time_s)
	assert(release_seen and w.zombie_latches.is_empty(),"Actual rotation inputs must make both grips let go visibly.")
	get_tree().quit()
