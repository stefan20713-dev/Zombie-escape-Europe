extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const BACK_INTERVAL_MS: int = 1100

func _ready() -> void:
	call_deferred("_run_back_navigation_smoke")

func _run_back_navigation_smoke() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var hud: Control = game.get_node("HUDLayer/HUD") as Control

	# An active run pauses first; a second Back request returns to the garage.
	game.first_drive_tutorial_completed = true
	game.start_run()
	assert(game.screen_state == "RUN" and not game.paused, "The smoke test must begin in an active run.")
	game.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(game.screen_state == "RUN" and game.paused and game.wagon.freeze, "Back during a run must pause and freeze the wagon.")
	game.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(game.screen_state == "RUN" and game.paused, "A duplicate Back notification must not skip the pause screen.")
	_wait_for_back_interval()
	game.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(game.screen_state == "GARAGE" and not game.paused and game.wagon.freeze, "Back from pause must return to the garage and freeze the wagon.")
	game.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(game.screen_state == "GARAGE", "A duplicate Back notification in the garage must not close the app.")

	# Map and end-of-run screens always return to the garage.
	for state in ["MAP", "RESULT", "LEVEL_COMPLETE", "WIN"]:
		_wait_for_back_interval()
		game.screen_state = state
		game.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
		assert(game.screen_state == "GARAGE", "Back from %s must return to the garage." % state)
	_wait_for_back_interval()
	game.final_rescue_completed = true
	game.ending_sequence_seen = false
	game.screen_state = "ENDING"
	game.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(game.screen_state == "WIN" and game.ending_sequence_seen, "Android Back should skip the finale and save its completion.")

	# System Back closes transient panels before changing the underlying screen.
	_wait_for_back_interval()
	game.screen_state = "MAP"
	hud.set("_privacy_visible", true)
	game.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(not bool(hud.get("_privacy_visible")) and game.screen_state == "MAP", "Back should dismiss the privacy panel and preserve the map.")
	_wait_for_back_interval()
	game.screen_state = "GARAGE"
	game.open_radio_archive()
	game.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(game.screen_state == "GARAGE", "Android Back should close the archive and return to the garage.")
	_wait_for_back_interval()
	game.screen_state = "GARAGE"
	game.first_drive_tutorial_completed = false
	hud.set("_first_drive_tutorial_page", 2)
	game.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(int(hud.get("_first_drive_tutorial_page")) == 1 and game.screen_state == "GARAGE", "Back should move to the previous tutorial page without leaving the garage.")

	print("ANDROID_BACK_NAVIGATION_OK run_pause=true paused_to_garage=true result_screens=true ending_skip=true privacy_dismiss=true archive_close=true tutorial_previous=true")
	get_tree().quit(0)

func _wait_for_back_interval() -> void:
	OS.delay_msec(BACK_INTERVAL_MS)
