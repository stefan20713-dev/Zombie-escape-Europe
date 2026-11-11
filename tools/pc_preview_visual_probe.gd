extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CAPTURE_PATH: String = "res://build/pc_preview_amsterdam_tier3_in_motion_0.5.45.png"

func _ready() -> void:
	call_deferred("_capture_preview")

func _capture_preview() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.first_drive_tutorial_completed = true
	game.selected_vehicle = "kombi"
	game.selected_world_index = 0
	# Stage the visual comparison beside the first ramp and horde. The actual PC
	# preview still starts from the player's real garage and campaign progress.
	game.campaign_meter = 425.0
	if game.world_best_distances.size() > 0:
		game.world_best_distances[0] = 425.0
	if game.world_completed_flags.size() > 0:
		game.world_completed_flags[0] = false
	game.upgrades = {"engine": 3, "tires": 2, "tank": 2, "armor": 3, "suspension": 2, "efficiency": 2, "brakes": 2, "nitro": 3}
	game._begin_run(false)
	game.radio_time = 0.0
	game.toast_time = 0.0
	game.set_touch_action("accelerate", true)
	game.set_touch_action("boost", true)
	var capture_physics_frames: int = 0
	while capture_physics_frames < 720:
		await get_tree().physics_frame
		capture_physics_frames += 1
		if game.screen_state != "RUN" or absf(game.wagon.speed_mps) * 3.6 >= 105.0:
			break
	var viewport_image: Image = get_tree().root.get_viewport().get_texture().get_image()
	var save_error: Error = viewport_image.save_png(CAPTURE_PATH)
	print("PC_PREVIEW_VISUAL_CAPTURE path=%s size=%dx%d error=%d speed_kmh=%.1f boost_active=%s nitro=%.2f distance_m=%.1f build_tier=%d upgrades=%s" % [
		CAPTURE_PATH,
		viewport_image.get_width(),
		viewport_image.get_height(),
		save_error,
		absf(game.wagon.speed_mps) * 3.6,
		str(game.wagon.boost_active),
		game.wagon.nitro,
		game.run_distance,
		game.wagon.tuning_visual_tier,
		str(game.wagon.engine_level) + "/" + str(game.wagon.tire_level) + "/" + str(game.wagon.tank_level) + "/" + str(game.wagon.armor_level) + "/" + str(game.wagon.suspension_level) + "/" + str(game.wagon.efficiency_level) + "/" + str(game.wagon.brake_level)
	])
	for _frame_index in range(180):
		await get_tree().physics_frame
	print("PC_PREVIEW_RENDER_CHECK fps=%d speed_kmh=%.1f distance_m=%.1f draw_calls=%d" % [
		Engine.get_frames_per_second(),
		absf(game.wagon.speed_mps) * 3.6,
		game.run_distance,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	])
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()
