extends Node
func _ready() -> void:
	call_deferred("_run")
func key(code: Key, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.keycode=code;e.physical_keycode=code;e.pressed=pressed
	Input.parse_input_event(e)
func _run() -> void:
	for levels in [Vector2i(1,0),Vector2i(1,1),Vector2i(2,1)]:
		var d=load("res://scenes/amsterdam_preview.tscn").instantiate()
		d.workshop_vehicle="kombi"
		d.workshop_upgrades={"engine":levels.x,"nitro":levels.y,"tank":3}
		get_tree().root.add_child(d)
		await get_tree().physics_frame
		var c=d.course
		var w=d.wagon
		c._upper_launch_triggered=true
		c._branch_decided=true
		for event in c._encounters:
			event.done=true
		w.reset_at(1160.0*36,c)
		w.freeze=false
		w.linear_velocity.x=22.0*36
		d._run_started=true
		var takeoff := -1.0
		var landed := false
		for frame in range(1300):
			key(KEY_W,true)
			key(KEY_SPACE,w.position.x/36.0 >= c.LOCK_START_M-75.0)
			await get_tree().physics_frame
			if c._lock_launched and takeoff < 0.0:
				takeoff=w.linear_velocity.x/36*3.6
			if w.position.x/36.0 > c.LOCK_REJOIN_M+3.0 and not w.airborne:
				landed=true
				break
			if c._lock_water_entered or d._finished:
				break
		key(KEY_W,false);key(KEY_SPACE,false)
		print("LOCK_UPGRADE_INPUT engine=",levels.x," nitro=",levels.y," takeoff_kmh=",takeoff," landed=",landed," water=",c._lock_water_entered)
		assert(landed and not c._lock_water_entered if takeoff>=c.LOCK_MIN_SPEED_KMH else not landed and c._lock_water_entered)
		if levels == Vector2i(2, 1):
			assert(landed, "The recommended Amsterdam build must cross the lock.")
		d.queue_free()
		await get_tree().process_frame
	print("LOCK_UPGRADE_TARGET_OK engine2_nitro1=true actual_speed_determines_landing=true")
	get_tree().quit()
