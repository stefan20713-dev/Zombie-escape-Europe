extends Node
var shots := 0
var contacts := 0
var max_latches := 0
var ahead_blasts := 0
var d: Node
func _ready() -> void:
	call_deferred("_run")
func key(code: Key, pressed: bool) -> void:
	var e := InputEventKey.new()
	e.keycode=code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e)
func shot_photo(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/weapon-clearance-"+label+".png")
func _run() -> void:
	var results: Array[Dictionary]=[]
	for weapon in [0,1]:
		shots=0;contacts=0;max_latches=0;ahead_blasts=0
		d=load("res://scenes/amsterdam_preview.tscn").instantiate()
		d.workshop_vehicle="kombi"
		d.workshop_upgrades={"engine":2,"tires":2,"tank":3,"armor":2,"suspension":1,"nitro":1,"weapon":weapon}
		get_tree().root.add_child(d)
		await get_tree().physics_frame
		var w=d.wagon;var c=d.course
		assert(c._encounters.all(func(e:Dictionary):return String(e.get("prop",""))!="harbor_metal_gate"))
		c.zombie_shot.connect(func():shots+=1)
		c.encounter_hit.connect(func(kind,_r,_v,_n,_x,_y,_s):
			if String(kind) in ["zombie_group","runner_group"]:contacts+=1)
		c.explosives.exploded.connect(func(_n,_chain):
			var blast:Dictionary=c.explosives.blasts.back()
			if Vector2(blast.center).x>w.position.x+w.front_contact_offset_px():ahead_blasts+=1)
		w.reset_at(1450.0*36,c);w.linear_velocity.x=32*36;w.freeze=false;d._run_started=true
		d.camera.position=w.position+Vector2(285,-75);d.camera.force_update_scroll()
		var explosion_photo:=false
		var gate_photo:=false
		for frame in range(1400):
			key(KEY_W,true)
			await get_tree().physics_frame
			max_latches=maxi(max_latches,w.zombie_latches.size())
			if weapon==1 and ahead_blasts>0 and not explosion_photo:
				explosion_photo=true;await shot_photo("explosion")
			if weapon==1 and w.position.x/36>1505 and not gate_photo:
				gate_photo=true;await shot_photo("tor-entfernt")
			if w.position.x>1625*36 or d._finished:break
		key(KEY_W,false)
		assert(w.position.x>1625*36 and not d._finished)
		results.append({"shots":shots,"contacts":contacts,"latches":max_latches,"ahead":ahead_blasts})
		print("WEAPON_DRIVE level=",weapon," result=",results.back())
		d.queue_free();await get_tree().process_frame
	assert(results[1].shots>0 and results[1].contacts<results[0].contacts)
	assert(results[1].ahead>=2,"Mounted weapon must detonate both drums ahead of the visible front.")
	assert(results[1].latches<=results[0].latches)
	print("WEAPON_CLEARANCE_OK gate_removed=true ahead_explosions=true fewer_zombie_contacts=true")
	get_tree().quit()
