extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	game.screen_state = "RUN"
	game.paused = false
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(not game.paused, "Losing focus on desktop must not open the pause menu during a screenshot.")
	print("PC_SCREENSHOT_FOCUS_OK pause_overlay_remains_closed=true")
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
