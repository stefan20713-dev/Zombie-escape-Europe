extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	var wagon: EscapeWagon = game.wagon
	wagon.configure({"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}, "kombi")
	wagon.set_stock_test_mode(false)
	wagon.linear_velocity.x = 1800.0
	wagon.durability = 100.0
	assert(wagon.add_zombie_latch(0.25, 1.0, 0, 0, 0.8), "A weak zombie should attach to the roof.")
	assert(wagon.add_zombie_latch(1.2, 2.0, 1, 1, 2.0), "A strong zombie should also be able to attach.")
	assert(not wagon.add_zombie_latch(0.0, 2.0, 2, 2), "Invalid latch durations should not attach.")
	wagon.update_zombie_latches(0.1)
	assert(is_equal_approx(wagon.linear_velocity.x, 1800.0 - (3.0 * wagon.PIXELS_PER_METER * 0.1)), "Attached zombies should apply real, additive drag to the car's speed.")
	var expected_contact_damage: float = (0.8 + 2.0) * 1.75 * 0.1 * wagon.armor_damage_multiplier()
	assert(is_equal_approx(wagon.durability, 100.0 - expected_contact_damage), "Both attached zombies should apply their own ongoing damage while they cling to the vehicle, scaled by armor.")
	assert(wagon.zombie_latches.size() == 2, "Both zombies should remain visible while their timers are active.")
	assert(wagon.zombie_fuel_penalty > 0.0, "Attached zombies should increase fuel use while clinging to the Kombi.")
	var fuel_rate_without_latches: float = wagon.fuel_consumption_rate(false, false) - wagon.zombie_fuel_penalty
	assert(wagon.fuel_consumption_rate(false, false) > fuel_rate_without_latches, "Zombie weight and damage should create additional fuel consumption.")
	wagon.update_zombie_latches(0.2)
	assert(wagon.zombie_latches.size() == 2, "At high speed, even a weak zombie should flutter behind the car before releasing.")
	wagon.update_zombie_latches(0.1)
	assert(wagon.zombie_latches.size() == 2 and float(wagon.zombie_latches[0].get("slipping",0.0)) > 0.0, "A weak grip should visibly slip before detaching.")
	wagon.update_zombie_latches(0.45)
	assert(wagon.zombie_latches.size() == 1, "The slipping weak zombie should fall away before the strong one.")
	wagon.zombie_latches.clear()
	wagon.linear_velocity.x = 0.0
	wagon.add_zombie_latch(1.0, 1.0, 0, 2, 1.0)
	wagon.update_zombie_latches(0.2)
	var slow_vehicle_grip_time: float = float(wagon.zombie_latches[0]["time_left"])
	wagon.zombie_latches.clear()
	wagon.linear_velocity.x = 1800.0
	wagon.add_zombie_latch(1.0, 1.0, 0, 2, 1.0)
	wagon.update_zombie_latches(0.2)
	var fast_vehicle_grip_time: float = float(wagon.zombie_latches[0]["time_left"])
	assert(slow_vehicle_grip_time > fast_vehicle_grip_time, "Zombies should hold on longer when the car is slower.")
	var weak_rolls: int = 0
	var strong_rolls: int = 0
	var no_latch_rolls: int = 0
	for meter in range(20, 220):
		var profile: Dictionary = game._zombie_latch_profile({"meter": meter, "class": "slow"}, 0)
		if profile.is_empty():
			no_latch_rolls += 1
		elif float(profile["duration"]) <= 1.6:
			weak_rolls += 1
		else:
			strong_rolls += 1
	assert(weak_rolls > 0 and strong_rolls > 0 and no_latch_rolls > 0, "Seeded slow-zombie packs should include different latch strengths and non-grabbers.")
	for armor_level in range(4):
		wagon.configure({"engine": 0, "tires": 0, "tank": 0, "armor": armor_level, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}, "kombi")
		wagon.set_stock_test_mode(false)
		wagon.linear_velocity.x = 0.0
		wagon.durability = 100.0
		assert(wagon.add_zombie_latch(2.0, 1.0, 0, 0, 1.0), "The armor damage check needs an attached zombie.")
		wagon.update_zombie_latches(0.1)
		var expected_latch_damage: float = 0.1 * 1.75 * wagon.armor_damage_multiplier()
		assert(is_equal_approx(wagon.durability, 100.0 - expected_latch_damage), "Armor %d should reduce ongoing damage from a latched zombie." % armor_level)
	print("ZOMBIE_LATCH_OK drag=true longer_grip_when_slow=true extra_fuel=true ongoing_damage=true armor_scales_damage=true varied_profiles=true no_grip=true")
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
