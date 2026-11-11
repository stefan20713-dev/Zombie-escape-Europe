extends Node

const PREVIEW: PackedScene = preload("res://scenes/amsterdam_preview.tscn")
const ZOMBIE_DATA = preload("res://scripts/zombie_data.gd")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var drive: Node = PREVIEW.instantiate()
	add_child(drive)
	await get_tree().process_frame
	drive.set_physics_process(false)
	var course: AmsterdamPreviewCourse = drive.course
	course.set_physics_process(false)
	var wagon: EscapeWagon = drive.wagon
	wagon.freeze = false
	var group_index: int = -1
	for index in range(course._encounters.size()):
		var event: Dictionary = course._encounters[index]
		if int(event["variant"]) == 1 and event["members_data"].size() >= 3:
			group_index = index
			break
	assert(group_index >= 0)
	var group: Dictionary = course._encounters[group_index]
	course._on_encounter_body_entered(wagon, group_index, 0)
	assert(group["members_data"][0]["hit"] and not group["members_data"][1]["hit"], "A contact must hit only the member that actually touched the car.")
	assert(not group["done"], "Survivors must remain active after the first group contact.")
	assert(drive._zombie_coins == 2)
	course._on_encounter_body_entered(wagon, group_index, 0)
	assert(drive._zombie_coins == 2, "The same member must not grant a duplicate reward.")
	for index in range(1, group["members_data"].size()):
		course._on_encounter_body_entered(wagon, group_index, index)
	assert(group["done"] and drive._zombie_coins == group["members_data"].size() * 2)

	var runner: Dictionary = course._encounters[1]["members_data"][0]
	runner["x"] = wagon.position.x + wagon.front_contact_offset_px() + 16.0 * course.PIXELS_PER_METER
	var before: float = runner["x"]
	course._physics_process(0.2)
	assert(float(runner["x"]) < before and float(runner["run_phase"]) > 0.0, "An alerted runner must charge and advance its running cycle.")
	runner["x"] = wagon.position.x - 8.0 * course.PIXELS_PER_METER
	before = runner["x"]
	course._physics_process(0.2)
	assert(float(runner["x"]) > before and float(runner["facing"]) < 0.0, "A passed runner must turn and pursue the rear of the car.")
	for frame in range(4):
		var region: Rect2 = ZOMBIE_DATA.runner_charge_frame(frame)
		assert(region.size.x > 0.0 and region.size.y > 0.0)
	for style in range(3):
		assert(ZOMBIE_DATA.impact_pose(2, 38.0, 0.5, 0, style).y < 45.0, "Hit reactions should stay close to the road.")
	print("AMSTERDAM_ZOMBIE_CONTACT_OK individual_hits=true rewards_once=true pursuit=true run_frames=4 grounded_reactions=true")
	get_tree().quit()
