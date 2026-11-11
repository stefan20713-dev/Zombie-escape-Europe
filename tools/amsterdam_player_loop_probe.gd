extends Node
var game:Node
var drive:Node
var results:Array[Dictionary]=[]
func _ready()->void:call_deferred("_run")
func wait_frames(count:int=5)->void:
	for i in range(count):await get_tree().process_frame
func click_point(point:Vector2)->void:
	for pressed in [true,false]:
		var e:=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed
		get_viewport().push_input(e,true);await get_tree().process_frame
	await wait_frames()
func click_hud(id:String)->void:
	await wait_frames(2)
	var hud=game.get_node("HUDLayer/HUD")
	var found:Array=hud.buttons.filter(func(b:Dictionary):return String(b.id)==id)
	assert(found.size()==1,"Expected actual UI action "+id)
	await click_point(Rect2(found[0].rect).get_center())
func key(code:Key,pressed:bool)->void:
	var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=pressed;Input.parse_input_event(e)
func photo(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/spielerweg-"+label+".png")
func _run()->void:
	assert("--amsterdam-werkstatt" in OS.get_cmdline_user_args(),"Use the real launcher mode.")
	game=load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game);get_tree().current_scene=game
	await wait_frames(12)
	assert(game.money==100 and not game.stock_test_mode)
	await click_hud("garage")
	for page in range(3):await click_hud("tutorial:next")
	await photo("einfuehrung")
	await click_hud("tutorial:start")
	for attempt in range(3):
		await wait_frames(8)
		drive=get_tree().current_scene
		assert(drive.has_method("_course_length_m") and drive.workshop_rewards_enabled)
		var levels:Dictionary=drive.workshop_upgrades.duplicate(true)
		print("PLAYER_ATTEMPT_START number=",attempt+1," levels=",levels)
		var frames:=0
		while not drive._finished and frames<10000:
			var w=drive.wagon;var c=drive.course
			key(KEY_W,true)
			var error:float=wrapf(w.rotation-c.slope_at(w.position.x),-PI,PI)
			key(KEY_D,w.airborne and error<-.12);key(KEY_A,w.airborne and error>.12)
			var meter:float=w.position.x/36
			key(KEY_SPACE,w.nitro_level>0 and meter>c.LOCK_START_M-75 and meter<c.LOCK_REJOIN_M)
			await get_tree().physics_frame;frames+=1
			if frames%600==0:print("PLAYER_PROGRESS attempt=",attempt+1," m=",drive.distance_m," health=",w.durability," fuel=",w.fuel)
		for code in [KEY_W,KEY_A,KEY_D,KEY_SPACE]:key(code,false)
		assert(drive._finished,"Attempt must reach a real result without forced ending.")
		var result:Dictionary={"attempt":attempt+1,"distance":drive.distance_m,"time":drive.elapsed_s,"earned":drive._arrival_income,"balance":drive._arrival_balance,"levels":levels}
		results.append(result);print("PLAYER_ATTEMPT_RESULT ",result)
		await photo("ergebnis-"+str(attempt+1))
		var buttons:Array=drive._pause_overlay.find_children("*","Button",true,false)
		var back:Button=buttons.filter(func(b:Button):return b.text=="ZUR WERKSTATT")[0]
		await click_point(back.get_global_rect().get_center())
		game=get_tree().current_scene
		assert(game.screen_state=="GARAGE" and game.money==int(result.balance))
		for part in levels:assert(game.upgrade_level(part)==int(levels[part]),"Return must retain "+part)
		await photo("werkstatt-"+str(attempt+1))
		if attempt==0:
			await click_hud("starter_package")
			assert(game.upgrade_level("engine")==1 and game.upgrade_level("tank")==1)
		elif attempt==1:
			var candidates:Array[String]=["nitro","armor","tires","engine"]
			var bought:=false
			for part in candidates:
				var price:int=game.upgrade_price(part)
				if price>0 and price<=game.money:
					await click_hud("garage_part:"+part)
					var before:int=game.money;var level:int=game.upgrade_level(part)
					await click_hud("upgrade")
					assert(game.money==before-price and game.upgrade_level(part)==level+1)
					bought=true;break
			assert(bought,"A second attempt must provide a meaningful affordable upgrade.")
		if attempt<2:await click_hud("start")
	print("PLAYER_LOOP_DONE results=",results," final_balance=",game.money," final_levels=",game.upgrades)
	get_tree().quit()
