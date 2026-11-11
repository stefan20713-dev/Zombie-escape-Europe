extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SAVE_PATH: String = "user://progress.cfg"
const SAVE_INTEGRITY_SECTION: String = "zz_save_integrity"
const SAVE_INTEGRITY_MARKER: String = "ZEE_SAVE_COMPLETE_V1"
const EXPECTED_UPGRADES: Dictionary = {"engine": 2, "tires": 1, "tank": 3, "armor": 0, "suspension": 1, "efficiency": 2, "brakes": 1}

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	_write_tuned_profile()
	var game: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	assert(int(game.upgrades["engine"]) == 2 and int(game.upgrades["tank"]) == 3, "The tuned profile should load before the stock test is applied.")
	var tuned_fuel_rate: float = game.wagon.fuel_consumption_rate(true, false)
	var tuned_speed_limit: float = float(game.wagon.get("_max_speed_pixels_s"))
	game.wagon.durability = 100.0
	game.wagon.linear_velocity = Vector2(10.0 * game.wagon.PIXELS_PER_METER, 0.0)
	game.wagon.hit_obstacle(true)
	var tuned_obstacle_damage: float = 100.0 - game.wagon.durability
	game._activate_stock_test_mode()
	assert(bool(game.stock_test_mode), "The first launch should enable a stock test session.")
	assert(bool(game.wagon.stock_test_mode), "The vehicle must receive the stock test balancing modifiers.")
	assert(int(game.wagon.nitro_level) == 0 and is_zero_approx(float(game.wagon.nitro)), "A stock test vehicle must not have nitro or boost available.")
	assert(float(game.wagon.get("_max_speed_pixels_s")) < tuned_speed_limit * 0.65, "The stock Kombi should be much slower than the saved, engine-tuned car.")
	var stock_fuel_rate: float = game.wagon.fuel_consumption_rate(true, false)
	assert(stock_fuel_rate > tuned_fuel_rate * 1.7, "The stock vehicle should burn fuel substantially faster than the saved tuned vehicle.")
	game.wagon.durability = 100.0
	game.wagon.hit_zombie(4.0)
	assert(game.wagon.durability <= 94.0, "A normal zombie impact should wear down the stock vehicle more than the tuned baseline.")
	game.wagon.durability = 100.0
	game.wagon.linear_velocity = Vector2(10.0 * game.wagon.PIXELS_PER_METER, 0.0)
	game.wagon.hit_obstacle(true)
	var stock_obstacle_damage: float = 100.0 - game.wagon.durability
	assert(stock_obstacle_damage > tuned_obstacle_damage * 1.6, "At the same impact speed, stock bodywork should take substantially more damage than the saved tuned car.")
	for part in game.UPGRADE_PARTS:
		assert(int(game.upgrades[part]) == 0, "The runtime test vehicle must have zero levels for %s." % part)
	assert(int(game.vehicle_upgrades["kombi"]["engine"]) == 2, "The loaded garage upgrade data should remain unchanged in memory.")
	var saved: ConfigFile = ConfigFile.new()
	assert(saved.load(SAVE_PATH) == OK, "The stock-test save should remain readable.")
	assert(bool(saved.get_value("testing", "stock_start_seen", false)), "The one-time stock start must be consumed in the save.")
	var saved_vehicles: Dictionary = saved.get_value("vehicles", "upgrades", {})
	assert(int(saved_vehicles["kombi"]["engine"]) == 2 and int(saved_vehicles["kombi"]["tank"]) == 3, "The pre-existing upgrades must survive every save during stock testing.")
	assert(int(saved.get_value("upgrades", "engine", 0)) == 2, "Legacy upgrade fields should also retain their original levels.")
	game._save_progress()
	var saved_after_session: ConfigFile = ConfigFile.new()
	assert(saved_after_session.load(SAVE_PATH) == OK, "The profile should still load after saving during the stock session.")
	var upgrades_after_session: Dictionary = saved_after_session.get_value("vehicles", "upgrades", {})
	assert(int(upgrades_after_session["kombi"]["engine"]) == 2 and int(upgrades_after_session["kombi"]["tank"]) == 3, "The higher stock-mode fuel use and damage must not overwrite saved garage tuning.")
	assert(not game.buy_upgrade("engine"), "Garage purchases should not silently alter the saved tuned profile during the stock test.")
	print("STOCK_START_MODE_OK slower_stock=true faster_fuel=true obstacle_damage_ratio=%.2f saved_tuning_preserved=true one_time_marker=true" % (stock_obstacle_damage / maxf(0.01, tuned_obstacle_damage)))
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _write_tuned_profile() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("progress", "money", 1500)
	config.set_value("campaign", "schema", 10)
	config.set_value("campaign", "selected_world", 0)
	config.set_value("campaign", "unlocked_world", 0)
	config.set_value("campaign", "best_distances", [180.0])
	config.set_value("campaign", "completed_worlds", PackedByteArray([0]))
	config.set_value("campaign", "completed_challenges", PackedByteArray([0]))
	config.set_value("vehicles", "selected", "kombi")
	config.set_value("vehicles", "unlocked", PackedStringArray(["kombi"]))
	config.set_value("vehicles", "upgrades", {"kombi": EXPECTED_UPGRADES.duplicate(true)})
	for part in EXPECTED_UPGRADES:
		config.set_value("upgrades", part, int(EXPECTED_UPGRADES[part]))
	config.set_value("testing", "stock_start_seen", false)
	config.set_value(SAVE_INTEGRITY_SECTION, "generation", 1)
	config.set_value(SAVE_INTEGRITY_SECTION, "complete", SAVE_INTEGRITY_MARKER)
	assert(config.save(SAVE_PATH) == OK, "The isolated tuned fixture should be written before startup.")
