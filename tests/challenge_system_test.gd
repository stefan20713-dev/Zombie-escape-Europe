extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const CHALLENGE_DATA = preload("res://scripts/challenge_data.gd")

func _ready() -> void:
	_write_schema_three_save()
	await get_tree().process_frame
	var game: Node = MAIN_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	assert(CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() == 1, "Amsterdam must be the only active campaign route.")
	assert(CHALLENGE_DATA.WORLD_CHALLENGES.size() == 1, "Amsterdam must keep its bonus objective.")
	assert(game.money == 777 and game.selected_world_index == 0, "Schema 3 save data should be retained during migration.")
	assert(game.world_challenge_completed.size() == 1 and game.completed_challenge_count() == 0, "Old campaign saves should migrate to one route with no fabricated medals.")
	assert(game.first_drive_tutorial_completed, "An existing profile should not be forced into the new-player tutorial.")
	var saved_config := ConfigFile.new()
	assert(saved_config.load("user://progress.cfg") == OK, "Migrated profile should be written.")
	assert(int(saved_config.get_value("campaign", "schema", 0)) == 12, "Amsterdam scope and campaign reset should advance the save schema.")
	var challenge_ids: Array[String] = []
	var supported_kinds: Array[String] = ["coins", "zombies", "condition", "speed", "fuel", "repairs", "clean_hazard"]
	for world_index in range(CHALLENGE_DATA.WORLD_CHALLENGES.size()):
		var challenge: Dictionary = game.challenge_data(world_index)
		var challenge_id: String = String(challenge.get("id", ""))
		var kind: String = String(challenge.get("kind", ""))
		var target: float = float(challenge.get("target", 0.0))
		assert(not challenge_id.is_empty() and not challenge_ids.has(challenge_id), "World challenge IDs must be unique.")
		assert(supported_kinds.has(kind) and target > 0.0 and int(challenge.get("reward", 0)) > 0, "Every objective must have supported, useful parameters.")
		challenge_ids.append(challenge_id)
		game.run_world_index = world_index
		game.run_is_final_rescue = false
		_set_matching_progress(game, kind, target)
		assert(game._challenge_requirements_met(), "The matching progress should complete world objective %d." % (world_index + 1))
		_set_matching_progress(game, kind, maxf(0.0, target - 1.0))
		assert(not game._challenge_requirements_met(), "One unit below target should fail objective %d." % (world_index + 1))
	game.wagon.airborne = false
	game.wagon.linear_velocity = Vector2(64.0, 0.0)
	game.wagon.launch_from_ramp()
	assert(game.wagon.airborne and game.wagon.linear_velocity.y < 0.0, "Crossing a launch marker should apply an upward physical takeoff velocity.")
	game.wagon.reset_at(game.terrain.route_meter_to_world_x(0.0), game.terrain)
	game.run_collectible_reward = 0
	game.run_zombie_contacts = 0
	game.run_repair_pickups = 0
	game.terrain.entities.clear()
	game.terrain.entities.append({"meter": 1.0, "kind": "coins", "reward": 30, "done": false})
	game._resolve_entities(0.0, 2.0)
	assert(game.run_collectible_reward == 30, "Picking up a grounded coin cache should advance the coin objective.")
	game.terrain.entities.clear()
	game.wagon.airborne = false
	game.terrain.entities.append({"meter": 1.0, "kind": "zombie", "group_size": 3, "damage": 0.0, "reward": 15, "done": false})
	game._resolve_entities(0.0, 2.0)
	assert(game.run_zombie_contacts == 3, "Breaking through a group should advance the zombie-contact objective by group size.")
	game.terrain.entities.clear()
	game.wagon.durability = 40.0
	game.terrain.entities.append({"meter": 1.0, "kind": "repair", "amount": 30.0, "done": false})
	game._resolve_entities(0.0, 2.0)
	assert(game.run_repair_pickups == 1 and game.wagon.durability == 70.0, "Collecting a repair kit should advance its objective and restore condition.")
	game.run_hazard_passed = false
	game.run_hazard_hits = 0
	game._resolve_setpiece_hazard({"hazard_label": "TESTSPERRE", "speed_retention": 0.8, "damage": 2.0})
	assert(game.run_hazard_passed and game.run_hazard_hits == 1, "Driving into a setpiece should fail clean-passage objectives.")
	game.run_hazard_passed = false
	game.run_hazard_hits = 0
	game.wagon.airborne = true
	game._resolve_setpiece_hazard({"hazard_label": "TESTSPERRE", "speed_retention": 0.8, "damage": 2.0})
	assert(game.run_hazard_passed and game.run_hazard_hits == 0, "Jumping a setpiece should satisfy clean-passage progress without damage.")
	game.wagon.airborne = false
	game.selected_world_index = 0
	game.to_garage()
	game.start_run()
	game.wagon.linear_velocity = Vector2(120.0, 0.0)
	game._physics_process(0.016)
	assert(game.run_peak_speed_kmh > 50.0, "The live physics loop should record peak speed up to the configured vehicle limit.")
	game.to_garage()
	game.selected_world_index = 0
	game.run_world_index = 0
	game.unlocked_world_index = 0
	game.world_completed_flags[0] = false
	game.world_challenge_completed[0] = false
	game.to_garage()
	game.start_run()
	game.run_collectible_reward = 60
	var first_run_balance: int = game.money
	game._finish_run(true)
	assert(game.screen_state == "LEVEL_COMPLETE" and game.run_challenge_success, "A completed stage meeting its goal should award the challenge.")
	assert(game.run_challenge_reward == int(CHALLENGE_DATA.WORLD_CHALLENGES[0]["reward"]), "The first medal should award its authored bonus.")
	assert(game.money == first_run_balance + 60 + game.run_challenge_reward, "Challenge bonus should be added once on top of normal run earnings.")
	assert(game.world_challenge_completed[0], "The medal should be stored in campaign state.")
	await get_tree().process_frame
	await get_tree().process_frame
	var game_hud: Control = game.get_node("HUDLayer/HUD") as Control
	assert(_has_button(game_hud.buttons, "garage"), "The completed-world results screen should still offer its garage action.")
	game.open_world_map()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(_has_button(game_hud.buttons, "map_back") and _has_button(game_hud.buttons, "world_select:1"), "The campaign map should draw the world list after stage completion.")
	game.queue_free()
	await get_tree().process_frame
	var restored: Node = MAIN_SCENE.instantiate()
	add_child(restored)
	await get_tree().process_frame
	assert(restored.world_challenge_completed[0] and restored.completed_challenge_count() == 1, "The medal should persist after reload.")
	assert(restored.money == first_run_balance + 60 + int(CHALLENGE_DATA.WORLD_CHALLENGES[0]["reward"]), "The challenge bonus should persist with the wallet.")
	restored.selected_world_index = 0
	restored._configure_selected_world()
	restored.to_garage()
	restored.start_run()
	restored.run_collectible_reward = 60
	restored._finish_run(true)
	assert(restored.run_challenge_success and restored.run_challenge_reward == 0, "Replaying a completed objective must not grant its one-time bonus twice.")
	restored.to_garage()
	restored.queue_free()
	await get_tree().process_frame
	print("CHALLENGE_SYSTEM_OK worlds=1 unique_goals=true progress=true one_time_rewards=true schema3_migration=true tutorial_existing_profile=true save_reload=true hud_results_map=true")
	get_tree().quit(0)

