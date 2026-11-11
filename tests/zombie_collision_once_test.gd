extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const ZOMBIE_DATA = preload("res://scripts/zombie_data.gd")

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	game.first_drive_tutorial_completed = true
	game.selected_vehicle = "kombi"
	game.selected_world_index = 0
	game.campaign_meter = 0.0
	game._begin_run(false)
	var target: Dictionary = {}
	for entity in game.terrain.entities:
		if String(entity.get("kind", "")) == "zombie" and int(entity.get("meter", -1)) == 54:
			target = entity
			break
	assert(not target.is_empty(), "The first Amsterdam zombie should be available for the collision regression.")
	game.wagon.airborne = false
	var expected_contacts: int = int(target.get("group_size", 1))
	var front_offset_m: float = game.wagon.front_contact_offset_m()
	var base_zombie_x: float = game.terrain.route_meter_to_world_x(float(target["meter"]))
	var zombie_profile: Dictionary = ZOMBIE_DATA.profile(int(target.get("variant_id", 1)))
	var group_spacing: float = clampf(float(zombie_profile.get("visual_height", 78.0)) * 0.8, 56.0, 82.0)
	var group_reach_px: float = float(maxi(0, expected_contacts - 1)) * group_spacing * 0.5
	game.terrain.set_zombie_chase_target_x(base_zombie_x - 24.0 * game.wagon.PIXELS_PER_METER, 1.0 / 30.0)
	var chase_start_offset_px: float = float(target.get("chase_offset_px", 0.0))
	for _frame in range(29):
		game.terrain.set_zombie_chase_target_x(base_zombie_x - 24.0 * game.wagon.PIXELS_PER_METER, 1.0 / 30.0)
	var chase_offset_px: float = float(target.get("chase_offset_px", 0.0))
	assert(chase_offset_px - chase_start_offset_px > 12.0, "A nearby horde must advance in world space toward the car, not only animate in place.")
	var first_member_x: float = base_zombie_x - chase_offset_px - group_reach_px
	var zombie_half_width: float = float(zombie_profile.get("visual_height", 78.0)) * 0.31
	var chassis_half_width: float = (game.wagon.chassis_shape.shape as RectangleShape2D).size.x * 0.5
	var clear_car_x: float = first_member_x - zombie_half_width - chassis_half_width - 5.0
	game.wagon.reset_at(clear_car_x, game.terrain)
	var no_contact: Dictionary = game._zombie_group_spatial_contact(target, base_zombie_x, chase_offset_px, expected_contacts, group_spacing, zombie_profile)
	assert(not bool(no_contact.get("overlap", false)), "The hitbox must not reach a zombie before the wagon chassis physically overlaps it.")
	game._resolve_entities(0.0, 0.0, front_offset_m)
	assert(game.run_zombie_contacts == 0, "The zombie must remain ahead until the chassis physically overlaps it.")
	var actual_overlap: bool = false
	for _step in range(40):
		game.wagon.position.x += 1.0
		game.wagon.position.y = game.terrain.height_at(game.wagon.position.x) - (25.0 + game.wagon.wheel_visual_radius())
		game.wagon.global_rotation = game.terrain.slope_at(game.wagon.position.x) * 0.45
		var contact: Dictionary = game._zombie_group_spatial_contact(target, base_zombie_x, chase_offset_px, expected_contacts, group_spacing, zombie_profile)
		if bool(contact.get("overlap", false)):
			actual_overlap = true
			game._resolve_entities(0.0, 0.0, front_offset_m)
			break
	assert(actual_overlap, "Moving the wagon into the zombie must create a real oriented-chassis overlap.")
	assert(game.run_zombie_contacts == expected_contacts, "One crossing should count the horde only once.")
	assert(bool(target.get("done", false)), "The horde should stay resolved after its single collision.")
	assert(not game.wagon.zombie_latches.is_empty(), "The first authored slow zombie should visibly cling to the stock Kombi.")
	assert(bool(target.get("reacting", false)) or not game.wagon.zombie_latches.is_empty(), "The hit horde should either ragdoll or leave a zombie visibly clinging to the car.")
	var reward_after_hit: int = game.run_zombie_reward
	for _repeat in range(5):
		game._resolve_entities(0.0, 0.0, front_offset_m)
	assert(game.run_zombie_contacts == expected_contacts, "The reaction window must not allow repeated zombie contacts.")
	assert(game.run_zombie_reward == reward_after_hit, "The reaction window must not award the same horde repeatedly.")
	print("ZOMBIE_COLLISION_ONCE_OK group=%d contacts=%d latches=%d reward=%d repeat_attempts=5" % [expected_contacts, game.run_zombie_contacts, game.wagon.zombie_latches.size(), game.run_zombie_reward])
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
