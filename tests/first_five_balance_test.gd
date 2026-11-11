extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const PHYSICS_STEP_LIMIT: int = 18000
const FIRST_GROUP_COUNT: int = 1

func _ready() -> void:
	call_deferred("_run_amsterdam_balance")

func _run_amsterdam_balance() -> void:
	Engine.physics_ticks_per_second = 960
	Engine.time_scale = 16.0
	Engine.max_fps = 240
	var game: Node = MAIN_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	game.first_drive_tutorial_completed = true
	game.screen_state = "GARAGE"
	game.money = 100
	game.selected_vehicle = "kombi"
	game.upgrades = {"engine": 0, "tires": 0, "tank": 0, "armor": 0}
	game.vehicle_upgrades["kombi"] = game.upgrades.duplicate(true)
	game.final_rescue_unlocked = false
	game.final_rescue_completed = false
	game.world_completed_flags.fill(false)
	game.world_challenge_completed.fill(false)
	game.world_best_distances.fill(0.0)
	assert(game.buy_upgrade("engine"), "A fresh profile should afford the engine starter upgrade.")
	assert(game.buy_upgrade("tank"), "A fresh profile should afford the 95-coin engine/tank starter package.")
	assert(game.money == 5 and game.upgrade_level("engine") == 1 and game.upgrade_level("tank") == 1, "The recommended starter package should leave five coins and one level in both parts.")

	for world_index in range(FIRST_GROUP_COUNT):
		game.screen_state = "GARAGE"
		game.selected_world_index = world_index
		game._configure_selected_world()
		game.start_run()
		assert(game.screen_state == "RUN", "World %d should start from the freshly unlocked map." % (world_index + 1))
		var start_meter: float = game.campaign_meter
		var minimum_speed_kmh: float = 999.0
		var maximum_slope: float = 0.0
		var frames: int = 0
		while game.screen_state == "RUN" and frames < PHYSICS_STEP_LIMIT:
			var slope: float = game.terrain.slope_at(game.wagon.position.x)
			var speed: float = game.wagon.speed_mps
			if game._meter_at(game.wagon.position.x) - start_meter >= 25.0:
				minimum_speed_kmh = minf(minimum_speed_kmh, speed * 3.6)
			maximum_slope = maxf(maximum_slope, absf(slope))
			game.touch_actions["accelerate"] = true
			game.touch_actions["boost"] = slope <= -0.035 and speed < 13.5 and game.wagon.nitro > 4.0 and game.wagon.fuel > 5.0
			var pitch_error: float = wrapf(game.wagon.global_rotation, -PI, PI) + game.wagon.angular_velocity * 0.4
			game.touch_actions["tilt_left"] = game.wagon.airborne and pitch_error > 0.10
			game.touch_actions["tilt_right"] = game.wagon.airborne and pitch_error < -0.10
			await get_tree().physics_frame
			frames += 1
		game.clear_touch_actions()
		if game.screen_state == "RUN":
			game._finish_run(false)
		assert(bool(game.world_completed_flags[world_index]), "World %d (%s) should be completable with the fresh-profile starter package and checkpoint supplies." % [world_index + 1, String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[world_index]["city"])])
		assert(game.wagon.fuel >= 0.0 and game.wagon.durability >= 0.0, "Vehicle resources should remain within valid limits after World %d." % (world_index + 1))
		print("FIRST_FIVE_BALANCE world=%02d city=%s completed=true distance=%.1fm fuel=%.1f/%.1f durability=%.1f coins=%d min_speed=%.1fkmh max_slope=%.3f frames=%d" % [
			world_index + 1,
			String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[world_index]["city"]),
			game.run_distance,
			game.wagon.fuel,
			game.wagon.fuel_capacity,
			game.wagon.durability,
			game.money,
			minimum_speed_kmh,
			maximum_slope,
			frames
		])
		game.to_garage()

	assert(game.world_completed_flags.count(true) == FIRST_GROUP_COUNT and game.unlocked_world_index == 0, "Completing Amsterdam should retain its result without opening an unbuilt route.")
	print("FIRST_FIVE_BALANCE_OK worlds=1 city=Amsterdam fresh_profile=true starter_package=engine1_tank1 human_playtest_still_required=true")
	get_tree().quit(0)
