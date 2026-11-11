extends "res://tools/amsterdam_player_loop_probe.gd"
func _run()->void:
	var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://.local_probe/earned-drive-expected.json"))
	game=load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game);get_tree().current_scene=game
	await wait_frames(12)
	assert(game.money==int(expected.money))
	for part in expected.levels:assert(game.upgrade_level(part)==int(expected.levels[part]),"Fresh process must retain "+part)
	assert(not game.tuning_trial_mode and not game.stock_test_mode)
	await click_hud("garage")
	await photo("neustart-kaeufe-erhalten")
	print("EARNED_PROFILE_FRESH_PROCESS_OK money=",game.money," levels=",game.upgrades)
	get_tree().quit()
