extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const PARTS: Array[String] = ["engine", "tank", "tires", "armor", "suspension", "efficiency", "brakes", "nitro"]

func _ready() -> void:
	call_deferred("_run_upgrade_preview_smoke")

func _run_upgrade_preview_smoke() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var checked: int = 0
	for vehicle_id in CAMPAIGN_DATA.VEHICLE_ORDER:
		game.selected_vehicle = vehicle_id
		var vehicle: Dictionary = CAMPAIGN_DATA.VEHICLES[vehicle_id]
		for part in PARTS:
			for level in range(4):
				game.upgrades = _empty_upgrades()
				game.upgrades[part] = level
				var preview: Dictionary = game.upgrade_preview(part)
				if level < 3:
					assert(bool(preview.get("available", false)), "%s %s level %d must offer its next purchase." % [vehicle_id, part, level])
					assert(int(preview.get("level", -1)) == level and int(preview.get("next_level", -1)) == level + 1, "%s %s should preview the next level." % [vehicle_id, part])
					assert(int(preview.get("price", -1)) == int(game.upgrade_price(part)), "%s %s preview price must match the garage purchase." % [vehicle_id, part])
					match part:
						"engine":
							var expected_force: float = float(vehicle["base_engine_force"]) + float(level) * float(vehicle["engine_force_per_level"])
							var expected_speed: float = (float(vehicle["base_speed_mps"]) + float(level) * float(vehicle["speed_per_level_mps"])) * 3.6
							assert(is_equal_approx(float(preview["current_value"]), expected_force), "%s engine preview current force mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["next_value"]), expected_force + float(vehicle["engine_force_per_level"])), "%s engine preview next force mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["current_speed_kmh"]), expected_speed), "%s engine preview current speed mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["next_speed_kmh"]), expected_speed + float(vehicle["speed_per_level_mps"]) * 3.6), "%s engine preview next speed mismatch." % vehicle_id)
						"tank":
							var expected_capacity: float = float(vehicle["base_fuel"]) + float(level) * float(vehicle["fuel_per_tank_level"])
							assert(is_equal_approx(float(preview["current_value"]), expected_capacity), "%s tank preview current capacity mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["next_value"]), expected_capacity + float(vehicle["fuel_per_tank_level"])), "%s tank preview next capacity mismatch." % vehicle_id)
						"tires":
							var expected_suspension: float = float(vehicle.get("suspension_strength", 9500.0)) + float(level) * 900.0
							var expected_damping: float = float(vehicle.get("suspension_damping", 1550.0)) + float(level) * 100.0
							assert(is_equal_approx(float(preview["current_value"]), expected_suspension), "%s tire preview current suspension mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["next_value"]), expected_suspension + 900.0), "%s tire preview next suspension mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["current_damping"]), expected_damping), "%s tire preview current damping mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["next_damping"]), expected_damping + 100.0), "%s tire preview next damping mismatch." % vehicle_id)
						"armor":
							var expected_damage: float = maxf(8.0, float(vehicle["obstacle_damage"]) - float(level) * 4.0)
							assert(is_equal_approx(float(preview["current_value"]), expected_damage), "%s armor preview current damage mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["next_value"]), maxf(8.0, expected_damage - 4.0)), "%s armor preview next damage mismatch." % vehicle_id)
						"suspension":
							var expected_spring: float = float(vehicle.get("suspension_strength", 9500.0)) + float(level) * 1200.0
							var expected_damping: float = float(vehicle.get("suspension_damping", 1550.0)) + float(level) * 220.0
							assert(is_equal_approx(float(preview["current_value"]), expected_spring), "%s suspension preview current spring mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["next_value"]), expected_spring + 1200.0), "%s suspension preview next spring mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["current_damping"]), expected_damping), "%s suspension preview current damping mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["next_damping"]), expected_damping + 220.0), "%s suspension preview next damping mismatch." % vehicle_id)
						"efficiency":
							var expected_multiplier: float = maxf(0.70, 1.0 - float(level) * 0.08)
							assert(is_equal_approx(float(preview["current_value"]), expected_multiplier), "%s efficiency preview current multiplier mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["next_value"]), maxf(0.70, 1.0 - float(level + 1) * 0.08)), "%s efficiency preview next multiplier mismatch." % vehicle_id)
						"brakes":
							var expected_brake_force: float = 6200.0 + float(level) * 930.0
							assert(is_equal_approx(float(preview["current_value"]), expected_brake_force), "%s brake preview current force mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["next_value"]), expected_brake_force + 930.0), "%s brake preview next force mismatch." % vehicle_id)
						"nitro":
							var expected_capacity: float = 0.0 if level == 0 else 100.0 + float(level) * 20.0
							assert(is_equal_approx(float(preview["current_value"]), expected_capacity), "%s nitro preview current capacity mismatch." % vehicle_id)
							assert(is_equal_approx(float(preview["next_value"]), 100.0 + float(level + 1) * 20.0), "%s nitro preview next capacity mismatch." % vehicle_id)
					assert(not String(preview.get("text", "")).is_empty(), "%s %s should show a player-readable benefit." % [vehicle_id, part])
				else:
					assert(not bool(preview.get("available", true)) and String(preview.get("text", "")) == "VOLL AUSGEBAUT", "%s %s must identify a maxed upgrade." % [vehicle_id, part])
				checked += 1
	game.selected_vehicle = "kombi"
	game.upgrades = _empty_upgrades()
	var engine_preview: Dictionary = game.upgrade_preview("engine")
	var tank_preview: Dictionary = game.upgrade_preview("tank")
	assert(int(game.money) == 100 and int(engine_preview["price"]) + int(tank_preview["price"]) == 95, "A fresh player should see that the recommended engine/tank package fits the 100-coin starter balance.")
	game.wagon.configure(_empty_upgrades(), "kombi")
	var baseline_fuel_rate: float = game.wagon.fuel_consumption_rate(true, false)
	for nitro_stage in range(1,4):
		var levels:Dictionary=_empty_upgrades()
		levels["nitro"]=nitro_stage
		game.upgrades=levels.duplicate(true)
		game.wagon.configure(levels,"kombi")
		var actual_capacity:float=game.wagon.nitro_capacity
		var live_preview:Dictionary=game.upgrade_preview("nitro")
		if bool(live_preview.get("available",false)):
			assert(is_equal_approx(float(live_preview["current_value"]),actual_capacity),"Nitro panel must match the real mounted capacity.")
	game.upgrades=_empty_upgrades()
	game.wagon.configure({"engine": 0, "tank": 0, "tires": 2, "armor": 0, "suspension": 3, "efficiency": 3, "brakes": 3}, "kombi")
	assert(is_equal_approx(game.wagon._suspension_strength, 9500.0 + 2.0 * 900.0 + 3.0 * 1200.0), "Suspension and tire upgrades must stack on the real vehicle tuning.")
	assert(is_equal_approx(game.wagon._suspension_damping, 1550.0 + 2.0 * 100.0 + 3.0 * 220.0), "Suspension upgrades must change real damping.")
	assert(is_equal_approx(game.wagon.fuel_consumption_rate(true, false), baseline_fuel_rate * 0.76), "Three efficiency levels must reduce actual fuel use by 24 percent.")
	var expected_brake_force: float = (6200.0 + 3.0 * 930.0) * (CAMPAIGN_DATA.PIXELS_PER_METER / CAMPAIGN_DATA.LEGACY_PIXEL_SCALE)
	assert(is_equal_approx(game.wagon._brake_force, expected_brake_force), "Three brake levels must change the force used by actual braking at the current world scale.")
	game.wagon.linear_velocity.x = 1000.0
	game.wagon.hit_road_hazard(0.8, 0.0)
	assert(is_equal_approx(game.wagon.linear_velocity.x, 850.0), "Two tire levels must improve speed retention across a road hazard.")
	var hud: Variant = game.get_node("HUDLayer/HUD")
	hud.queue_redraw()
	for _frame in range(2):
		await get_tree().process_frame
	assert(_has_upgrade_button(hud, "garage_part:engine") and _has_upgrade_button(hud, "garage_part:tires") and _has_upgrade_button(hud, "garage_part:tank") and _has_upgrade_button(hud, "garage_part:armor") and _has_upgrade_button(hud, "garage_part:nitro") and _has_upgrade_button(hud, "upgrade"), "The vehicle tuning page must show its five core parts, including Nitro, with a shared improve button.")
	assert(not _has_upgrade_button(hud, "garage_part:suspension") and not _has_upgrade_button(hud, "garage_part:efficiency") and not _has_upgrade_button(hud, "garage_part:brakes") and not _has_upgrade_button(hud, "upgrade_page:next"), "The Mehr Teile workshop tab and its second page must be gone.")
	print("UPGRADE_PREVIEW_OK entries=%d vehicles=%d fresh_package=95/100 exact_stats=true live_physics=true single_vehicle_page=true nitro_in_vehicle=true maxed_state=true" % [checked, CAMPAIGN_DATA.VEHICLE_ORDER.size()])
	get_tree().quit(0)

func _empty_upgrades() -> Dictionary:
	return {"engine": 0, "tank": 0, "tires": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}

func _has_upgrade_button(hud: Variant, button_id: String) -> bool:
	for button in hud.buttons:
		if String(button.get("id", "")) == button_id:
			return true
	return false

