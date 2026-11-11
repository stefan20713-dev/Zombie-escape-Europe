extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const TERRAIN_SCRIPT = preload("res://scripts/terrain.gd")

func _ready() -> void:
	call_deferred("_run_collision_budget_check")

func _run_collision_budget_check() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	game.selected_world_index = 0
	game.call("_configure_selected_world")
	var terrain: Node = game.get_node("Terrain")
	var end_meter: float = float(terrain.call("road_collision_end_meter"))
	var full_world_point_count: int = int(ceil(float(TERRAIN_SCRIPT.WORLD_END_M) * TERRAIN_SCRIPT.PIXELS_PER_METER / TERRAIN_SCRIPT.COLLISION_STEP)) + 1
	var active_road_point_count: int = int(terrain.get("road_collision_point_count"))
	var active_chunk_count: int = int(terrain.get("road_collision_chunk_count"))
	assert(end_meter >= float(terrain.route_length_m) + 200.0, "The road collision must retain enough runway after the finish for a long jump landing.")
	assert(active_road_point_count < full_world_point_count, "Short routes must not build distant campaign road collision points.")
	assert(active_chunk_count > 1, "The active route must use multiple short road collision shapes to keep broadphase bounds local.")
	assert(active_chunk_count <= int(ceil(end_meter / TERRAIN_SCRIPT.COLLISION_CHUNK_WIDTH_M)) + 1, "Road collision chunk count must remain bounded by route length.")
	assert(terrain.call("road_collision_covers_world_x", terrain.call("route_meter_to_world_x", 1200.0)), "A road collision chunk must cover Amsterdam's mid-route road.")
	var collision_body: StaticBody2D = terrain.get_node("RoadCollision") as StaticBody2D
	for collision_node in collision_body.get_children():
		var collision_shape: CollisionShape2D = collision_node as CollisionShape2D
		assert(collision_shape != null, "Each collision chunk must be an individual collision shape.")
		assert(collision_shape.shape is ConcavePolygonShape2D, "Each chunk must remain an open concave segment chain.")
		var segments: PackedVector2Array = (collision_shape.shape as ConcavePolygonShape2D).get_segments()
		assert(segments.size() >= 2 and segments.size() % 2 == 0, "Every collision chunk must contain paired road segments.")
		assert(segments.size() <= int(ceil(TERRAIN_SCRIPT.COLLISION_CHUNK_WIDTH_M * TERRAIN_SCRIPT.PIXELS_PER_METER / TERRAIN_SCRIPT.COLLISION_STEP)) * 2 + 2, "A road collision shape must not retain a route-sized segment list.")
	print("TERRAIN_COLLISION_BUDGET_OK full_world_points=%d amsterdam_points=%d amsterdam_chunks=%d chunk_width_m=%.0f landing_runway_m=%.0f" % [full_world_point_count, active_road_point_count, active_chunk_count, TERRAIN_SCRIPT.COLLISION_CHUNK_WIDTH_M, TERRAIN_SCRIPT.COLLISION_END_PADDING_M])
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
