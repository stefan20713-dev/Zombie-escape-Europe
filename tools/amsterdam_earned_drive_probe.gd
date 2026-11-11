extends "res://tools/amsterdam_player_loop_probe.gd"
func _run()->void:
	assert("--amsterdam-werkstatt" in OS.get_cmdline_user_args())
	game=load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game);get_tree().current_scene=game
	await wait_frames(12)
	assert(game.money==471,"Continue the genuinely earned profile, never seed coins.")
	await click_hud("garage")
	for part in ["tank","armor"]:
		await click_hud("garage_part:"+part)
		var before:int=game.money;var price:int=game.upgrade_price(part)
		var owned:Dictionary=game.upgrades.duplicate(true)
		await click_hud("upgrade")
		assert(game.money==before-price)
		for other in owned:assert(game.upgrade_level(other)==int(owned[other])+(1 if other==part else 0))
	assert(game.money==236)
	assert(game.upgrade_level("engine")==2 and game.upgrade_level("nitro")==1 and game.upgrade_level("weapon")==0)
	await photo("ausbau-ohne-waffe")
	await click_hud("start");await wait_frames(8)
	drive=get_tree().current_scene
	var frames:=0
	while not drive._finished and frames<10000:
		var w=drive.wagon;var c=drive.course
		key(KEY_W,true)
		var error:float=wrapf(w.rotation-c.slope_at(w.position.x),-PI,PI)
		var unsteady:bool=w.airborne or w.front_spring.is_colliding()!=w.rear_spring.is_colliding() or absf(error)>.35
		key(KEY_D,unsteady and error<-.10);key(KEY_A,unsteady and error>.10)
		var meter:float=w.position.x/36
		key(KEY_SPACE,meter>c.LOCK_START_M-75 and meter<c.LOCK_REJOIN_M)
		await get_tree().physics_frame;frames+=1
		if frames%300==0:print("EARNED_DRIVE_PROGRESS m=",drive.distance_m," health=",w.durability," fuel=",w.fuel)
	for code in [KEY_W,KEY_A,KEY_D,KEY_SPACE]:key(code,false)
	await photo("ohne-waffe-ergebnis")
	print("EARNED_DRIVE_RESULT distance=",drive.distance_m," time=",drive.elapsed_s," income=",drive._arrival_income," balance=",drive._arrival_balance," levels=",drive.workshop_upgrades)
	var expected:Dictionary={"money":drive._arrival_balance,"levels":drive.workshop_upgrades,"distance":drive.distance_m}
	var file:=FileAccess.open("res://.local_probe/earned-drive-expected.json",FileAccess.WRITE);file.store_string(JSON.stringify(expected));file.close()
	assert(drive._finished)
	get_tree().quit()
