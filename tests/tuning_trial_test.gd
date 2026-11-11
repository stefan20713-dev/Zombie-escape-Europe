extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SAVE_PATH: String = "user://progress.cfg"
const SAVE_INTEGRITY_SECTION: String = "zz_save_integrity"
const SAVE_INTEGRITY_MARKER: String = "ZEE_SAVE_COMPLETE_V1"
const ZERO_UPGRADES: Dictionary = {"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	_write_tuned_profile()
	# This runner normally disables automatic experiments; restore normal startup
	# logic in this isolated process so the first-launch behavior is exercised.
	OS.set_environment("ZEE_AUTOMATED_QA", "")
	var game: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	assert(not bool(game.tuning_trial_mode) and not bool(game.stock_test_mode), "Normal startup must not replace owned tuning with an automatic trial.")
	assert(game.upgrade_level("engine")==2 and game.upgrade_level("tires")==1 and game.upgrade_level("tank")==1)
	assert(int(game.money)==1500)
	assert(int(game.vehicle_upgrades["lieferwagen"]["engine"])==2)
	var before:Dictionary=game.upgrades.duplicate(true)
	var price:int=game.upgrade_price("engine")
	assert(game.buy_upgrade("engine"))
	assert(game.money==1500-price)
	for part in before:assert(game.upgrade_level(part)==int(before[part])+(1 if part=="engine" else 0))
	assert(game.buy_upgrade("nitro"))
	assert(game.wagon.nitro_level==1 and is_equal_approx(game.wagon.nitro_capacity,120.0))
	var saved:=ConfigFile.new()
	assert(saved.load(SAVE_PATH)==OK)
	var vehicles:Dictionary=saved.get_value("vehicles","upgrades",{})
	assert(int(vehicles.kombi.engine)==3 and int(vehicles.kombi.nitro)==1)
	assert(int(vehicles.kombi.tires)==1 and int(vehicles.kombi.tank)==1)
	assert(int(vehicles.lieferwagen.engine)==2)
	print("LEGACY_STARTUP_PROTECTION_OK owned_levels_preserved=true purchases_independent=true save_retained=true")
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
	config.set_value("testing", "upgrade_trial_seen", true)
	config.set_value("testing", "upgrade_trial_active", false)
	config.set_value("testing", "upgrade_trial_revision", 1)
	config.set_value("vehicles", "unlocked", PackedStringArray(["kombi", "lieferwagen"]))
	config.set_value("vehicles", "upgrades", {
		"kombi": {"engine": 2, "tires": 1, "tank": 1, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0},
		"lieferwagen": {"engine": 2, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}
	})
	for part in ZERO_UPGRADES:
		config.set_value("upgrades", part, 0)
	config.set_value(SAVE_INTEGRITY_SECTION, "generation", 1)
	config.set_value(SAVE_INTEGRITY_SECTION, "complete", SAVE_INTEGRITY_MARKER)
	assert(config.save(SAVE_PATH) == OK, "The isolated tuned fixture must be written before game startup.")
