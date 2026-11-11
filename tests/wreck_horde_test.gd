extends Node
func _ready()->void:call_deferred("_run")
func _run()->void:
	var d=load("res://scenes/amsterdam_preview.tscn").instantiate()
	get_tree().root.add_child(d)
	await get_tree().physics_frame
	d.set_physics_process(false)
	d.course.set_physics_process(false)
	var w=d.wagon;var c=d.course
	w.reset_at(1008*36,c);w.rotation=PI
	d._begin_roof_crash()
	assert(c._wreck_horde.size()==6)
	for enemy in c._wreck_horde:
		assert(float(enemy.facing)==signf(float(enemy.x)-w.position.x),"Walking source faces left: mirror must face the wreck.")
	for i in range(1,3):
		assert(absf(float(c._wreck_horde[i].target)-float(c._wreck_horde[i-1].target))>=160.0)
	var start:float=absf(float(c._wreck_horde[0].x)-w.position.x)
	for i in range(180):d._physics_process(1.0/60.0)
	assert(absf(float(c._wreck_horde[0].x)-w.position.x)<start)
	assert(c._wreck_horde.any(func(enemy:Dictionary):return float(enemy.attack_time)>.5),"Nearby zombies must reach and grab the car.")
	assert(not d._finished and w.roof_crash_time_s>=2.9)
	d.camera.position=w.position+Vector2(240,-45);d.camera.force_update_scroll()
	if DisplayServer.get_name()!="headless":
		for i in range(6):await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://build/wrack-zombiehorde.png")
	for i in range(60):d._physics_process(1.0/60.0)
	assert(d._finished)
	d._start_test_run()
	assert(c._wreck_horde.is_empty())
	print("WRECK_HORDE_OK count=6 approaches=true fire_game_over=true restart_clears=true")
	get_tree().quit()
