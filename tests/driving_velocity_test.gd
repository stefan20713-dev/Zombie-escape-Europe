extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	game.start_run()
	var wagon: EscapeWagon = game.wagon as EscapeWagon
	wagon.configure({"engine": 0}, "kombi")
	var stock_limit_px_s: float = float(wagon.get("_max_speed_pixels_s"))
	wagon.configure({"engine": 3, "nitro": 1}, "kombi")
	var normal_limit_px_s: float = float(wagon.get("_max_speed_pixels_s"))
	assert(normal_limit_px_s >= stock_limit_px_s * 1.85, "Engine tuning should raise the real speed ceiling substantially above the stock Kombi.")
	assert(absf(normal_limit_px_s / wagon.PIXELS_PER_METER * 3.6 - 135.0) < 0.1, "A fully tuned Kombi should be limited to 135 km/h without boost.")
	wagon.nitro = wagon.nitro_capacity
	wagon.linear_velocity = Vector2(normal_limit_px_s * 1.50, 0.0)
	wagon.simulate(1.0 / 60.0, false, false, true, 0.0)
	var boosted_speed_px_s: float = wagon.linear_velocity.x
	assert(boosted_speed_px_s > normal_limit_px_s, "Boost must raise the actual velocity ceiling, not only draw faster streaks.")
	assert(boosted_speed_px_s >= (159.9 / 3.6) * wagon.PIXELS_PER_METER, "A fully tuned Kombi should reach the 160 km/h boost cap.")
	assert(boosted_speed_px_s <= (160.0 / 3.6) * wagon.PIXELS_PER_METER + 0.1, "The fully tuned Kombi must never exceed 160 km/h, including boost.")
	wagon.linear_velocity = Vector2(normal_limit_px_s * 1.50, 0.0)
	wagon.simulate(1.0 / 60.0, false, false, false, 0.0)
	assert(wagon.linear_velocity.x <= normal_limit_px_s + 0.1, "Normal driving must return to the unboosted speed cap.")
	print("DRIVING_VELOCITY_OK stock=%.1fkmh tuned=%.1fkmh boosted=%.1fkmh" % [stock_limit_px_s / wagon.PIXELS_PER_METER * 3.6, normal_limit_px_s / wagon.PIXELS_PER_METER * 3.6, boosted_speed_px_s / wagon.PIXELS_PER_METER * 3.6])
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
