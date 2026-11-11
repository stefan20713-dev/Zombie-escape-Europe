extends Node
const DATA = preload("res://scripts/zombie_data.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var preview = load("res://scenes/amsterdam_preview.tscn").instantiate()
	preview.workshop_vehicle = "kombi"
	preview.workshop_upgrades = {"engine": 1, "tires": 1, "tank": 2, "armor": 1}
	get_tree().root.add_child(preview)
	await get_tree().physics_frame
	preview.set_physics_process(false)
	preview.course.set_physics_process(false)
	var wagon = preview.wagon
	for variant in range(1, 6):
		wagon.reset_at(60.0 * 36.0, preview.course)
		wagon.linear_velocity.x = 18.0 * 36.0
		preview._zombie_latch_cooldown_s = 0.0
		preview._on_encounter_hit("zombie_group", 0.0, variant, 1, 99.0 * 36.0, preview.course.height_at(99.0 * 36.0), 18.0)
		assert(wagon.zombie_latches.size() == 1, "Each zombie type must be able to grab through the actual encounter callback.")
		assert(float(wagon.zombie_latches[0]["facing"]) == 1.0, "Forward driving must show a forward-facing climber.")
		var crawled := false
		preview.camera.position = wagon.position + Vector2(278.0, -75.0)
		preview.camera.reset_smoothing()
		await _capture("anfang-" + str(variant))
		for frame in range(80):
			wagon.linear_velocity.x = 18.0 * 36.0
			wagon.update_zombie_latches(0.05)
			if not wagon.zombie_latches.is_empty():
				crawled = crawled or (wagon.zombie_latches[0]["mount"] == "roof" and float(wagon.zombie_latches[0]["crawl_distance"]) > 0.1)
		assert(crawled, "Attached zombie must pull onto the roof and crawl toward the bonnet.")
		await _capture("vorwaerts-" + str(variant))
		var frames := 0
		while not wagon.zombie_latches.is_empty() and frames < 1600:
			wagon.linear_velocity.x = 25.0 * 36.0
			wagon.update_zombie_latches(0.05)
			frames += 1
		assert(wagon.zombie_latches.is_empty() and wagon._released_zombies.size() == 1, "Losing the grip must produce a visible falling zombie.")
		wagon.update_zombie_latches(0.3)
		assert(wagon._released_zombies.size() == 1, "A released zombie must remain visible briefly.")
		await _capture("abfallen-" + str(variant))
		wagon.update_zombie_latches(6.0)
		assert(wagon._released_zombies.is_empty(), "Falling visuals must clean up.")
		for index in range(4):
			var rect: Rect2 = DATA.crawl_frame(variant, index)
			assert(rect.size.x > 0.0 and rect.size.y > 0.0)
		print("ZOMBIE_CLIMB_VARIANT_OK variant=", variant, " forward=true climbed=true visible_release=true")
	wagon.reset_at(7.0 * 36.0, preview.course)
	assert(wagon.zombie_latches.is_empty() and wagon._released_zombies.is_empty())
	wagon.linear_velocity.x = -5.0 * 36.0
	wagon.add_zombie_latch(3.0, 0.5, 0, 3)
	assert(float(wagon.zombie_latches[0]["facing"]) == 1.0, "Even rolling backward must not turn a zombie away from the bonnet.")
	wagon.add_zombie_latch(3.0, 0.5, 1, 4)
	for frame in range(40):
		wagon.update_zombie_latches(0.05)
		assert(wagon.zombie_latches[0]["mount"] == "roof" and wagon.zombie_latches[1]["mount"] == "side", "A second zombie must wait at the side while the roof is occupied.")
	wagon.zombie_latches.pop_front()
	for frame in range(32):
		wagon.update_zombie_latches(0.05)
	assert(wagon.zombie_latches[0]["mount"] == "roof", "The waiting zombie climbs once the roof is free.")
	var anchor: Vector2 = wagon.zombie_latches[0]["anchor"]
	for frame in range(2):
		var pose: Rect2 = wagon.ATTACHMENT_ART.local_rect(4, frame, false, -1.0, wagon._roof_crawl_scale(4))
		assert(pose.size.x > 76.0 and pose.position.x + anchor.x >= -80.0 and pose.end.x + anchor.x <= 18.0, "The crawl keeps a full-sized silhouette within the Kombi roof.")
	print("ZOMBIE_CLIMB_OK types=5 frames=20 forward_climb=true release=true reset=true")
	get_tree().quit()

func _capture(stage: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for frame in range(5):
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/zombie-klettern-" + stage + ".png")
