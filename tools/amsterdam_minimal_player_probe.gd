extends "res://tools/amsterdam_player_loop_probe.gd"
func _run()->void:
	game=load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game);get_tree().current_scene=game
	await wait_frames(12);assert(game.money==100 and not game.stock_test_mode)
	await click_hud("garage")
	for page in range(3):await click_hud("tutorial:next")
	await click_hud("tutorial:start")
	for attempt in range(2):
		await wait_frames(8);drive=get_tree().current_scene
		var levels:Dictionary=drive.workshop_upgrades.duplicate(true)
		var frames:=0
		while not drive._finished and frames<9000:
			var w=drive.wagon;var c=drive.course;var meter:float=w.position.x/36
			key(KEY_W,true);key(KEY_SPACE,meter>=c.LOCK_START_M-75 and meter<c.LOCK_REJOIN_M)
			var error:float=wrapf(w.rotation-c.slope_at(w.position.x),-PI,PI)
			var unsteady:bool=w.airborne or w.front_spring.is_colliding()!=w.rear_spring.is_colliding() or absf(error)>.35
			key(KEY_D,unsteady and error<-.10);key(KEY_A,unsteady and error>.10)
			await get_tree().physics_frame;frames+=1
			if frames%600==0:print("MINIMAL_PLAYER_PROGRESS attempt=",attempt+1," distance=",drive.distance_m," health=",w.durability," fuel=",w.fuel)
		for code in [KEY_W,KEY_SPACE,KEY_A,KEY_D]:key(code,false)
		assert(drive._finished)
		var balance:int=drive._arrival_balance
		print("MINIMAL_PLAYER_RESULT attempt=",attempt+1," distance=",drive.distance_m," income=",drive._arrival_income," balance=",balance," levels=",levels)
		if attempt==1:assert(drive.distance_m>=1800)
		await photo("minimal-versuch-"+str(attempt+1))
		var buttons:Array=drive._pause_overlay.find_children("*","Button",true,false)
		var back:Button=buttons.filter(func(b:Button):return b.text=="ZUR WERKSTATT")[0]
		await click_point(back.get_global_rect().get_center());game=get_tree().current_scene
		assert(game.money==balance)
		for part in levels:assert(game.upgrade_level(part)==int(levels[part]))
		if attempt==0:
			for part in ["engine","engine","tank","nitro"]:
				await click_hud("garage_part:"+part)
				var before:int=game.money;var price:int=game.upgrade_price(part)
				var owned:Dictionary=game.upgrades.duplicate(true)
				assert(before>=price)
				await click_hud("upgrade");assert(game.money==before-price)
				for other in owned:assert(game.upgrade_level(other)==int(owned[other])+(1 if other==part else 0))
			assert(game.upgrade_level("engine")==2 and game.upgrade_level("tank")==1 and game.upgrade_level("nitro")==1)
			for part in ["tires","armor","suspension","efficiency","brakes","weapon"]:assert(game.upgrade_level(part)==0)
			await click_hud("start")
	var file:=FileAccess.open("res://.local_probe/minimal-player-expected.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"money":game.money,"levels":game.upgrades}));file.close()
	print("MINIMAL_PLAYER_OK actual_purchases=4 independent=true balance=",game.money)
	get_tree().quit()
