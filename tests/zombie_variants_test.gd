extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const ZOMBIE_DATA = preload("res://scripts/zombie_data.gd")

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	var walk_a: Dictionary = ZOMBIE_DATA.walk_motion(0.0, 0.8)
	var walk_b: Dictionary = ZOMBIE_DATA.walk_motion(PI * 0.5, 0.8)
	assert(not is_equal_approx(float(walk_a["left_step"]), float(walk_b["left_step"])), "Approaching zombies must visibly animate their steps.")
	assert(not is_equal_approx(float(walk_a["arm_swing"]), float(walk_b["arm_swing"])), "Approaching zombies must visibly swing their reaching arm.")
	var latch_a: Dictionary = ZOMBIE_DATA.latch_motion(0.0, 0.8)
	var latch_b: Dictionary = ZOMBIE_DATA.latch_motion(PI * 0.5, 0.8)
	assert(Vector2(latch_a["left_knee"]) != Vector2(latch_b["left_knee"]), "Attached zombies must kick their legs while hanging.")
	assert(Vector2(latch_a["left_elbow"]) != Vector2(latch_b["left_elbow"]), "Attached zombies must flex both arms while gripping the roof.")

	for variant_id in range(1, 6):
		var profile: Dictionary = ZOMBIE_DATA.profile(variant_id)
		assert(float(profile.get("hit_damage", 0.0)) > 0.0, "Every zombie needs its own impact damage.")
		assert(float(profile.get("speed_retention", 1.0)) < 1.0, "Every zombie collision must affect vehicle speed.")
		var texture_paths: Array[String] = [
			"res://assets/zombie_normal_0.7.0.png",
			"res://assets/zombie_runner_0.7.0.png",
			"res://assets/zombie_worker_0.7.0.png",
			"res://assets/zombie_riot_0.7.0.png",
			"res://assets/zombie_brute_0.7.0.png"
		]
		assert(ResourceLoader.load(texture_paths[variant_id - 1]) is Texture2D, "Zombie variant %d must have a loadable illustration." % variant_id)
		assert(game.wagon.zombie_latch_texture(variant_id) is Texture2D, "Each zombie illustration must be available to the hanging pose renderer.")

	var normal_latch: Dictionary = ZOMBIE_DATA.latch_profile(1, 54)
	var runner_latch: Dictionary = ZOMBIE_DATA.latch_profile(2, 99)
	var worker_latch: Dictionary = ZOMBIE_DATA.latch_profile(3, 99)
	var riot_latch: Dictionary = ZOMBIE_DATA.latch_profile(4, 99)
	var brute_latch: Dictionary = ZOMBIE_DATA.latch_profile(5, 99)
	assert(not normal_latch.is_empty(), "A normal zombie must sometimes grip the car.")
	assert(float(runner_latch["duration"]) < float(normal_latch["duration"]), "The runner's rare grip must be shorter than a normal zombie's.")
	assert(float(worker_latch["duration"]) > float(normal_latch["duration"]), "The construction worker must hold on longer than a normal zombie.")
	assert(float(riot_latch["duration"]) > float(worker_latch["duration"]), "The riot zombie must hold on longer than the worker.")
	assert(float(brute_latch["damage"]) > float(riot_latch["damage"]), "The brute must cause the most ongoing damage.")
	assert(float(normal_latch["duration"]) >= 2.5, "The normal zombie must hold on long enough to be seen during the drive.")
	assert(float(worker_latch["duration"]) >= 5.0 and float(riot_latch["duration"]) >= 6.0 and float(brute_latch["duration"]) >= 7.0, "Heavy zombies should remain attached substantially longer.")
	assert(is_equal_approx(float(ZOMBIE_DATA.profile(5)["stop_duration"]), 1.0), "The brute must stop the car for one second.")

	game.selected_world_index = 0
	game._configure_selected_world()
	var amsterdam_zombie_groups: int = 0
	var amsterdam_zombie_count: int = 0
	for entity in game.terrain.entities:
		if String(entity.get("kind", "")) != "zombie":
			continue
		amsterdam_zombie_groups += 1
		amsterdam_zombie_count += int(entity.get("group_size", 1))
		assert(int(entity.get("variant_id", 0)) == 1, "Amsterdam's introductory horde should use the normal zombie.")
	assert(amsterdam_zombie_groups == 1 and amsterdam_zombie_count == 1, "Amsterdam should have just one introductory zombie encounter.")

	assert(ZOMBIE_DATA.variant_for_world("amsterdam", 0, 0) == 2, "The Amsterdam route should include the quick, lighter zombie variant.")
	assert(ZOMBIE_DATA.variant_for_world("amsterdam", 0, 1) == 1, "The Amsterdam route should include the normal zombie variant.")

	var wagon: EscapeWagon = game.wagon
	wagon.configure({"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}, "kombi")
	assert(wagon.add_zombie_latch(1.0, 1.0, 0, 1), "The normal zombie should be able to latch onto the vehicle roof.")
	assert(is_equal_approx(float(wagon.zombie_latches[0]["anchor"].y), wagon.KOMBI_ROOF_GRIP_Y), "The grip point must sit on the Kombi roof line.")
	wagon.set_stock_test_mode(false)
	wagon.airborne = false
	wagon.linear_velocity.x = 1200.0
	wagon.durability = 100.0
	wagon.hit_zombie(float(ZOMBIE_DATA.profile(2)["hit_damage"]), float(ZOMBIE_DATA.profile(2)["speed_retention"]))
	assert(is_equal_approx(wagon.linear_velocity.x, 1200.0 * float(ZOMBIE_DATA.profile(2)["speed_retention"])), "The runner must cause only a light speed loss.")
	assert(wagon.durability > 90.0, "The runner must cause little direct damage.")

	wagon.configure({"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}, "kombi")
	wagon.set_stock_test_mode(false)
	wagon.airborne = false
	wagon.linear_velocity.x = 1800.0
	wagon.durability = 100.0
	wagon.hit_zombie(float(ZOMBIE_DATA.profile(5)["hit_damage"]), float(ZOMBIE_DATA.profile(5)["speed_retention"]), 1.0)
	assert(is_zero_approx(wagon.linear_velocity.x), "The brute must immediately stop the car.")
	assert(is_equal_approx(wagon._zombie_stop_time_s, 1.0), "The brute's stop timer must begin at one second.")
	assert(wagon.durability < 75.0, "The brute must inflict heavy direct damage.")
	for _step in range(4):
		wagon.simulate(0.25, true, false, false, 0.0)
		assert(is_zero_approx(wagon.linear_velocity.x), "The car must remain stopped throughout the full second.")
	assert(is_zero_approx(wagon._zombie_stop_time_s), "The brute's stop timer must expire after one second.")

	print("ZOMBIE_VARIANTS_OK profiles=5 gait=walking_limbs_and_hanging_kick amsterdam=normal_and_fast variants=5 assets=5")
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
