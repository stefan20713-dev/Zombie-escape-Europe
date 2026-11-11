extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	call_deferred("_run_notification_layout_check")

func _run_notification_layout_check() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	var hud: Control = game.get_node("HUDLayer/HUD") as Control
	game.screen_state = "RUN"
	game.paused = false
	game.toast_text = "VORRATSDEPOT +20 MÜNZEN · VERSORGT"
	game.toast_time = 2.0
	assert(String(hud.call("_run_notification_content")) == game.toast_text, "A current gameplay event should appear in the compact ticker.")
	var ticker: Rect2 = hud.call("_run_notification_rect", Vector2(1280.0, 720.0))
	assert(ticker.size.x <= 380.0 and ticker.size.y == 28.0, "Run notifications must remain a slim ticker instead of a large message card.")
	assert(ticker.end.x <= 780.0, "The run ticker must not overlap the pause button at 1280x720.")
	game.toast_time = 0.0
	assert(String(hud.call("_run_notification_content")).is_empty(), "The ticker should disappear when no gameplay event is active; no radio announcement should be injected.")
	print("RUN_HUD_NOTIFICATION_OK ticker=%dx%d pause_clear=true toast_priority=true radio_announcements=removed" % [int(ticker.size.x), int(ticker.size.y)])
	get_tree().quit(0)