func _set_matching_progress(game: Node, kind: String, value: float) -> void:
	game.run_collectible_reward = 0
	game.run_zombie_contacts = 0
	game.run_repair_pickups = 0
	game.run_hazard_passed = false
	game.run_hazard_hits = 0
	game.run_peak_speed_kmh = 0.0
	game.wagon.durability = 100.0
	game.wagon.fuel = value
	match kind:
		"coins":
			game.run_collectible_reward = int(value)
		"zombies":
			game.run_zombie_contacts = int(value)
		"condition":
			game.wagon.durability = value
		"speed":
			game.run_peak_speed_kmh = value
		"fuel":
			game.wagon.fuel = value
		"repairs":
			game.run_repair_pickups = int(value)
		"clean_hazard":
			game.run_hazard_passed = value > 0.0
			game.run_hazard_hits = 0 if value > 0.0 else 1

func _has_button(buttons: Array[Dictionary], button_id: String) -> bool:
	for button in buttons:
		if String(button.get("id", "")) == button_id:
			return true
	return false

func _write_schema_three_save() -> void:
	var completed_worlds := PackedByteArray()
	for _world_index in range(30):
		completed_worlds.append(0)
	var config := ConfigFile.new()
	config.set_value("progress", "meters", 0.0)
	config.set_value("progress", "money", 777)
	config.set_value("campaign", "schema", 3)
	config.set_value("campaign", "selected_world", 0)
	config.set_value("campaign", "unlocked_world", 0)
	config.set_value("campaign", "best_distances", [])
	config.set_value("campaign", "completed_worlds", completed_worlds)
	config.set_value("campaign", "final_rescue_unlocked", false)
	config.set_value("campaign", "final_rescue_completed", false)
	config.save("user://progress.cfg")

