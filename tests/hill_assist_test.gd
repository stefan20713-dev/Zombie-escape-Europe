extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const MINIMUM_CLIMB_ANGLE: float = 0.035

func _ready() -> void:
	call_deferred("_run_hill_assist_smoke")

func _run_hill_assist_smoke() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	game.screen_state = "RUN"
	game.paused = false
	game.touch_actions["accelerate"] = true
	game.wagon.fuel = 25.0
	game.wagon.nitro_level = 1
	game.wagon.nitro = 100.0
	game.wagon.speed_mps = 5.0
	var hud: Node = game.get_node("HUDLayer/HUD")

	var uphill_x: float = -1.0
	var uphill_angle: float = 0.0
	var downhill_x: float = -1.0
	var downhill_angle: float = 0.0
	var route_length: int = int(game.route_length_m)
	for meter in range(0, route_length, 2):
		var world_x: float = game.terrain.route_meter_to_world_x(float(meter))
		var slope_angle: float = game.terrain.slope_at(world_x)
		if uphill_x < 0.0 and slope_angle <= -MINIMUM_CLIMB_ANGLE:
			uphill_x = world_x
			uphill_angle = slope_angle
		elif downhill_x < 0.0 and slope_angle >= MINIMUM_CLIMB_ANGLE:
			downhill_x = world_x
			downhill_angle = slope_angle
		if uphill_x >= 0.0 and downhill_x >= 0.0:
			break
	assert(uphill_x >= 0.0 and downhill_x >= 0.0, "The starter road should contain both a climb and a descent above the boost hint threshold.")
	assert(game.terrain.height_at(uphill_x + 16.0) < game.terrain.height_at(uphill_x - 16.0), "Negative terrain slope must mean the road rises to the right.")
	assert(game.terrain.height_at(downhill_x + 16.0) > game.terrain.height_at(downhill_x - 16.0), "Positive terrain slope must mean the road falls to the right.")
	assert(bool(hud.call("should_recommend_boost_for_slope", uphill_angle)), "Boost should be recommended on a climb.")
	assert(not bool(hud.call("should_recommend_boost_for_slope", downhill_angle)), "Boost should not be recommended on a descent.")
	assert(bool(hud.call("should_recommend_boost_for_slope", -MINIMUM_CLIMB_ANGLE)), "The incline threshold should be inclusive.")
	assert(not bool(hud.call("should_recommend_boost_for_slope", -MINIMUM_CLIMB_ANGLE + 0.001)), "Near-flat road should not trigger the incline hint.")

	game.wagon.global_position.x = uphill_x
	assert(bool(hud.call("_boost_is_recommended")), "A moving, fueled vehicle accelerating uphill should receive the boost hint.")
	game.wagon.global_position.x = downhill_x
	assert(not bool(hud.call("_boost_is_recommended")), "The HUD must not recommend boost while accelerating downhill.")
	game.wagon.global_position.x = uphill_x
	game.touch_actions["accelerate"] = false
	assert(not bool(hud.call("_boost_is_recommended")), "The HUD should not recommend boost when the player is not accelerating.")
	game.touch_actions["accelerate"] = true
	game.wagon.fuel = 0.0
	assert(not bool(hud.call("_boost_is_recommended")), "The HUD should not recommend unavailable boost with an empty tank.")
	game.wagon.fuel = 25.0
	game.wagon.nitro = 0.0
	assert(not bool(hud.call("_boost_is_recommended")), "The HUD should not recommend unavailable nitro.")
	game.wagon.nitro = 100.0
	game.wagon.nitro_level = 0
	assert(not bool(hud.call("_boost_is_recommended")), "The HUD should not recommend nitro before the upgrade is purchased.")
	game.wagon.nitro_level = 1
	game.wagon.speed_mps = 14.0
	assert(not bool(hud.call("_boost_is_recommended")), "Boost advice should be reserved for low-speed climbs.")
	game.wagon.speed_mps = 5.0
	game.touch_actions["boost"] = true
	assert(not bool(hud.call("_boost_is_recommended")), "The hint should disappear while boost is already held.")

	print("HILL_ASSIST_DIRECTION_OK uphill_angle=%.3f downhill_angle=%.3f checks=14" % [uphill_angle, downhill_angle])
	get_tree().quit(0)
