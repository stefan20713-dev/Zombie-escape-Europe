extends Node

const WAGON_SCENE: PackedScene = preload("res://scenes/wagon.tscn")
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var wagon: EscapeWagon = WAGON_SCENE.instantiate() as EscapeWagon
	add_child(wagon)
	await get_tree().process_frame
	var checked_profiles: int = 0
	for vehicle_id in CAMPAIGN_DATA.VEHICLE_ORDER:
		var vehicle: Dictionary = CAMPAIGN_DATA.VEHICLES[vehicle_id]
		for engine_level in range(4):
			for tire_level in range(4):
				for armor_level in range(4):
					var levels := {
						"engine": engine_level,
						"tires": tire_level,
						"tank": 0,
						"armor": armor_level
					}
					wagon.configure(levels, vehicle_id)
					var expected_engine_force: float = float(vehicle["base_engine_force"]) + float(engine_level) * float(vehicle["engine_force_per_level"])
					var expected_max_speed: float = (float(vehicle["base_speed_mps"]) + float(engine_level) * float(vehicle["speed_per_level_mps"])) * wagon.PIXELS_PER_METER
					var expected_spring_strength: float = float(vehicle.get("suspension_strength", 9500.0)) + float(tire_level) * 900.0
					var expected_spring_damping: float = float(vehicle.get("suspension_damping", 1550.0)) + float(tire_level) * 100.0
					assert(is_equal_approx(wagon._engine_force, expected_engine_force), "%s engine %d cache mismatch" % [vehicle_id, engine_level])
					assert(is_equal_approx(wagon._boost_force, float(vehicle["boost_force"])), "%s boost cache mismatch" % vehicle_id)
					assert(is_equal_approx(wagon._max_speed_pixels_s, expected_max_speed), "%s engine %d speed cache mismatch" % [vehicle_id, engine_level])
					assert(is_equal_approx(wagon._obstacle_damage, float(vehicle["obstacle_damage"])), "%s obstacle cache mismatch" % vehicle_id)
					assert(is_equal_approx(wagon._suspension_strength, expected_spring_strength), "%s tire %d spring cache mismatch" % [vehicle_id, tire_level])
					assert(is_equal_approx(wagon._suspension_damping, expected_spring_damping), "%s tire %d damping cache mismatch" % [vehicle_id, tire_level])
					assert(is_equal_approx(wagon._grounded_torque, float(vehicle.get("grounded_torque", 360000.0))), "%s grounded torque cache mismatch" % vehicle_id)
					assert(is_equal_approx(wagon._airborne_torque, float(vehicle.get("airborne_torque", 2800000.0))), "%s airborne torque cache mismatch" % vehicle_id)
					wagon.airborne = false
					wagon.linear_velocity = Vector2(100.0, 0.0)
					wagon.durability = 100.0
					var impact_speed_mps: float = absf(wagon.linear_velocity.x) / wagon.PIXELS_PER_METER
					var speed_fraction: float = clampf(impact_speed_mps / 28.0, 0.0, 1.0)
					var speed_damage_scale: float = 0.08 + speed_fraction * 0.92
					var expected_damage: float = maxf(
						0.3,
						float(vehicle["obstacle_damage"]) * 0.36 * speed_damage_scale * wagon.armor_damage_multiplier()
					)
					wagon.hit_obstacle()
					assert(is_equal_approx(wagon.durability, 100.0 - expected_damage), "%s armor %d obstacle behavior changed" % [vehicle_id, armor_level])
					wagon.durability = 100.0
					wagon.hit_zombie(10.0)
					assert(is_equal_approx(wagon.durability, 100.0 - 10.0 * wagon.armor_damage_multiplier()), "%s armor %d zombie impact should scale with armor" % [vehicle_id, armor_level])
					wagon.durability = 100.0
					wagon.hit_road_hazard(1.0, 10.0)
					assert(is_equal_approx(wagon.durability, 100.0 - 10.0 * wagon.armor_damage_multiplier()), "%s armor %d road hazard should scale with armor" % [vehicle_id, armor_level])
					checked_profiles += 1
	wagon.queue_free()
	print("VEHICLE_TUNING_CACHE_OK profiles=%d vehicles=%d armor_damage_scaling=obstacles_zombies_hazards" % [checked_profiles, CAMPAIGN_DATA.VEHICLE_ORDER.size()])
	get_tree().quit()
