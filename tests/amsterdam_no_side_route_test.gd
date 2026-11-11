extends Node
func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	var d = load("res://scenes/amsterdam_preview.tscn").instantiate()
	get_tree().root.add_child(d)
	await get_tree().physics_frame
	var c = d.course
	assert(c.action.get_child_count() == 0, "Crane action must not create route collision bodies.")
	var shape: ConcavePolygonShape2D = c.get_node("AmsterdamRoadCollision/LowerCanalRoad").shape
	var segments := shape.get_segments()
	for meter in range(1040, 1127):
		var x: float = float(meter) * 36.0
		assert(is_equal_approx(c.height_at(x), c._quay_height_at(x)))
		var present := false
		for i in range(0, segments.size(), 2):
			if segments[i].x <= x and segments[i + 1].x >= x:
				present = true
				break
		assert(present, "Continuous collision must cover the former side route.")
	assert(c.quay_visible_gap_world_bounds(1080.0 * 36.0) == c.quay_gap_world_bounds())
	assert(c.BARGE_START_M == 827.0, "The original 820 m barge remains.")
	assert(c.action.cranes.size() == 2)
	print("NO_SIDE_ROUTE_OK continuous_road=true no_route_bodies=true original_barge=true cranes=2")
	get_tree().quit()
