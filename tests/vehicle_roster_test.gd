extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	Engine.max_fps = 0
	Engine.physics_ticks_per_second = 240
	var game: Variant = MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	assert(CAMPAIGN_DATA.VEHICLE_ORDER == ["kombi", "lieferwagen", "offroad_pickup"], "The campaign should register all three vehicles in selection order.")
	assert(game.selected_vehicle == "kombi" and game.unlocked_vehicles.size() == 1 and game.is_vehicle_unlocked("kombi"), "A fresh campaign must start with only the Kombi unlocked.")
	assert(not game.is_vehicle_unlocked("lieferwagen") and not game.is_vehicle_unlocked("offroad_pickup"), "Later vehicles must remain locked on a fresh campaign.")
	assert(game.next_vehicle_unlock_hint() == "LIEFERWAGEN AUF EINER SPÄTEREN STRECKE", "The first locked vehicle should explain that its route is not active yet.")
	var selector_at_start: bool = await _garage_has_vehicle_selector(game)
	assert(not selector_at_start, "The garage must not show a selector before another vehicle is unlocked.")
	assert(not game.select_next_vehicle(), "A locked vehicle must not be selectable.")

	game.first_drive_tutorial_completed = true
	game.money = 2000
	game.vehicle_upgrades = _empty_vehicle_upgrades()
	game.upgrades = _empty_upgrades()
	game.unlocked_vehicles.clear()
	game.unlocked_vehicles.append("kombi")
	game.selected_vehicle = "kombi"
	game.wagon.configure(game.upgrades, game.selected_vehicle)
	game.unlocked_vehicle_names_this_run.clear()
	game.vehicle_unlocked_this_run = false
	game._unlock_vehicles_for_world(2, false)
	assert(game.is_vehicle_unlocked("lieferwagen") and not game.is_vehicle_unlocked("offroad_pickup"), "The three-route progression should unlock only the delivery van at its configured milestone.")
	game.to_garage()
	var selector_after_van: bool = await _garage_has_vehicle_selector(game)
	assert(selector_after_van, "The garage must show the vehicle selector after its first unlock.")
	assert(game.select_next_vehicle() and game.selected_vehicle == "lieferwagen", "The first unlocked vehicle must be selectable from the garage.")
	assert(is_equal_approx(game.wagon.mass, 520.0) and is_equal_approx(game.wagon.fuel_capacity, 88.0), "The delivery van must use its own mass and fuel profile.")
	assert(game.buy_upgrade("tank") and game.upgrade_level("tank") == 1 and is_equal_approx(game.wagon.fuel_capacity, 114.0), "The delivery van must accept and apply its independent tank upgrade.")
	game.money = 2000
	assert(game.buy_upgrade("suspension") and game.buy_upgrade("efficiency") and game.buy_upgrade("brakes"), "The delivery van must be able to purchase every newly added chassis upgrade.")
	assert(game.wagon.suspension_level == 1 and game.wagon.efficiency_level == 1 and game.wagon.brake_level == 1, "New upgrades must immediately configure the selected vehicle.")
	assert(game.select_next_vehicle() and game.selected_vehicle == "kombi", "The vehicle selector must cycle back to the Kombi.")
	assert(game.upgrade_level("tank") == 0 and game.buy_upgrade("engine") and game.upgrade_level("engine") == 1, "The Kombi upgrade row must remain independent from the delivery van.")
	assert(game.select_next_vehicle() and game.selected_vehicle == "lieferwagen" and game.upgrade_level("tank") == 1 and game.upgrade_level("engine") == 0, "Switching back must restore the delivery van upgrades.")
	assert(game.upgrade_level("suspension") == 1 and game.upgrade_level("efficiency") == 1 and game.upgrade_level("brakes") == 1, "The new van chassis upgrades must stay independent from the Kombi.")
	assert(game.next_vehicle_unlock_hint() == "GELÄNDE-PICKUP AUF EINER SPÄTEREN STRECKE", "The garage should explain that the third vehicle's route will be authored later.")

	game.to_garage()
	game.unlocked_vehicle_names_this_run.clear()
	game.vehicle_unlocked_this_run = false
	game._unlock_vehicles_for_world(14, false)
	assert(game.is_vehicle_unlocked("offroad_pickup"), "The configured later vehicle milestone should unlock the off-road pickup.")
	assert(game.unlocked_vehicle_names_this_run.has("GELÄNDE-PICKUP"), "The result screen should know which vehicle was unlocked.")
	assert(game.vehicle_unlock_message() == "GELÄNDE-PICKUP FREIGESCHALTET", "The unlock message should name the unlocked vehicle.")
	game.to_garage()
	assert(game.next_vehicle_name().to_upper() == "GELÄNDE-PICKUP", "The selector should point from the van to the newly unlocked pickup.")
	assert(game.select_next_vehicle() and game.selected_vehicle == "offroad_pickup", "The pickup must be selectable after its campaign unlock.")
	assert(game.current_vehicle_name() == "Gelände-Pickup", "Vehicle display names should preserve the model's hyphenated German name.")
	assert(is_equal_approx(game.wagon.mass, 465.0) and is_equal_approx(game.wagon.fuel_capacity, 80.0), "The pickup must load its own mass and tank values.")
	assert(is_equal_approx(game.wagon.wheel_radius, 19.5) and is_equal_approx(game.wagon.rear_spring.position.x, -51.0), "The pickup must use its larger wheels and axle position.")
	assert(is_equal_approx(game.wagon.front_spring.position.x, 51.0), "The pickup front suspension must align with its wheel arch.")
	assert(is_equal_approx(game.wagon.chassis_shape.shape.size.x, 184.0), "The pickup chassis collision must cover its wider body.")
	assert(game.buy_upgrade("tank") and game.upgrade_level("tank") == 1 and is_equal_approx(game.wagon.fuel_capacity, 104.0), "The pickup must receive an independent tank upgrade.")
	game.start_run()
	assert(game.screen_state == "RUN" and game.wagon.vehicle_id == "offroad_pickup", "The selected pickup must enter the actual running scene.")
	assert(is_equal_approx(game.wagon._engine_force, 58000.0), "The pickup must load its own engine force in the running scene.")
	assert(is_equal_approx(game.wagon._suspension_strength, 11200.0) and is_equal_approx(game.wagon._suspension_damping, 1780.0), "The pickup must load its own suspension strength and damping in the running scene.")
	assert(is_equal_approx(game.wagon._max_speed_pixels_s, 16.0 * game.wagon.PIXELS_PER_METER), "The pickup must load its own base speed in the running scene.")
	print("PICKUP_CONFIGURATION_OK engine=%.0f suspension=%.0f damping=%.0f max_speed_px_s=%.0f" % [game.wagon._engine_force, game.wagon._suspension_strength, game.wagon._suspension_damping, game.wagon._max_speed_pixels_s])
	game._finish_run(false)
	game.to_garage()
	assert(game.select_next_vehicle() and game.selected_vehicle == "kombi", "A three-vehicle roster must cycle from pickup to Kombi.")
	assert(is_equal_approx(game.wagon.chassis_shape.shape.size.x, 184.0), "Switching back must restore the longer Kombi chassis collision width.")
	assert(game.select_next_vehicle() and game.selected_vehicle == "lieferwagen", "A three-vehicle roster must cycle from Kombi to van.")
	assert(game.select_next_vehicle() and game.selected_vehicle == "offroad_pickup" and game.upgrade_level("tank") == 1, "A three-vehicle roster must cycle back to pickup with its upgrade intact.")
	game._save_progress()
	game.queue_free()
	await process_frame

	var saved_game: Variant = MAIN_SCENE.instantiate()
	root.add_child(saved_game)
	await process_frame
	assert(saved_game.selected_vehicle == "offroad_pickup" and saved_game.is_vehicle_unlocked("offroad_pickup"), "The selected and unlocked pickup must survive saving and reload.")
	assert(saved_game.upgrade_level("tank") == 1 and is_equal_approx(saved_game.wagon.fuel_capacity, 104.0), "The pickup's vehicle-specific upgrade must survive reload.")
	var saved_van_levels: Dictionary = saved_game.vehicle_upgrades["lieferwagen"]
	assert(int(saved_van_levels.get("suspension", -1)) == 1 and int(saved_van_levels.get("efficiency", -1)) == 1 and int(saved_van_levels.get("brakes", -1)) == 1, "All new per-vehicle upgrade levels must survive reload.")
	saved_game.queue_free()
	await process_frame

	_write_schema_five_save()
	var migrated_game: Variant = MAIN_SCENE.instantiate()
	root.add_child(migrated_game)
	await process_frame
	assert(migrated_game.money == 777 and migrated_game.selected_world_index == 0 and migrated_game.unlocked_world_index == 0, "Schema 5 currency should remain while the campaign restarts in Amsterdam.")
	assert(migrated_game.is_vehicle_unlocked("offroad_pickup"), "A schema 5 save past Alicante must gain the newly available pickup.")
	assert(migrated_game.selected_vehicle == "lieferwagen", "Migration must preserve the player's previously selected vehicle.")
	assert(migrated_game.upgrade_level("engine") == 2 and migrated_game.upgrade_level("tank") == 1, "Existing delivery van upgrades must survive migration.")
	var migrated_config := ConfigFile.new()
	assert(migrated_config.load("user://progress.cfg") == OK, "The migrated profile should be written.")
	assert(int(migrated_config.get_value("campaign", "schema", 0)) == 12, "The vehicle and upgrade migration must advance the save schema to 12.")
	assert(migrated_game.upgrade_level("suspension") == 0 and migrated_game.upgrade_level("efficiency") == 0 and migrated_game.upgrade_level("brakes") == 0, "Pre-existing saves must receive safe default levels for the new upgrades.")

	print("VEHICLE_ROSTER_OK fresh_kombi=true future_vehicle_milestones=true distinct_collision=true physics_drive=true cycle=true separate_upgrades=true chassis_upgrades=true save_reload=true schema5_migration=true")
	quit(0)

