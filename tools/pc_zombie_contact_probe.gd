extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CAPTURE_PATH: String = "res://build/pc_preview_amsterdam_zombie_contact_0.5.45.png"
const ZOMBIE_METER: float = 54.0

func _ready() -> void:
	call_deferred("_capture_real_encounter")

func _capture_real_encounter() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.first_drive_tutorial_completed = true
	game.selected_vehicle = "kombi"
	game.selected_world_index = 0
	game.campaign_meter = 0.0
	if game.world_best_distances.size() > 0:
		game.world_best_distances[0] = 0.0
	if game.world_completed_flags.size() > 0:
		game.world_completed_flags[0] = false
	game.upgrades = {"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}
	game._begin_run(false)
	game.radio_time = 0.0
	game.toast_time = 0.0
	var target: Dictionary = {}
	for entity in game.terrain.entities:
		if String(entity.get("kind", "")) == "zombie" and is_equal_approx(float(entity.get("meter", -1.0)), ZOMBIE_METER):
			target = entity
			break
	assert(not target.is_empty(), "The authored Amsterdam zombie at 54 m must exist in the production route.")
	assert(int(target.get("variant_id", 0)) == 1, "The Amsterdam encounter must use the selected yellow-raincoat zombie.")
	assert(int(target.get("group_size", 0)) == 1, "Amsterdam must contain only the single requested introductory zombie.")
	var start_durability: float = game.wagon.durability
	var start_fuel: float = game.wagon.fuel
	game.set_touch_action("accelerate", true)
	var reached_and_latched: bool = false
	var drive_frames: int = 0
	for frame_index in range(900):
		await get_tree().physics_frame
		drive_frames = frame_index + 1
		if game.run_zombie_contacts > 0 and not game.wagon.zombie_latches.is_empty():
			reached_and_latched = true
			break
	game.set_touch_action("accelerate", false)
	assert(reached_and_latched, "The production drive should reach and attach the Amsterdam zombie without scripted position changes.")
	assert(bool(target.get("done", false)), "The real collision should resolve the encounter once.")
	assert(game.wagon.durability < start_durability, "The real zombie collision should damage the stock vehicle.")
	assert(game.run_zombie_contacts == 1, "The single Amsterdam zombie must count as one contact.")
	for _frame_index in range(14):
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_tree().root.get_viewport().get_texture().get_image()
	var save_error: Error = image.save_png(CAPTURE_PATH)
	assert(save_error == OK, "The real encounter screenshot should save successfully.")
	print("PC_ZOMBIE_CONTACT_CAPTURE path=%s size=%dx%d drive_frames=%d route_m=%.1f speed_kmh=%.1f contacts=%d latches=%d damage=%.2f fuel_used=%.2f variant=%d paused=%s" % [
		CAPTURE_PATH,
		image.get_width(),
		image.get_height(),
		drive_frames,
		game.run_start_meter + game.run_distance,
		absf(game.wagon.speed_mps) * 3.6,
		game.run_zombie_contacts,
		game.wagon.zombie_latches.size(),
		start_durability - game.wagon.durability,
		start_fuel - game.wagon.fuel,
		int(target.get("variant_id", 0)),
		str(game.paused)
	])
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
