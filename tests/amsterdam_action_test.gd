extends Node
var shaken := 0
var hazard_hits := 0
func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	var drive = load("res://scenes/amsterdam_preview.tscn").instantiate()
	drive.workshop_vehicle = "kombi"
	drive.workshop_upgrades = {"engine": 2, "tires": 2, "tank": 3, "armor": 2, "nitro": 3, "suspension": 1}
	get_tree().root.add_child(drive)
	await get_tree().physics_frame
	var w = drive.wagon
	var a = drive.course.action
	w.zombies_shaken.connect(func(count: int): shaken += count)
	a.hazard_hit.connect(func(): hazard_hits += 1)
	# Holding constant speed never counts as a deliberate shake maneuver.
	w.add_zombie_latch(12.0, 1.0, 0, 1)
	w.airborne = false
	w.linear_velocity.x = 22.0 * 36.0
	for i in range(120):
		w._update_shake_maneuver(1.0 / 60.0, true, false, false)
	assert(shaken == 0)
	for i in range(18):
		w.linear_velocity.x = (22.0 - float(i) * 0.2) * 36.0
		w._update_shake_maneuver(1.0 / 60.0, false, true, false)
	for i in range(65):
		w._update_shake_maneuver(1.0 / 60.0, true, false, false)
	assert(shaken == 1)
	w.update_zombie_latches(0.50)
	assert(w.zombie_latches.is_empty() and w._released_zombies.size() == 1)
	# Combo pays only real event callbacks, resets on a hit, and caps each bonus.
	drive._on_zombie_shot()
	drive._on_zombie_shot()
	drive._on_zombie_shot()
	assert(drive._combo_count == 3 and drive._combo_coins == 3)
	drive._break_combo()
	assert(drive._combo_count == 0)
	drive._combo_left_s = 0.01
	drive._update_action_tracking(0.02, false)
	assert(drive._combo_count == 0)
	# Spatial crane collision: no distance-only damage and only one hit per load.
	w.freeze = false
	var crane: Dictionary = a.cranes[0]
	w.position = Vector2(float(crane.meter) * 36.0 - 1000.0, 0.0)
	a.update_action(0.01, w, false)
	assert(crane.warned and hazard_hits == 0)
	w.rotation = 0.0
	w.position = a.load_rect(crane).get_center()
	a.update_action(0.001, w, false)
	a.update_action(0.001, w, false)
	assert(hazard_hits == 1)
	a.reset()
	assert(not a.cranes[0].hit and not a.cranes[0].warned)
	print("AMSTERDAM_ACTION_OK shake=deliberate combo=bounded crane=spatial_once reset=true")
	get_tree().quit()
