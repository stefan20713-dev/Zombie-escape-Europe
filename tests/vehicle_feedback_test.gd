extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	call_deferred("_run_vehicle_feedback_smoke")

func _run_vehicle_feedback_smoke() -> void:
	var game: Node2D = MAIN_SCENE.instantiate() as Node2D
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	game.complete_first_drive_tutorial()
	game.start_run()
	assert(game.screen_state == "RUN", "The vehicle feedback smoke test should exercise the production driving state.")
	var wagon: EscapeWagon = game.wagon as EscapeWagon
	wagon.airborne = false
	wagon.fuel = 40.0
	wagon.linear_velocity = Vector2(220.0, 0.0)
	wagon._update_vehicle_feedback(0.1, true)
	assert(float(wagon.get("_throttle_visual")) > 0.4, "Accelerating should drive visible exhaust feedback smoothly toward full throttle.")
	assert(float(wagon.get("_dust_visual_strength")) > 0.3, "Grounded throttle should emit tire grit while the wagon is moving.")
	var initial_durability: float = wagon.durability
	wagon.hit_zombie(4.0)
	var zombie_feedback: float = float(wagon.get("_impact_visual_strength"))
	assert(zombie_feedback >= 0.4 and float(wagon.get("_impact_visual_remaining")) > 0.0, "A zombie collision should trigger a short visible impact burst.")
	assert(wagon.durability < initial_durability, "Impact feedback must remain connected to the existing damage response.")
	wagon.hit_obstacle()
	var obstacle_feedback: float = float(wagon.get("_impact_visual_strength"))
	assert(obstacle_feedback > zombie_feedback, "A heavier obstacle should produce a stronger spark burst.")
	var durability_after_obstacle: float = wagon.durability
	wagon.airborne = true
	wagon.hit_road_hazard(0.6, 12.0)
	assert(is_equal_approx(wagon.durability, durability_after_obstacle), "Airborne hazard contact should not apply ground-impact damage.")
	assert(is_equal_approx(float(wagon.get("_impact_visual_strength")), obstacle_feedback), "Ignored airborne contact should not create false impact feedback.")
	wagon._update_vehicle_feedback(0.5, false)
	assert(float(wagon.get("_impact_visual_remaining")) == 0.0 and float(wagon.get("_impact_visual_strength")) == 0.0, "Impact sparks must clear after their visual lifetime.")
	assert(float(wagon.get("_throttle_visual")) == 0.0, "Exhaust intensity should settle after the driver releases gas.")
	wagon._reset_vehicle_feedback()
	assert(float(wagon.get("_dust_visual_strength")) == 0.0, "Run reset should clear tire particles before the next drive.")
	print("VEHICLE_FEEDBACK_OK exhaust=true tire_grit=true impact_scaling=true airborne_guard=true decay=true reset=true")
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()