func _garage_has_vehicle_selector(game: Variant) -> bool:
	var hud: Variant = game.get_node("HUDLayer/HUD")
	hud.queue_redraw()
	for _frame in range(2):
		await process_frame
	for button in hud.buttons:
		if String(button.get("id", "")) == "vehicle_next":
			return true
	return false

func _empty_upgrades() -> Dictionary:
	return {"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0}

func _empty_vehicle_upgrades() -> Dictionary:
	var result: Dictionary = {}
	for vehicle_id in CAMPAIGN_DATA.VEHICLE_ORDER:
		result[vehicle_id] = _empty_upgrades()
	return result

func _write_schema_five_save() -> void:
	var completed_worlds := PackedByteArray()
	var completed_challenges := PackedByteArray()
	var best_distances: Array[float] = []
	for _world_index in range(30):
		completed_worlds.append(0)
		completed_challenges.append(0)
		best_distances.append(0.0)
	var config := ConfigFile.new()
	config.set_value("progress", "meters", 0.0)
	config.set_value("progress", "money", 777)
	config.set_value("campaign", "schema", 5)
	config.set_value("campaign", "selected_world", 14)
	config.set_value("campaign", "unlocked_world", 15)
	config.set_value("campaign", "best_distances", best_distances)
	config.set_value("campaign", "completed_worlds", completed_worlds)
	config.set_value("campaign", "completed_challenges", completed_challenges)
	config.set_value("campaign", "final_rescue_unlocked", false)
	config.set_value("campaign", "final_rescue_completed", false)
	config.set_value("campaign", "final_rescue_challenge_completed", false)
	config.set_value("tutorial", "first_drive_completed", true)
	config.set_value("vehicles", "selected", "lieferwagen")
	config.set_value("vehicles", "unlocked", PackedStringArray(["kombi", "lieferwagen"]))
	config.set_value("vehicles", "upgrades", {
		"kombi": _empty_upgrades(),
		"lieferwagen": {"engine": 2, "tires": 1, "tank": 1, "armor": 0}
	})
	assert(config.save("user://progress.cfg") == OK, "The schema 5 migration fixture should be saved.")
