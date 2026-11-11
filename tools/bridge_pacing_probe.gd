extends Node
var drive: Node
var samples: Array[float] = []
var last_us := 0
var recording := false
func _ready() -> void:
	call_deferred("_run")
func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if recording and last_us > 0:
		samples.append(float(now-last_us)/1000.0)
	last_us = now
func key(code: Key, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.keycode=code; e.physical_keycode=code; e.pressed=pressed
	Input.parse_input_event(e)
func _run() -> void:
	for section in [Vector2(350,550),Vector2(1160,1360)]:
		drive=load("res://scenes/amsterdam_preview.tscn").instantiate()
		drive.workshop_vehicle="kombi"
		drive.workshop_upgrades={"engine":2,"tires":2,"tank":3,"armor":2,"suspension":1,"nitro":1,"weapon":1}
		get_tree().root.add_child(drive)
		await get_tree().physics_frame
		var w=drive.wagon
		var c=drive.course
		c._upper_launch_triggered=section.x>1000
		c._branch_decided=section.x>1000
		w.reset_at(section.x*36,c)
		w.freeze=false
		w.linear_velocity.x=22.0*36
		drive._run_started=true
		drive.camera.position=w.position+Vector2(285,-75)
		drive.camera.force_update_scroll()
		samples.clear()
		var peak_speed := 0.0
		for frame in range(1600):
			var meter:float=w.position.x/36
			recording=frame>40 and meter < section.y
			key(KEY_W,true);key(KEY_SPACE,true)
			var error:float=wrapf(w.rotation-c.slope_at(w.position.x),-PI,PI)
			key(KEY_D,w.airborne and error < -0.12);key(KEY_A,w.airborne and error > 0.12)
			await get_tree().physics_frame
			peak_speed=maxf(peak_speed,w.speed_mps*3.6)
			if drive._finished or meter>section.y:
				break
		recording=false
		for code in [KEY_W,KEY_SPACE,KEY_A,KEY_D]:key(code,false)
		samples.sort()
		if not samples.is_empty():
			print("BRIDGE_PACING start=",section.x," end=",w.position.x/36," frames=",samples.size()," median_ms=",samples[samples.size()/2]," p95_ms=",samples[int(samples.size()*0.95)]," max_ms=",samples[-1]," peak_kmh=",peak_speed," lock_water=",c._lock_water_entered," upper=",c._upper_route_chosen)
		drive.queue_free()
		await get_tree().process_frame
	get_tree().quit()
