extends "res://tools/amsterdam_player_loop_probe.gd"
func _run()->void:
	game=load("res://scenes/main.tscn").instantiate();get_tree().root.add_child(game);get_tree().current_scene=game
	await wait_frames(12)
	await click_hud("garage");await click_hud("stock_test_toggle")
	assert(game.get_node("HUDLayer/HUD")._garage_selected_part=="engine")
	await click_point(Vector2(99,612))
	for step in range(2):
		await click_hud("upgrade")
		assert(game.upgrade_level("engine")==step+1)
		assert(game.upgrade_level("tires")==0)
		assert("MOTOR" in game.toast_text)
	for part in ["nitro","tank"]:
		await click_hud("garage_part:"+part);await click_hud("upgrade")
	print("STOCK_WORKSHOP levels=",game.upgrades," stock=",game.stock_test_mode)
	assert(game.upgrade_level("engine")==2 and game.upgrade_level("tank")==1 and game.upgrade_level("nitro")==1)
	await click_hud("start");await wait_frames(8)
	drive=get_tree().current_scene
	var modern:bool=drive.get_script().resource_path.ends_with("driving_test.gd")
	var balanced:bool="--balance-controls" in OS.get_cmdline_user_args()
	var route=drive.course if modern else drive.terrain
	var end:=false;var frames:=0;var distance:=0.0;var captured:=false
	print("STOCK_ACTUAL wagon_stock=",drive.wagon.stock_test_mode);print("ROUTE_CHECK scene=",drive.get_script().resource_path," levels=",game.upgrades if not modern else drive.workshop_upgrades," balanced=",balanced)
	while not end and frames<9000:
		var w=drive.wagon
		key(KEY_W,true);key(KEY_SPACE,w.position.x/36>=1167 or "--all-nitro" in OS.get_cmdline_user_args() or ("--pulse-nitro" in OS.get_cmdline_user_args() and (w.position.x/36<130 or (w.position.x/36>330 and w.position.x/36<480) or (w.position.x/36>620 and w.position.x/36<780))))
		var error:float=wrapf(w.rotation-route.slope_at(w.position.x),-PI,PI)
		var unsteady:bool=w.airborne or w.front_spring.is_colliding()!=w.rear_spring.is_colliding() or absf(error)>.35
		key(KEY_D,balanced and unsteady and error<-.1);key(KEY_A,balanced and unsteady and error>.1)
		await get_tree().physics_frame;frames+=1
		distance=drive.distance_m if modern else maxf(0.0,drive._meter_at(w.position.x)-drive.run_start_meter)
		if frames%600==0:print("ROUTE_PROGRESS m=",distance," fuel=",w.fuel," health=",w.durability," angle=",w.rotation)
		if not captured and distance>=719:
			captured=true;print("AT_719 fuel=",w.fuel," health=",w.durability," angle=",w.rotation);await photo("719-kontrolle")
		end=drive._finished if modern else drive.screen_state in ["RESULT","WIN"]
	for code in [KEY_W,KEY_SPACE,KEY_A,KEY_D]:key(code,false)
	print("ROUTE_RESULT distance=",distance," fuel=",drive.wagon.fuel," health=",drive.wagon.durability," modern=",modern," balanced=",balanced," ended=",end)
	assert(distance>=1800 and modern)
	if DisplayServer.get_name()!="headless":await photo("719-auswahl-korrigiert")
	get_tree().quit()
