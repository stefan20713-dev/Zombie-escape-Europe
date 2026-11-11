extends Node
var d: Node
func _ready() -> void:
	call_deferred("_run")
func shot(label: String) -> void:
	d.course.queue_redraw()
	d.wagon.queue_redraw()
	for frame in range(5):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/grips-"+label+".png")
func prepare() -> void:
	d.wagon.reset_at(1008.0*36.0,d.course)
	d.wagon.durability=65.0
	d.wagon.linear_velocity.x=25.0*36.0
	d.distance_m=1001.0
	d.camera.position=d.wagon.position+Vector2(278,-75)
	d.camera.zoom=Vector2.ONE*1.5
	d.camera.force_update_scroll()
	d._update_hud(false,false,false)
func _run() -> void:
	d=load("res://scenes/amsterdam_preview.tscn").instantiate()
	d.workshop_vehicle="kombi"
	d.workshop_upgrades={"tank":3}
	get_tree().root.add_child(d)
	await get_tree().physics_frame
	d.set_physics_process(false)
	d.course.set_physics_process(false)
	for kind in range(1,6):
		prepare()
		d.wagon.add_zombie_latch(12.0,0.6,0,kind,0.0,2)
		for frame in range(15):d.wagon.update_zombie_latches(0.05)
		await shot("seite-"+str(kind))
		for frame in range(21):d.wagon.update_zombie_latches(0.05)
		await shot("uebergang-"+str(kind))
		for frame in range(19):d.wagon.update_zombie_latches(0.05)
		await shot("dach-"+str(kind))
	prepare()
	d.wagon.add_zombie_latch(12.0,0.6,0,3,0.0,1)
	for frame in range(35):d.wagon.update_zombie_latches(0.05)
	await shot("hochklettern")
	d.wagon.rotation=2.3
	d.wagon.angular_velocity=2.2
	d.wagon.update_zombie_latches(0.05)
	assert(d.wagon.zombie_latches.is_empty())
	assert(float(d.wagon._released_zombies[0].get("pull",-1.0))>=0.0)
	await shot("abfallen-beim-klettern")
	prepare()
	d.wagon.add_zombie_latch(12.0,0.6,0,3,0.0,1)
	for frame in range(35):d.wagon.update_zombie_latches(0.05)
	for frame in range(20):d.wagon.update_zombie_latches(0.05)
	await shot("dach")
	prepare()
	d.wagon.add_zombie_latch(12.0,0.6,0,3,0.0,2)
	for frame in range(10):d.wagon.update_zombie_latches(0.05)
	d.wagon.rotation=2.3
	d.wagon.angular_velocity=2.2
	d.wagon.update_zombie_latches(0.05)
	assert(d.wagon.zombie_latches.is_empty() and not d.wagon._released_zombies.is_empty())
	for frame in range(8):d.wagon.update_zombie_latches(0.05)
	await shot("abfallen-drehung")
	for frame in range(20):d.wagon.update_zombie_latches(0.05)
	await shot("gelandet")
	print("GRIP_GALLERY_OK types=5 side_roof_climb_rotation_release=true")
	get_tree().quit()
