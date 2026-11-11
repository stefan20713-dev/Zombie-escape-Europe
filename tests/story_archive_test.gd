extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const STORY_DATA = preload("res://scripts/story_data.gd")
const GAME_SCRIPT = preload("res://scripts/game.gd")

func _ready() -> void:
	call_deferred("_run_story_archive_smoke")

func _run_story_archive_smoke() -> void:
	_write_schema_seven_save()
	var game: Node2D = MAIN_SCENE.instantiate() as Node2D
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(CAMPAIGN_DATA.PLAYABLE_WORLD_COUNT == 1 and CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() == 1, "Only Amsterdam should remain in the active campaign.")
	assert(String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[0].get("id", "")) == "amsterdam", "The active route should be Amsterdam.")
	assert(STORY_DATA.LOGS.size() == 1 and game.story_log_count() == 1, "The archive should contain only the authored Amsterdam entry.")
	var entry: Dictionary = STORY_DATA.get_log(0)
	assert(not String(entry.get("title", "")).is_empty() and not String(entry.get("text", "")).is_empty(), "The Amsterdam entry needs readable text.")
	assert(int(GAME_SCRIPT.CAMPAIGN_SAVE_SCHEMA) == 12, "The old profile should migrate to the current campaign save schema.")
	var migrated_save := ConfigFile.new()
	assert(migrated_save.load("user://progress.cfg") == OK, "The migrated campaign save should exist.")
	assert(int(migrated_save.get_value("campaign", "schema", 0)) == int(GAME_SCRIPT.CAMPAIGN_SAVE_SCHEMA), "The current save schema should persist.")
	assert(int(migrated_save.get_value("progress", "money", 0)) == 100, "Campaign cleanup must preserve player currency.")

	var hud: Control = game.get_node("HUDLayer/HUD") as Control
	hud.size = Vector2(1280.0, 720.0)
	hud.queue_redraw()
	await get_tree().process_frame
	assert(_has_button(hud.buttons, "archive_open"), "The garage should expose the archive entry point.")
	game.open_radio_archive()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(game.screen_state == "ARCHIVE" and game.archive_return_state == "GARAGE", "The archive should open from the garage and remember its return screen.")
	assert(_has_button(hud.buttons, "archive_back"), "The archive should expose a return button.")
	var selectable_count: int = 0
	for button in hud.buttons:
		if String(button.get("id", "")).begins_with("story_select:"):
			selectable_count += 1
	assert(selectable_count == 1, "Only the Amsterdam story entry should be selectable.")
	hud._handle_button("story_select:0")
	assert(int(game.archive_selected_log_index) == 0 and not game.is_story_log_collected(0), "A locked entry should stay unread until found on the road.")
	hud._handle_button("archive_back")
	assert(game.screen_state == "GARAGE", "The archive should return to the garage.")

	game.open_world_map()
	hud.queue_redraw()
	await get_tree().process_frame
	assert(_has_button(hud.buttons, "archive_open"), "The Amsterdam map should expose the archive too.")
	game.open_radio_archive()
	assert(game.archive_return_state == "MAP", "Opening the archive from the map should preserve the map as its return screen.")
	game.close_radio_archive()
	assert(game.screen_state == "MAP", "Closing the map archive should return to the map.")
	game.to_garage()

	game.start_run()
	assert(game.screen_state == "RUN" and not game.run_is_final_rescue, "A drive should start on the standard Amsterdam route.")
	var story_entity: Dictionary = {}
	for entity in game.terrain.entities:
		if String(entity.get("kind", "")) == "story_log":
			story_entity = entity
	assert(not story_entity.is_empty() and not bool(story_entity.get("done", true)), "The uncollected Amsterdam entry should appear once on the road.")
	var story_meter: float = float(story_entity["meter"])
	game._resolve_entities(story_meter - 1.0, story_meter + 1.0, 0.0)
	assert(game.is_story_log_collected(0) and game.run_story_log_collected, "Driving through the entry should collect and record it.")
	assert(game.run_collectible_reward == 20 and String(game.toast_text).contains("+20"), "The Amsterdam entry should grant its one-time 20-coin reward.")
	var collected_save := ConfigFile.new()
	assert(collected_save.load("user://progress.cfg") == OK, "Collecting the entry should persist progress immediately.")
	var stored_logs: PackedByteArray = collected_save.get_value("campaign", "collected_story_logs", PackedByteArray())
	assert(stored_logs.size() == 1 and int(stored_logs[0]) == 1, "Only the Amsterdam entry flag should be persisted.")

	var reloaded: Node2D = MAIN_SCENE.instantiate() as Node2D
	add_child(reloaded)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(reloaded.is_story_log_collected(0), "The collected entry should survive a reload.")
	assert(reloaded.money >= 120, "The one-time reward should be retained in the player's currency.")
	reloaded.start_run()
	for entity in reloaded.terrain.entities:
		if String(entity.get("kind", "")) == "story_log":
			entity["done"] = false
	reloaded._resolve_entities(story_meter - 1.0, story_meter + 1.0, 0.0)
	assert(reloaded.run_collectible_reward == 0 and reloaded.collected_story_log_count() == 1, "A collected entry must not pay twice.")

	print("STORY_ARCHIVE_OK active_worlds=1 amsterdam_entries=1 archive_navigation=true written_entry=true one_time_reward=20 save_reload=true schema7_migration=true")
	get_tree().quit(0)

func _write_schema_seven_save() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "money", 100)
	config.set_value("campaign", "schema", 7)
	config.set_value("campaign", "selected_world", 0)
	config.set_value("campaign", "unlocked_world", 0)
	config.set_value("campaign", "best_distances", PackedFloat32Array())
	config.set_value("tutorial", "first_drive_completed", true)
	assert(config.save("user://progress.cfg") == OK, "The schema 7 profile fixture should be written to isolated QA storage.")

func _has_button(button_list: Array[Dictionary], button_id: String) -> bool:
	for button in button_list:
		if String(button.get("id", "")) == button_id:
			return true
	return false
