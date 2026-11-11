extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	call_deferred("_run_tutorial_smoke")

func _run_tutorial_smoke() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	add_child(game)
	await _wait_for_ui()
	var hud: Control = game.get_node("HUDLayer/HUD") as Control
	assert(not game.first_drive_tutorial_completed and game.is_first_drive_tutorial_active(), "A brand-new profile should open the first-drive tutorial in the garage.")
	assert(_has_button(hud, "tutorial:next") and _has_button(hud, "tutorial:skip") and _has_button(hud, "start"), "The tutorial must show navigation while preserving the start control behind its modal shield.")
	game.start_run()
	assert(game.screen_state == "GARAGE", "A new profile must not bypass the tutorial through the run API.")
	_click_button(hud, "start")
	assert(game.screen_state == "GARAGE" and not game.first_drive_tutorial_completed, "The tutorial modal must intercept taps aimed at the covered garage start button.")
	_click_button(hud, "tutorial:skip")
	assert(game.screen_state == "GARAGE" and game.first_drive_tutorial_completed, "Skipping should close the tutorial and leave the player ready in the garage.")
	var saved := ConfigFile.new()
	assert(saved.load("user://progress.cfg") == OK, "Skipping the tutorial must save the profile.")
	assert(int(saved.get_value("campaign", "schema", 0)) == 12 and bool(saved.get_value("tutorial", "first_drive_completed", false)), "The tutorial-complete state should be saved with schema 12.")
	game.queue_free()
	await get_tree().process_frame
	var restored: Node = MAIN_SCENE.instantiate()
	add_child(restored)
	await _wait_for_ui()
	var restored_hud: Control = restored.get_node("HUDLayer/HUD") as Control
	assert(restored.first_drive_tutorial_completed and not _has_button(restored_hud, "tutorial:next"), "A completed tutorial must stay closed after the game reloads.")
	# Exercise the final lesson action as well as the optional skip path.
	restored.first_drive_tutorial_completed = false
	restored_hud.set("_first_drive_tutorial_page", 0)
	restored_hud.queue_redraw()
	await _wait_for_ui()
	for _page in range(3):
		_click_button(restored_hud, "tutorial:next")
		await _wait_for_ui()
	assert(int(restored_hud.get("_first_drive_tutorial_page")) == 3 and _has_button(restored_hud, "tutorial:start"), "The final tutorial page should offer a direct first-drive action.")
	_click_button(restored_hud, "tutorial:start")
	assert(restored.screen_state == "RUN" and restored.first_drive_tutorial_completed, "Finishing the lessons should persist completion and start the first drive.")
	restored.queue_free()
	await get_tree().process_frame
	_write_schema_four_save()
	var legacy: Node = MAIN_SCENE.instantiate()
	add_child(legacy)
	await _wait_for_ui()
	assert(legacy.first_drive_tutorial_completed, "Existing schema 4 profiles should not be forced through a new tutorial.")
	assert(legacy.money == 321 and legacy.selected_world_index == 0 and legacy.unlocked_world_index == 0, "Schema 4 currency should remain while the campaign restarts in Amsterdam.")
	var migrated := ConfigFile.new()
	assert(migrated.load("user://progress.cfg") == OK, "The legacy profile should be rewritten after migration.")
	assert(int(migrated.get_value("campaign", "schema", 0)) == 12 and bool(migrated.get_value("tutorial", "first_drive_completed", false)), "Schema 4 migration should persist tutorial completion in schema 12.")
	legacy.queue_free()
	await get_tree().process_frame
	print("FIRST_DRIVE_TUTORIAL_OK fresh_profile=true modal_input_guard=true skip_save=true reload=true start_from_final_page=true schema4_migration=true progress_retained=true")
	get_tree().quit(0)

func _wait_for_ui() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

func _has_button(hud: Control, button_id: String) -> bool:
	for item in hud.buttons:
		if String(item.get("id", "")) == button_id:
			return true
	return false

func _click_button(hud: Control, button_id: String) -> void:
	for item in hud.buttons:
		if String(item.get("id", "")) != button_id:
			continue
		var rect: Rect2 = item["rect"]
		hud.call("_press_at", rect.get_center(), -1)
		return
	assert(false, "Tutorial smoke test could not find button %s." % button_id)

func _write_schema_four_save() -> void:
	var completed_worlds := PackedByteArray()
	for _world_index in range(30):
		completed_worlds.append(0)
	var config := ConfigFile.new()
	config.set_value("progress", "meters", 123.0)
	config.set_value("progress", "money", 321)
	config.set_value("campaign", "schema", 4)
	config.set_value("campaign", "selected_world", 2)
	config.set_value("campaign", "unlocked_world", 3)
	config.set_value("campaign", "best_distances", [])
	config.set_value("campaign", "completed_worlds", completed_worlds)
	config.set_value("campaign", "final_rescue_unlocked", false)
	config.set_value("campaign", "final_rescue_completed", false)
	config.set_value("campaign", "final_rescue_challenge_completed", false)
	config.save("user://progress.cfg")

