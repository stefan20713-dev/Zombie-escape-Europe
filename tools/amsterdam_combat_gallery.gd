extends Node
var drive: Node
func _ready() -> void:
	call_deferred("_run")
func shot(name: String) -> void:
	for item in get_tree().root.find_children("*", "CanvasItem", true, false):
		item.queue_redraw()
	for i in range(5):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/combat-" + name + ".png")
func _run() -> void:
	drive = load("res://scenes/amsterdam_preview.tscn").instantiate()
	drive.workshop_vehicle = "kombi"
	drive.workshop_upgrades = {"engine": 2, "tires": 2, "tank": 3, "armor": 2, "nitro": 3, "weapon": 1, "suspension": 1}
	get_tree().root.add_child(drive)
	await get_tree().physics_frame
	drive.set_physics_process(false)
	drive.course.set_physics_process(false)
	var c = drive.course
	var w = drive.wagon
	for meter in [134.0, 266.0, 277.0, 351.0, 565.0, 574.0, 585.0, 610.0, 683.0, 711.0, 952.0]:
		w.reset_at(meter * 36.0, c)
		drive.distance_m = meter - 7.0
		drive.camera.position = w.position + Vector2(278, -75)
		drive.camera.zoom = Vector2.ONE * 1.5
		drive.camera.force_update_scroll()
		drive._update_hud(false, false, false)
		await shot("strecke-%04d" % int(meter))
	w.reset_at(134.0 * 36.0, c)
	drive.distance_m = 127.0
	drive._update_hud(false, false, false)
	drive.camera.position = w.position + Vector2(278, -75)
	drive.camera.force_update_scroll()
	c.explosives._detonate(c.explosives.drums[0], w)
	c.explosives.blasts[0].age = 0.15
	await shot("explosion")
	for armor in [0, 1, 2, 3]:
		w.configure({"armor": armor, "tires": 1}, "kombi")
		w.reset_at(200.0 * 36.0, c)
		drive.distance_m = 193.0
		drive.camera.position = w.position + Vector2(278, -75)
		drive.camera.force_update_scroll()
		for health in [100.0, 80.0, 60.0, 40.0, 20.0, 0.0]:
			w.durability = health
			drive._update_hud(false, false, false)
			await shot("panzer-%d-zustand-%03d" % [armor,int(health)])
	print("COMBAT_GALLERY_OK route=11 explosion=1 damage=24")
	get_tree().quit()
