extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const RECOVERY_FRAMES: int = 36
const COUNTERSTEER_FRAMES: int = 16

func _ready() -> void:
	call_deferred("_run_air_righting_test")

func _run_air_righting_test() -> void:
	var game: Node2D = MAIN_SCENE.instantiate() as Node2D
	add_child(game)
	await get_tree().process_frame
	game.first_drive_tutorial_completed = true
	game.unlocked_world_index = 0
	game.selected_world_index = 0
	game.world_completed_flags.fill(false)
	game.world_best_distances.fill(0.0)
	game._configure_selected_world()
	game.start_run()
	assert(game.screen_state == "RUN", "The air-righting test needs the production run state.")

	var wagon: EscapeWagon = game.wagon as EscapeWagon
	var terrain: EscapeTerrain = game.terrain as EscapeTerrain
	var world_x: float = wagon.position.x
	var road_y: float = terrain.height_at(world_x)
	var road_angle: float = terrain.slope_at(world_x)
	wagon.global_position = Vector2(world_x, road_y - 260.0)
	wagon.global_rotation = road_angle - 0.82
	wagon.linear_velocity = Vector2.ZERO
	wagon.angular_velocity = 0.0
	wagon.airborne = true
	var initial_error: float = absf(wrapf(wagon.global_rotation - road_angle, -PI, PI))
	for frame_index in range(RECOVERY_FRAMES):
		await get_tree().physics_frame
	var released_error: float = absf(wrapf(wagon.global_rotation - terrain.slope_at(wagon.position.x), -PI, PI))
	assert(released_error < initial_error - 0.10, "With tilt released, an airborne/one-wheel wagon should settle back toward the road angle.")

	game.clear_touch_actions()
	world_x = wagon.position.x
	road_y = terrain.height_at(world_x)
	road_angle = terrain.slope_at(world_x)
	wagon.global_position = Vector2(world_x, road_y - 260.0)
	wagon.global_rotation = road_angle + 0.82
	wagon.linear_velocity = Vector2.ZERO
	wagon.angular_velocity = 0.0
	wagon.airborne = true
	game.touch_actions["tilt_left"] = true
	var countersteer_start: float = absf(wrapf(wagon.global_rotation - road_angle, -PI, PI))
	for frame_index in range(COUNTERSTEER_FRAMES):
		await get_tree().physics_frame
	var countersteer_end: float = absf(wrapf(wagon.global_rotation - terrain.slope_at(wagon.position.x), -PI, PI))
	assert(countersteer_end < countersteer_start - 0.035, "Counter-steering into a large airborne tilt should reduce its angle.")

	game.clear_touch_actions()
	world_x = wagon.position.x
	road_y = terrain.height_at(world_x)
	road_angle = terrain.slope_at(world_x)
	wagon.global_rotation = road_angle + PI
	wagon.angular_velocity = 0.0
	wagon._upside_down_time_s = 0.0
	wagon.overturned = false
	wagon.global_position.y = road_y - _chassis_bottom_offset(wagon)
	wagon.update_overturn_state(0.60, road_y, road_angle)
	assert(wagon.overturned, "A stable roof-first landing near the road should register as overturned.")

	wagon._upside_down_time_s = 0.0
	wagon.overturned = false
	wagon.global_position.y = road_y - _chassis_bottom_offset(wagon) - 260.0
	wagon.update_overturn_state(0.70, road_y, road_angle)
	assert(not wagon.overturned, "An upside-down pose far above the road must remain recoverable.")

	print("AIR_RIGHTING_OK passive_release=%.3f->%.3f countersteer=%.3f->%.3f roof_contact=true airborne_rollover=false" % [
		initial_error,
		released_error,
		countersteer_start,
		countersteer_end
	])
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _chassis_bottom_offset(wagon: EscapeWagon) -> float:
	var chassis: RectangleShape2D = wagon.chassis_shape.shape as RectangleShape2D
	var half_width: float = chassis.size.x * 0.5
	var half_height: float = chassis.size.y * 0.5
	return wagon.chassis_shape.position.rotated(wagon.global_rotation).y + absf(cos(wagon.global_rotation)) * half_height + absf(sin(wagon.global_rotation)) * half_width
