extends Node
func _ready()->void:call_deferred("_run")
func key(code:Key,pressed:bool)->void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e)
func photo(name:String)->void:
	if DisplayServer.get_name()=="headless":return
	for i in range(3):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/hafenausfahrt-"+name+".png")
func _run()->void:
	var profile:Dictionary={"engine":2,"tires":2,"tank":3,"armor":2,"suspension":1,"nitro":1,"weapon":1}
	var store=load("res://scripts/game.gd").new()
	store._initialize_world_progress();store.money=321;store.upgrades=profile.duplicate(true);store.vehicle_upgrades["kombi"]=profile.duplicate(true)
	assert(store._save_progress()==OK);store.free()
	var d=load("res://scenes/amsterdam_preview.tscn").instantiate()
	d.workshop_vehicle="kombi";d.workshop_upgrades=profile.duplicate(true);d.workshop_rewards_enabled=true
	get_tree().root.add_child(d)
	await get_tree().physics_frame
	var w=d.wagon;var c=d.course
	assert(c.get_node_or_null("HarborExitForeground")==null,"Rejected gate must stay removed.")
	w.reset_at(1770*36,c);w.linear_velocity.x=38*36;w.freeze=false;d._run_started=true;c._harbor_ramp_triggered=true
	d.camera.position=w.position+Vector2(285,-75);d.camera.force_update_scroll()
	var entry_x:float=0;var health:float=0;var fuel:float=0;var captured:=false;var moving:=false
	for frame in range(800):
		key(KEY_W,true);await get_tree().physics_frame
		if not captured and d.distance_m>1782:captured=true;await photo("anlauf")
		if d._arrival_time_s>=0 and entry_x==0:
			entry_x=w.position.x;health=w.durability;fuel=w.fuel
			d._on_encounter_hit("zombie_group",1.0,5,1,w.position.x,w.position.y,20.0)
			assert(is_equal_approx(w.durability,health))
			assert(not d._finished and c._finish_safe)
			var paused_time:float=d._arrival_time_s
			d._toggle_pause()
			for i in range(3):await get_tree().physics_frame
			assert(is_equal_approx(d._arrival_time_s,paused_time))
			d._toggle_pause()
			await photo("ziellinie")
		if entry_x>0 and w.position.x>entry_x+20:moving=true
		if d._finished:break
	key(KEY_W,false)
	assert(entry_x>0 and moving and d._finished)
	assert(is_equal_approx(d.distance_m,1800))
	assert(is_equal_approx(w.fuel,fuel) and is_equal_approx(w.durability,health))
	assert(is_instance_valid(d._pause_overlay) and d._pause_overlay.name=="ArrivalResult")
	await photo("auswertung")
	var progress=load("res://scripts/game.gd").new();progress._initialize_world_progress();progress._load_progress()
	assert(progress.is_world_completed(0) and progress.world_best_distances[0]>=1800)
	var balance:int=progress.money
	assert(balance==321+d._arrival_income)
	for part in profile:assert(int(progress.upgrades.get(part,0))==int(profile[part]),"Finish must preserve bought "+part)
	d._record_workshop_reward()
	progress._load_progress();assert(progress.money==balance,"Result must never pay twice.");progress.free()
	get_tree().root.size=Vector2i(1920,864)
	await photo("auswertung-breit")
	var buttons:Array=d._pause_overlay.find_children("*","Button",true,false)
	var replay:Button=buttons.filter(func(b:Button):return b.text=="NOCHMAL FAHREN")[0]
	var point:Vector2=replay.get_global_rect().get_center()
	for pressed in [true,false]:
		var click:=InputEventMouseButton.new();click.position=point;click.global_position=point;click.button_index=MOUSE_BUTTON_LEFT;click.pressed=pressed
		get_viewport().push_input(click,true)
		await get_tree().process_frame
	for i in range(4):await get_tree().process_frame
	assert(d._arrival_time_s<0 and not c._finish_safe and not d._finished)
	print("HARBOR_ARRIVAL_OK real_input=true coast=true safe=true income_once=true completed_saved=true upgrades_preserved=true restart=true wide=true")
	get_tree().quit()
