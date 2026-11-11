extends Node

const PREVIEW_SCENE: PackedScene = preload("res://scenes/amsterdam_preview.tscn")
const PIXELS_PER_METER: float = 36.0

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var preview: Node = PREVIEW_SCENE.instantiate()
	add_child(preview)
	await get_tree().process_frame
	var course: AmsterdamPreviewCourse = preview.get_node("Course") as AmsterdamPreviewCourse
	assert(course != null, "The Amsterdam preview must load its authored route.")
	assert(course.preview_length_m() == 1800.0, "The Amsterdam finish must be 1.8 km from the starting point.")
	assert(course.BARGE_START_M - course.START_M == 820.0, "The barge approach starts at the displayed 820 m mark.")
	for edge_m in [course.BARGE_START_M, course.BARGE_DECK_START_M, course.BARGE_DECK_END_M, course.BARGE_END_M]:
		var edge_x: float = edge_m * PIXELS_PER_METER
		assert(absf(course.height_at(edge_x - 0.01) - course.height_at(edge_x + 0.01)) < 0.1, "Barge ramps and deck must join without a collision step.")
	assert(is_equal_approx(course.height_at((course.BARGE_DECK_START_M + 5.0) * PIXELS_PER_METER), course.height_at((course.BARGE_DECK_END_M - 5.0) * PIXELS_PER_METER)), "The boat has one level driving deck.")
	assert(course.UPPER_BRIDGE_START_M - course.RAMP_LIP_M >= 30.0, "The jump needs a physical gap wide enough to separate the two routes.")
	var lower_road: CollisionShape2D = course.get_node("AmsterdamRoadCollision/LowerCanalRoad") as CollisionShape2D
	var upper_ramp: CollisionShape2D = course.get_node("UpperLaunchAndExitRampCollision/UpperRouteOnlySurface") as CollisionShape2D
	var launch_ramp: CollisionShape2D = course.get_node("UpperLaunchAndExitRampCollision/AlwaysOpenLaunchRamp") as CollisionShape2D
	var bridge_deck: CollisionShape2D = course.get_node("UpperCanalBridgeCollision/OneWayBridgeDeck") as CollisionShape2D
	assert(lower_road != null and not lower_road.disabled, "The lower underpass road must stay available at every speed.")
	assert(upper_ramp != null and upper_ramp.disabled, "The raised route must start disabled until the speed choice is made.")
	assert(launch_ramp != null and not launch_ramp.disabled, "The launch ramp must be solid before the speed decision.")
	assert(bridge_deck != null and bridge_deck.one_way_collision and not bridge_deck.disabled, "The deck must stay physically present before and during the jump.")
	assert(course.height_at(430.0 * PIXELS_PER_METER) < course._base_height_at(430.0 * PIXELS_PER_METER), "The approach follows the ramp independently of speed.")
	assert(is_equal_approx(course.height_at(455.0 * PIXELS_PER_METER), course._base_height_at(455.0 * PIXELS_PER_METER)), "A failed jump must return to the lower road.")
	print("AMSTERDAM_PREVIEW_BRANCH_OK physical_gap=true lower_route_open=true deck_always_present=true")
	preview.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
