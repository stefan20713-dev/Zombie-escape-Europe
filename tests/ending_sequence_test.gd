extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")

func _ready() -> void:
	call_deferred("_run_ending_sequence_smoke")

func _run_ending_sequence_smoke() -> void:
	var game: Node2D = MAIN_SCENE.instantiate() as Node2D
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	game.final_rescue_unlocked = true
	game.start_final_rescue()
	assert(game.screen_state == "RUN" and game.run_is_final_rescue, "The final rescue mission should start from the garage.")
	game._finish_run(true)
	assert(game.screen_state == "ENDING" and game.final_rescue_completed, "Completing the rescue route should enter the ending sequence.")
	assert(not game.ending_sequence_seen and game.ending_sequence_phase() == 0, "A new ending should begin at phase zero and remain unacknowledged.")
	var hud: Control = game.get_node("HUDLayer/HUD") as Control
	await get_tree().process_frame
	await get_tree().process_frame
	assert(_has_button(hud.buttons, "ending_skip"), "The ending HUD should draw the visible touch continue control.")

	game._process(3.1)
	assert(game.screen_state == "ENDING" and game.ending_sequence_phase() == 1, "The survivor boarding chapter should begin after three seconds.")
	await get_tree().process_frame
	await get_tree().process_frame
	game._process(4.0)
	assert(game.screen_state == "ENDING" and game.ending_sequence_phase() == 2, "The Europe finale chapter should begin after seven seconds.")
	await get_tree().process_frame
	await get_tree().process_frame
	hud._handle_button("ending_skip")
	assert(game.screen_state == "WIN" and game.ending_sequence_seen, "The visible continue button should skip and record the ending.")
	var saved: ConfigFile = ConfigFile.new()
	assert(saved.load("user://progress.cfg") == OK, "Skipping should persist the completion save.")
	assert(int(saved.get_value("campaign", "schema", 0)) == 10, "The ending save should use campaign schema 10.")
	assert(bool(saved.get_value("campaign", "ending_sequence_seen", false)), "The save should record the watched or skipped ending.")

	var reloaded: Node2D = MAIN_SCENE.instantiate() as Node2D
	add_child(reloaded)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(reloaded.screen_state == "WIN" and reloaded.ending_sequence_seen, "A completed ending should not replay after loading the save.")
	assert(reloaded.world_data(CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() - 1).get("city", "") == "Messina", "The persisted campaign finale should be associated with Messina.")

	# A v6 save already had the rescue completion flag but knew nothing about endings.
	var legacy_save := ConfigFile.new()
	legacy_save.set_value("progress", "money", 321)
	legacy_save.set_value("campaign", "schema", 6)
	legacy_save.set_value("campaign", "selected_world", CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() - 1)
	legacy_save.set_value("campaign", "unlocked_world", CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() - 1)
	legacy_save.set_value("campaign", "final_rescue_unlocked", true)
	legacy_save.set_value("campaign", "final_rescue_completed", true)
	assert(legacy_save.save("user://progress.cfg") == OK, "The legacy campaign fixture should be written to the isolated QA profile.")
	var migrated: Node2D = MAIN_SCENE.instantiate() as Node2D
	add_child(migrated)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(migrated.screen_state == "ENDING" and not migrated.ending_sequence_seen, "A completed v6 save should receive the ending once after migration.")
	var migrated_save := ConfigFile.new()
	assert(migrated_save.load("user://progress.cfg") == OK, "The migrated save should be readable.")
	assert(int(migrated_save.get_value("campaign", "schema", 0)) == 10, "The v6 save should be migrated to schema 10.")
	assert(int(migrated_save.get_value("progress", "money", 0)) == 321, "Migration should preserve existing currency.")
	migrated._process(12.1)
	assert(migrated.screen_state == "WIN" and migrated.ending_sequence_seen, "The ending should finish automatically after twelve seconds.")

	print("ENDING_SEQUENCE_OK phases=true skip_button=true persistence=true legacy_v6=true auto_finish=true")
	get_tree().quit(0)

func _has_button(button_list: Array[Dictionary], button_id: String) -> bool:
	for button in button_list:
		if String(button.get("id", "")) == button_id:
			return true
	return false
