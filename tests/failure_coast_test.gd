extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.first_drive_tutorial_completed = true
	game.start_run()
	game.wagon.fuel = 0.0
	game.wagon.linear_velocity = Vector2(1000.0, 0.0)
	game._physics_process(0.1)
	assert(String(game.screen_state) == "RUN", "An empty tank must not open results while the Kombi is still rolling.")
	assert(float(game.wagon.linear_velocity.x) < 1000.0 and float(game.wagon.linear_velocity.x) > 0.0, "An empty Kombi should coast down gradually without engine power.")
	assert(float(game.failure_coast_elapsed_s) > 0.0, "The fuel failure should enter the coast phase.")
	for _frame_index in range(120):
		if String(game.screen_state) != "RUN":
			break
		game._physics_process(0.1)
	assert(String(game.screen_state) == "RESULT", "After coasting to a stop, the empty-tank run should finish normally.")
	game._begin_run(false)
	game.wagon.durability = 0.0
	game.wagon.fuel = game.wagon.fuel_capacity
	game.wagon.linear_velocity = Vector2(1000.0, 0.0)
	game._physics_process(0.1)
	assert(String(game.screen_state) == "RUN", "A destroyed vehicle must also coast before results appear.")
	assert(float(game.wagon.linear_velocity.x) < 1000.0 and float(game.wagon.linear_velocity.x) > 0.0, "A destroyed Kombi should lose speed over time, not stop abruptly.")
	for _frame_index in range(120):
		if String(game.screen_state) != "RUN":
			break
		game._physics_process(0.1)
	assert(String(game.screen_state) == "RESULT", "After the wrecked car slows down, the run should finish normally.")
	print("FAILURE_COAST_OK empty_tank_coasts=true wrecked_car_coasts=true results_wait_for_stop=true")
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
