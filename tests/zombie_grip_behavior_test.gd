extends Node
func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	var d=load("res://scenes/amsterdam_preview.tscn").instantiate()
	get_tree().root.add_child(d)
	await get_tree().physics_frame
	d.set_physics_process(false)
	d.course.set_physics_process(false)
	var w=d.wagon
	for variant in range(1,6):
		w.reset_at(50.0*36,d.course)
		w.add_zombie_latch(20.0,0.5,0,variant,0.0,2)
		assert(w.zombie_latches[0].mount=="side")
		for frame in range(70):
			w.linear_velocity.x=20*36
			w.update_zombie_latches(0.05)
		assert(w.zombie_latches.size()==1 and w.zombie_latches[0].mount=="roof")
		assert(int(w.zombie_latches[0].variant)==variant,"Climbing must preserve the attached character identity.")
		w.rotation=2.2
		w.angular_velocity=2.0
		w.update_zombie_latches(0.05)
		assert(w.zombie_latches.is_empty() and w._released_zombies.size()==1)
		assert(int(w._released_zombies[0].variant)==variant,"Falling must retain the same zombie identity.")
		var point: Vector2=w._released_zombies[0].position
		w.position.x+=1000.0
		w.update_zombie_latches(0.1)
		assert(Vector2(w._released_zombies[0].position).distance_to(point)<300.0)
		assert(float(w._released_zombies[0].ground_age)<1.8)
		w.update_zombie_latches(6.0)
		assert(w._released_zombies.is_empty())
		print("GRIP_BEHAVIOR variant=",variant," side_to_roof=true rotation_release=true world_fall=true")
	w.reset_at(50.0*36,d.course)
	w.add_zombie_latch(0.01,0.5,0,1)
	w.update_zombie_latches(0.05)
	assert(w.zombie_latches.size()==1 and float(w.zombie_latches[0].slipping)>0)
	w.update_zombie_latches(0.45)
	assert(w.zombie_latches.is_empty() and w._released_zombies.size()==1)
	w.update_zombie_latches(0.30)
	assert(w._released_zombies.size()==1 and float(w._released_zombies[0].ground_age)<1.8)
	print("ZOMBIE_GRIP_BEHAVIOR_OK variants=5 side_roof_slip_rotation_fall=true")
	get_tree().quit()

