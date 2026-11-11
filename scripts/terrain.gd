extends Node2D
class_name EscapeTerrain

const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const CHALLENGE_DATA = preload("res://scripts/challenge_data.gd")
const QA_DIAGNOSTICS = preload("res://scripts/qa_diagnostics.gd")
const ZOMBIE_DATA = preload("res://scripts/zombie_data.gd")
const ZOMBIE_NORMAL_TEXTURE: Texture2D = preload("res://assets/zombie_normal_0.7.0.png")
const ZOMBIE_NORMAL_RUN_TEXTURE: Texture2D = preload("res://assets/zombie_normal_run_0.7.1.png")
const ZOMBIE_NORMAL_LATCH_TEXTURE: Texture2D = preload("res://assets/zombie_normal_latch_0.7.1.png")
const ZOMBIE_RUNNER_TEXTURE: Texture2D = preload("res://assets/zombie_runner_0.7.0.png")
const ZOMBIE_WORKER_TEXTURE: Texture2D = preload("res://assets/zombie_worker_0.7.0.png")
const ZOMBIE_RIOT_TEXTURE: Texture2D = preload("res://assets/zombie_riot_0.7.0.png")
const ZOMBIE_BRUTE_TEXTURE: Texture2D = preload("res://assets/zombie_brute_0.7.0.png")
const AMSTERDAM_COBBLE_TILE: Texture2D = preload("res://assets/amsterdam_cobble_tile.svg")
const AMSTERDAM_QUAY_BRICK_TILE: Texture2D = preload("res://assets/amsterdam_quay_brick_tile.svg")
const ZOMBIE_NORMAL_RUN_FRAMES: Array[Rect2] = [
	Rect2(0.0, 0.0, 650.0, 713.0), Rect2(650.0, 0.0, 425.0, 713.0),
	Rect2(1075.0, 0.0, 635.0, 713.0), Rect2(1710.0, 0.0, 496.0, 713.0)
]
const ZOMBIE_NORMAL_LATCH_FRAMES: Array[Rect2] = [
	Rect2(18.0, 0.0, 500.0, 724.0), Rect2(670.0, 0.0, 330.0, 724.0),
	Rect2(1098.0, 0.0, 520.0, 724.0), Rect2(1798.0, 0.0, 320.0, 724.0)
]
const PIXELS_PER_METER: float = CAMPAIGN_DATA.PIXELS_PER_METER
const START_OFFSET_M: float = CAMPAIGN_DATA.WORLD_START_OFFSET_M
const WORLD_END_M: float = 3320.0
const DRAW_STEP: float = 22.0
const COLLISION_STEP: float = 54.0
const COLLISION_END_PADDING_M: float = 220.0
const COLLISION_CHUNK_WIDTH_M: float = 60.0
const ROAD_POST_SPACING_M: float = 45.0
const ROAD_SURFACE_DEPTH: float = 36.0
const REDRAW_INTERVAL_S: float = 1.0 / 30.0
const AMSTERDAM_POTHOLE_METERS: Array[float] = [72.0, 96.0, 222.0, 286.0, 390.0, 642.0, 835.0, 910.0, 945.0, 1188.0, 1380.0, 1478.0, 1668.0, 1750.0]
const AMSTERDAM_RAMP_PROFILES: Array[Dictionary] = [
	{"event_m": 258.0, "start_m": 242.0, "lip_m": 258.0, "crest_end_m": 258.0, "end_m": 302.0, "height_m": 2.1, "style": "amsterdam_timber_ramp"},
	{"event_m": 512.0, "start_m": 486.0, "lip_m": 498.0, "crest_end_m": 513.0, "end_m": 530.0, "height_m": 5.5, "style": "amsterdam_timber_ramp"},
	{"event_m": 628.0, "start_m": 612.0, "lip_m": 628.0, "crest_end_m": 628.0, "end_m": 678.0, "height_m": 3.4, "style": "amsterdam_timber_ramp"},
	{"event_m": 778.0, "start_m": 758.0, "lip_m": 778.0, "crest_end_m": 778.0, "end_m": 807.0, "height_m": 2.6, "style": "amsterdam_timber_ramp"},
	{"event_m": 872.0, "start_m": 856.0, "lip_m": 872.0, "crest_end_m": 872.0, "end_m": 916.0, "height_m": 2.8, "style": "amsterdam_timber_ramp"},
	{"event_m": 1046.0, "start_m": 1024.0, "lip_m": 1046.0, "crest_end_m": 1046.0, "end_m": 1084.0, "height_m": 5.2, "style": "amsterdam_schanze"},
	{"event_m": 1252.0, "start_m": 1228.0, "lip_m": 1252.0, "crest_end_m": 1252.0, "end_m": 1288.0, "height_m": 3.2, "style": "amsterdam_timber_ramp"},
	{"event_m": 1570.0, "start_m": 1548.0, "lip_m": 1570.0, "crest_end_m": 1570.0, "end_m": 1604.0, "height_m": 2.5, "style": "amsterdam_timber_ramp"}
]

var entities: Array[Dictionary] = []
var active_world_index: int = 0
var active_world: Dictionary = {}
var route_length_m: float = 1800.0
var final_rescue_mode: bool = false
var story_log_available: bool = true
var _redraw_elapsed: float = 0.0
var _last_draw_camera_x: float = -INF
var _first_draw_reported: bool = false
var _draw_ground_heights: PackedFloat32Array = PackedFloat32Array()
var _draw_road_points: PackedVector2Array = PackedVector2Array()
var _draw_road_surface: PackedVector2Array = PackedVector2Array()
var _draw_road_surface_uvs: PackedVector2Array = PackedVector2Array()
var _draw_road_underside: PackedVector2Array = PackedVector2Array()
var _draw_road_wear: PackedVector2Array = PackedVector2Array()
var _draw_ground_fill: PackedVector2Array = PackedVector2Array()
var _draw_ground_uvs: PackedVector2Array = PackedVector2Array()
var _draw_verge_points: PackedVector2Array = PackedVector2Array()
var _roadside_ground_heights: Dictionary = {}
var _surface_palette: Dictionary = {}
var _event_particles: Array[Dictionary] = []
var _shot_zombie_reactions: Array[Dictionary] = []
var _zombie_chase_target_x: float = 0.0
var _campaign_difficulty: float = 0.0
var _hill_theme_multiplier: float = 1.0
var _city_seed: float = 0.0
var _route_elevation_profile: Array = []
var _challenge_jump_ramp_active: bool = false
var road_collision_point_count: int = 0
var road_collision_chunk_count: int = 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var started_usec: int = Time.get_ticks_usec()
	active_world = CAMPAIGN_DATA.CAMPAIGN_WORLDS[active_world_index]
	route_length_m = float(active_world["length_m"])
	_cache_world_height_parameters()
	_build_entities()
	_rebuild_visual_cache()
	var entities_ready_usec: int = Time.get_ticks_usec()
	_build_road_collision()
	if QA_DIAGNOSTICS.enabled():
		print("[PERF] terrain_ready_ms=%d entities_ms=%d collision_ms=%d road_vertices=%d" % [
			int((Time.get_ticks_usec() - started_usec) / 1000),
			int((entities_ready_usec - started_usec) / 1000),
			int((Time.get_ticks_usec() - entities_ready_usec) / 1000),
			road_collision_point_count
		])
		print("[PERF] road_collision_points=%d road_collision_segments=%d road_collision_chunks=%d chunk_width_m=%.0f" % [
			road_collision_point_count,
			maxi(0, road_collision_point_count - road_collision_chunk_count),
			road_collision_chunk_count,
			COLLISION_CHUNK_WIDTH_M
		])
	queue_redraw()

func _process(delta: float) -> void:
	var animated_content: bool = false
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		var half_view_width: float = get_viewport_rect().size.x / maxf(0.02, camera.zoom.x) * 0.5
		for entity in entities:
			if String(entity.get("kind", "")) != "zombie" or bool(entity.get("done", false)):
				continue
			var zombie_x: float = float(entity.get("meter", 0.0)) * PIXELS_PER_METER + START_OFFSET_M * PIXELS_PER_METER
			if absf(zombie_x - camera.global_position.x) <= half_view_width + 90.0:
				animated_content = true
				break
	for entity in entities:
		if not bool(entity.get("reacting", false)):
			continue
		var reaction_left: float = maxf(0.0, float(entity.get("reaction_left", 0.0)) - delta)
		entity["reaction_left"] = reaction_left
		if reaction_left <= 0.0:
			entity["reacting"] = false
			entity["done"] = true
		else:
			animated_content = true
	for reaction_index in range(_shot_zombie_reactions.size() - 1, -1, -1):
		var shot_reaction: Dictionary = _shot_zombie_reactions[reaction_index]
		var life: float = maxf(0.0, float(shot_reaction.get("life", 0.0)) - delta)
		shot_reaction["life"] = life
		if life <= 0.0:
			_shot_zombie_reactions.remove_at(reaction_index)
			continue
		var shot_velocity: Vector2 = Vector2(shot_reaction.get("velocity", Vector2.ZERO))
		shot_velocity.y += 620.0 * delta
		shot_velocity.x *= exp(-0.85 * delta)
		var rotation: float = float(shot_reaction.get("rotation", 0.0)) + float(shot_reaction.get("angular_velocity", -2.4)) * delta
		var position: Vector2 = Vector2(shot_reaction["position"]) + shot_velocity * delta
		var floor_extent: float = (absf(cos(rotation)) * float(shot_reaction["height"]) + absf(sin(rotation)) * float(shot_reaction["width"])) * 0.5
		if position.y > float(shot_reaction["ground_y"]) - floor_extent:
			position.y = float(shot_reaction["ground_y"]) - floor_extent
			shot_velocity.y = 0.0
			shot_reaction["angular_velocity"] = float(shot_reaction["angular_velocity"]) * exp(-4.0 * delta)
		shot_reaction["velocity"] = shot_velocity
		shot_reaction["position"] = position
		shot_reaction["rotation"] = rotation
		animated_content = true
	for particle_index in range(_event_particles.size() - 1, -1, -1):
		var particle: Dictionary = _event_particles[particle_index]
		var particle_life: float = maxf(0.0, float(particle["life"]) - delta)
		particle["life"] = particle_life
		if particle_life <= 0.0:
			_event_particles.remove_at(particle_index)
			continue
		var velocity: Vector2 = Vector2(particle["velocity"])
		velocity.y += float(particle.get("gravity", 410.0)) * delta
		particle["velocity"] = velocity
		particle["position"] = Vector2(particle["position"]) + velocity * delta
		particle["rotation"] = float(particle.get("rotation", 0.0)) + float(particle.get("spin", 0.0)) * delta
		animated_content = true
	if animated_content:
		_redraw_elapsed += delta
		if _redraw_elapsed >= REDRAW_INTERVAL_S:
			_redraw_elapsed = 0.0
			queue_redraw()
	if camera == null:
		return
	var camera_x: float = camera.global_position.x
	if absf(camera_x - _last_draw_camera_x) < 1.0:
		return
	_redraw_elapsed += delta
	if _redraw_elapsed < REDRAW_INTERVAL_S:
		return
	_redraw_elapsed = 0.0
	_last_draw_camera_x = camera_x
	queue_redraw()

func _build_road_collision() -> void:
	var existing_road: Node = get_node_or_null("RoadCollision")
	if existing_road != null:
		remove_child(existing_road)
		existing_road.queue_free()
	road_collision_point_count = 0
	road_collision_chunk_count = 0
	var road := StaticBody2D.new()
	road.name = "RoadCollision"
	road.collision_layer = 1
	road.collision_mask = 0
	# Keep the collision path as short open chains in the physics broadphase.
	# One long concave chain makes every vehicle contact query inspect an entire
	# route-sized AABB; 60 m chunks let physics discard distant road sections.
	var route_end: float = road_collision_end_meter() * PIXELS_PER_METER
	var chunk_width_px: float = COLLISION_CHUNK_WIDTH_M * PIXELS_PER_METER
	var chunk_start: float = 0.0
	while chunk_start < route_end:
		var chunk_end: float = minf(route_end, chunk_start + chunk_width_px)
		var chunk_center: float = (chunk_start + chunk_end) * 0.5
		var points := PackedVector2Array()
		points.append(Vector2(chunk_start - chunk_center, height_at(chunk_start)))
		var sample_x: float = chunk_start + COLLISION_STEP
		while sample_x < chunk_end:
			points.append(Vector2(sample_x - chunk_center, height_at(sample_x)))
			sample_x += COLLISION_STEP
		points.append(Vector2(chunk_end - chunk_center, height_at(chunk_end)))
		var segments := PackedVector2Array()
		for point_index in range(points.size() - 1):
			segments.append(points[point_index])
			segments.append(points[point_index + 1])
		var segment_shape := ConcavePolygonShape2D.new()
		segment_shape.set_segments(segments)
		var collision_shape := CollisionShape2D.new()
		collision_shape.name = "RoadShape_%03d" % road_collision_chunk_count
		collision_shape.position.x = chunk_center
		collision_shape.shape = segment_shape
		road.add_child(collision_shape)
		road_collision_point_count += points.size()
		road_collision_chunk_count += 1
		chunk_start = chunk_end
	add_child(road)

func road_collision_covers_world_x(world_x: float, tolerance_px: float = COLLISION_STEP * 0.5) -> bool:
	var road: StaticBody2D = get_node_or_null("RoadCollision") as StaticBody2D
	if road == null:
		return false
	for child in road.get_children():
		var collision_shape: CollisionShape2D = child as CollisionShape2D
		if collision_shape == null or not (collision_shape.shape is ConcavePolygonShape2D):
			continue
		var concave_shape: ConcavePolygonShape2D = collision_shape.shape as ConcavePolygonShape2D
		for point in concave_shape.get_segments():
			if absf(collision_shape.position.x + point.x - world_x) <= tolerance_px:
				return true
	return false

func road_collision_end_meter() -> float:
	return minf(WORLD_END_M, route_length_m + START_OFFSET_M + COLLISION_END_PADDING_M)

func height_at(world_x: float) -> float:
	var route_meter: float = maxf(0.0, world_x / PIXELS_PER_METER - START_OFFSET_M)
	var level_progress: float = clampf(route_meter / maxf(1.0, route_length_m), 0.0, 1.0)
	var hill_intensity: float = lerpf(0.32, 0.70 + _campaign_difficulty * 0.22, smoothstep(0.0, 0.58, level_progress)) * _hill_theme_multiplier
	var legacy_world_x: float = world_x * CAMPAIGN_DATA.LEGACY_PIXEL_SCALE / PIXELS_PER_METER
	var vertical_scale: float = PIXELS_PER_METER / CAMPAIGN_DATA.LEGACY_PIXEL_SCALE
	var rolling_terrain: float = sin((legacy_world_x + _city_seed * 8.0) * 0.00175) * 30.0 * hill_intensity * vertical_scale
	rolling_terrain += sin((legacy_world_x + _city_seed * 5.0) * 0.0056 + 0.8) * 21.0 * hill_intensity * vertical_scale
	rolling_terrain += sin((legacy_world_x + _city_seed * 13.0) * 0.00048) * 22.0 * hill_intensity * vertical_scale
	var pothole_offset: float = _route_pothole_offset(route_meter) * PIXELS_PER_METER
	return 526.0 + rolling_terrain + _route_elevation_offset(level_progress) + _challenge_jump_ramp_offset(route_meter) * PIXELS_PER_METER + _amsterdam_showcase_ramp_offset(route_meter) * PIXELS_PER_METER + _amsterdam_route_stunts_offset(route_meter) * PIXELS_PER_METER + _amsterdam_steel_bridge_offset(route_meter) * PIXELS_PER_METER + pothole_offset

func _route_pothole_offset(route_meter: float) -> float:
	if final_rescue_mode or active_world_index != 0:
		return 0.0
	var potholes: Array[float] = AMSTERDAM_POTHOLE_METERS
	var pit_radius_m: float = 2.1
	var pit_depth_m: float = 0.34
	for pothole_meter in potholes:
		var distance_m: float = absf(route_meter - pothole_meter)
		if distance_m < pit_radius_m:
			return pit_depth_m * (1.0 - smoothstep(0.0, pit_radius_m, distance_m))
	return 0.0

func _amsterdam_steel_bridge_offset(route_meter: float) -> float:
	if active_world_index != 0 or final_rescue_mode:
		return 0.0
	# The road climbs onto a short steel canal bridge and stays on its deck before
	# descending again. Drawing and collision read this exact height profile.
	const APPROACH_START_M: float = 350.0
	const DECK_START_M: float = 374.0
	const DECK_END_M: float = 448.0
	const EXIT_END_M: float = 472.0
	const DECK_RISE_M: float = -2.8
	if route_meter < APPROACH_START_M or route_meter >= EXIT_END_M:
		return 0.0
	if route_meter < DECK_START_M:
		return lerpf(0.0, DECK_RISE_M, smoothstep(APPROACH_START_M, DECK_START_M, route_meter))
	if route_meter <= DECK_END_M:
		return DECK_RISE_M
	return lerpf(DECK_RISE_M, 0.0, smoothstep(DECK_END_M, EXIT_END_M, route_meter))

func _amsterdam_showcase_ramp_offset(route_meter: float) -> float:
	if active_world_index != 0 or final_rescue_mode:
		return 0.0
	return _amsterdam_ramp_profile_offset(route_meter, _amsterdam_ramp_profile_for_event(512.0))

func _amsterdam_route_stunts_offset(route_meter: float) -> float:
	if active_world_index != 0 or final_rescue_mode:
		return 0.0
	var offset_m: float = 0.0
	# Every authored wooden ramp and the large Schanze share one profile source
	# with their collision height, so none of the visible road lifts can float.
	for profile in AMSTERDAM_RAMP_PROFILES:
		if is_equal_approx(float(profile["event_m"]), 512.0):
			continue
		offset_m += _amsterdam_ramp_profile_offset(route_meter, profile)
	return offset_m

func _amsterdam_ramp_profile_for_event(event_meter: float) -> Dictionary:
	for profile in AMSTERDAM_RAMP_PROFILES:
		if is_equal_approx(float(profile["event_m"]), event_meter):
			return profile
	return {}

func _amsterdam_ramp_profile_offset(route_meter: float, profile: Dictionary) -> float:
	if profile.is_empty():
		return 0.0
	var start_m: float = float(profile["start_m"])
	var lip_m: float = float(profile["lip_m"])
	var crest_end_m: float = float(profile["crest_end_m"])
	var end_m: float = float(profile["end_m"])
	var height_m: float = float(profile["height_m"])
	if route_meter < start_m or route_meter >= end_m:
		return 0.0
	if route_meter < lip_m:
		return lerpf(0.0, -height_m, smoothstep(start_m, lip_m, route_meter))
	if route_meter <= crest_end_m:
		return -height_m
	return lerpf(-height_m, 0.0, smoothstep(crest_end_m, end_m, route_meter))

func spawn_event_feedback(world_x: float, ground_y: float, kind: String, intensity: float = 1.0) -> void:
	var safe_intensity: float = clampf(intensity, 0.35, 1.5)
	var palette: Array[Color]
	var particle_count: int = 12
	var gravity: float = 410.0
	match kind:
		"zombie":
			palette = [Color8(138, 158, 116), Color8(88, 111, 86), Color8(190, 161, 114), Color8(219, 184, 133)]
			particle_count = 14
			gravity = 360.0
		"pickup":
			palette = [Color8(255, 224, 143), Color8(219, 163, 72), Color8(244, 197, 97)]
			particle_count = 11
			gravity = 185.0
		"boost":
			palette = [Color8(255, 220, 143), Color8(242, 133, 62), Color8(227, 82, 46)]
			particle_count = 9
			gravity = 170.0
		"weapon":
			palette = [Color8(255, 239, 176), Color8(251, 187, 78), Color8(226, 112, 49)]
			particle_count = 4
			gravity = 235.0
		"destruction":
			palette = [Color8(220, 171, 105), Color8(119, 135, 132), Color8(75, 88, 87), Color8(177, 93, 56)]
			particle_count = 28
			gravity = 560.0
		_:
			palette = [Color8(255, 218, 142), Color8(219, 141, 77), Color8(134, 126, 103), Color8(211, 194, 157)]
			particle_count = 20
			gravity = 460.0
	for particle_index in range(particle_count):
		var upward: float = randf_range(-1.0, -0.28)
		var horizontal: float = randf_range(-1.0, 0.8)
		var velocity := Vector2(horizontal, upward).normalized() * randf_range(80.0, 300.0 if kind != "destruction" else 430.0) * safe_intensity
		var lifetime: float = randf_range(0.22, 0.82 if kind == "destruction" else 0.68) * (1.1 if kind == "pickup" else 1.0)
		_event_particles.append({
			"position": Vector2(world_x + randf_range(-12.0, 12.0), ground_y - randf_range(14.0, 42.0)),
			"velocity": velocity,
			"life": lifetime,
			"life_total": lifetime,
			"color": palette[randi_range(0, palette.size() - 1)],
			"size": randf_range(2.0, 5.0) * safe_intensity,
			"rotation": randf_range(-PI, PI),
			"spin": randf_range(-8.0, 8.0),
			"gravity": gravity,
			"smoke": kind == "zombie" and particle_index % 4 == 0,
			"debris": kind == "destruction"
		})
	queue_redraw()

func begin_zombie_reaction(entity: Dictionary, attached_count: int = 0, impact_speed_mps: float = 0.0) -> void:
	# Keep the collision resolved while the draw path uses `reacting` to show
	# the short ragdoll. Reopening the event lets a slow car hit the same horde
	# every physics frame while it is crossing the contact window.
	var reaction_count: int = maxi(0, int(entity.get("group_size", 1)) - attached_count)
	entity["reaction_count"] = reaction_count
	entity["reaction_speed_mps"] = impact_speed_mps
	entity["reacting"] = reaction_count > 0
	entity["reaction_left"] = 1.3
	entity["reaction_total"] = 1.3
	queue_redraw()

func spawn_shot_zombie_reaction(world_x: float, ground_y: float, variant_id: int) -> void:
	# Keep each defeated member visible briefly while other members continue
	# charging toward the car.
	var safe_variant: int = clampi(variant_id, 1, 5)
	var image_height: float = float(ZOMBIE_DATA.profile(safe_variant).get("visual_height", 78.0))
	var texture: Texture2D = _zombie_texture(safe_variant)
	_shot_zombie_reactions.append({
		"position": Vector2(world_x, ground_y - image_height * 0.5),
		"velocity": Vector2(66.0, -55.0),
		"rotation": 0.0,
		"angular_velocity": -2.4,
		"life": 1.0,
		"life_total": 1.0,
		"variant_id": safe_variant,
		"ground_y": ground_y,
		"height": image_height,
		"width": image_height * texture.get_width() / maxf(1.0, float(texture.get_height()))
	})
	spawn_event_feedback(world_x, ground_y - 24.0, "zombie", 0.62)
	queue_redraw()

func set_zombie_chase_target_x(world_x: float, delta: float = 0.0) -> void:
	_zombie_chase_target_x = world_x
	if delta <= 0.0:
		return
	for entity in entities:
		if String(entity.get("kind", "")) != "zombie" or bool(entity.get("done", false)):
			continue
		var authored_x: float = float(entity["draw_world_x"]) if entity.has("draw_world_x") else route_meter_to_world_x(float(entity["meter"]))
		var chase_offset_px: float = float(entity.get("chase_offset_px", 0.0))
		var group_size: int = int(entity.get("group_size", 1))
		var group_spacing: float = float(entity.get("group_spacing_px", 62.4))
		var group_reach_px: float = float(maxi(0, group_size - 1)) * group_spacing * 0.5
		var contact_radius_px: float = float(entity.get("contact_radius_px", 39.0))
		var gap_px: float = authored_x - chase_offset_px - group_reach_px - contact_radius_px - world_x
		if gap_px <= 0.0 or gap_px > 92.0 * PIXELS_PER_METER:
			continue
		var proximity: float = clampf(1.0 - gap_px / (92.0 * PIXELS_PER_METER), 0.0, 1.0)
		var class_speed_mps: float = float(entity.get("chase_speed_mps", 9.0))
		var chase_speed_px_s: float = class_speed_mps * PIXELS_PER_METER * proximity * (0.35 + 0.65 * proximity)
		entity["chase_offset_px"] = minf(chase_offset_px + chase_speed_px_s * delta, chase_offset_px + gap_px)
		if chase_speed_px_s > 0.1:
			queue_redraw()

func _cache_world_height_parameters() -> void:
	# These values are constant throughout a route and height_at() also runs in
	# the physics loop. Resolve campaign data here instead of on every query.
	_campaign_difficulty = float(active_world_index) / maxf(1.0, float(CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() - 1))
	_city_seed = float(active_world_index) * 37.0
	_hill_theme_multiplier = 1.0
	var theme: String = String(active_world.get("theme", ""))
	if theme in ["mountain_tunnel", "tunnel_bridge", "coastal_tunnel", "calabria_coast", "genoa_hillside_port", "madrid_highway"]:
		_hill_theme_multiplier = 1.20
	elif theme in ["flooded_city", "venice_flood", "canals", "coastal_crossing", "naples_coast"]:
		_hill_theme_multiplier = 0.86
	elif theme in ["gravel_road", "arid_industrial"]:
		_hill_theme_multiplier = 1.08
	var route_id: String = String(active_world.get("id", ""))
	_route_elevation_profile = CAMPAIGN_DATA.ROUTE_ELEVATION_M.get(route_id, [])
	_challenge_jump_ramp_active = false
	if final_rescue_mode:
		_challenge_jump_ramp_active = String(CHALLENGE_DATA.RESCUE_CHALLENGE.get("kind", "")) == "clean_hazard"
	elif active_world_index >= 0 and active_world_index < CHALLENGE_DATA.WORLD_CHALLENGES.size():
		_challenge_jump_ramp_active = String(CHALLENGE_DATA.WORLD_CHALLENGES[active_world_index].get("kind", "")) == "clean_hazard"

func _challenge_jump_ramp_offset(route_meter: float) -> float:
	if not _challenge_jump_ramp_active:
		return 0.0
	# The road itself forms this launch ramp. A smooth 7 m crest and short
	# downslope give players a readable, repeatable jump before the authored
	# hazard; the rendered surface and collision use this same profile.
	var hazard_meter: float = route_length_m * 0.64
	var ramp_progress: float = route_meter - (hazard_meter - 52.0)
	if ramp_progress < 0.0 or ramp_progress >= 44.0:
		return 0.0
	if ramp_progress <= 30.0:
		return lerpf(0.0, -7.0, smoothstep(0.0, 30.0, ramp_progress))
	return lerpf(-7.0, 0.0, smoothstep(30.0, 44.0, ramp_progress))

func _route_elevation_offset(level_progress: float) -> float:
	if _route_elevation_profile.size() < 2:
		return 0.0
	var profile_position: float = clampf(level_progress, 0.0, 1.0) * float(_route_elevation_profile.size() - 1)
	var segment: int = mini(int(floor(profile_position)), _route_elevation_profile.size() - 2)
	var weight: float = profile_position - float(segment)
	# Smootherstep keeps both slope and curvature calm where profile sections join.
	weight = weight * weight * weight * (weight * (weight * 6.0 - 15.0) + 10.0)
	var elevation_m: float = lerpf(float(_route_elevation_profile[segment]), float(_route_elevation_profile[segment + 1]), weight)
	return elevation_m * PIXELS_PER_METER

func slope_at(world_x: float) -> float:
	var half_span: float = 4.0 * PIXELS_PER_METER
	return atan((height_at(world_x + half_span) - height_at(world_x - half_span)) / (half_span * 2.0))

func route_meter_to_world_x(route_meter: float) -> float:
	return (route_meter + START_OFFSET_M) * PIXELS_PER_METER

func configure_world(world_index: int) -> void:
	var next_world_index: int = clampi(world_index, 0, CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() - 1)
	if next_world_index == active_world_index and not final_rescue_mode:
		return
	final_rescue_mode = false
	active_world_index = next_world_index
	active_world = CAMPAIGN_DATA.CAMPAIGN_WORLDS[active_world_index]
	route_length_m = float(active_world.get("length_m", 1800.0))
	_cache_world_height_parameters()
	_build_road_collision()
	_build_entities()
	_rebuild_visual_cache()
	reset_entities(0.0)
	queue_redraw()

func configure_final_rescue(length: float) -> void:
	active_world_index = CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() - 1
	active_world = CAMPAIGN_DATA.CAMPAIGN_WORLDS[active_world_index]
	route_length_m = maxf(300.0, length)
	final_rescue_mode = true
	_cache_world_height_parameters()
	_build_road_collision()
	_build_entities()
	entities.append({"meter": route_length_m - 26.0, "kind": "rescue_ship", "done": false})
	_rebuild_visual_cache()
	reset_entities(0.0)
	queue_redraw()

func _rebuild_visual_cache() -> void:
	# Rendering samples use a fixed 22 px grid. Prepare the expensive terrain
	# function once per world; height_at() itself remains the source of truth for
	# vehicle physics and collision geometry.
	var world_width: float = WORLD_END_M * PIXELS_PER_METER
	var sample_count: int = int(ceil(world_width / DRAW_STEP)) + 2
	_draw_ground_heights.resize(sample_count)
	for sample_index in range(sample_count):
		_draw_ground_heights[sample_index] = height_at(float(sample_index) * DRAW_STEP)

	_roadside_ground_heights.clear()
	var post_spacing_px: float = ROAD_POST_SPACING_M * PIXELS_PER_METER
	var post_jitter_scale: float = PIXELS_PER_METER / CAMPAIGN_DATA.LEGACY_PIXEL_SCALE
	var last_cached_post: int = int(ceil(world_width / post_spacing_px)) + 1
	for post_index in range(last_cached_post + 1):
		var world_x: float = float(post_index) * post_spacing_px + float((post_index * 53) % 67) * post_jitter_scale
		_roadside_ground_heights[post_index] = height_at(world_x)

	for entity_index in range(entities.size()):
		var world_x: float = route_meter_to_world_x(float(entities[entity_index]["meter"]))
		entities[entity_index]["draw_world_x"] = world_x
		entities[entity_index]["draw_ground_y"] = height_at(world_x)

	_surface_palette = _world_surface_palette()

func _cached_draw_ground_height(world_x: float) -> float:
	var sample_index: int = int(round(world_x / DRAW_STEP))
	if sample_index >= 0 and sample_index < _draw_ground_heights.size():
		return float(_draw_ground_heights[sample_index])
	return height_at(world_x)

func reset_entities(from_meter: float) -> void:
	for entity in entities:
		entity["done"] = float(entity["meter"]) < from_meter - 1.0 or (String(entity.get("kind", "")) == "story_log" and not story_log_available)
		if String(entity.get("kind", "")) == "zombie":
			entity["chase_offset_px"] = 0.0
	queue_redraw()

func set_story_log_available(available: bool) -> void:
	story_log_available = available
	for entity in entities:
		if String(entity.get("kind", "")) == "story_log":
			entity["done"] = not available
	queue_redraw()

func _build_entities() -> void:
	entities.clear()
	for index in range(90):
		var world_seed: int = active_world_index * 17
		var meter: float = 78.0 + float(index) * 71.0 + float((index * 37 + world_seed) % 49)
		if meter >= route_length_m - 85.0:
			break
		var kind: String = "zombie"
		var seeded_index: int = index + active_world_index * 3
		if seeded_index % 11 == 2:
			kind = "fuel"
		elif seeded_index == 4 or (seeded_index > 0 and seeded_index % 17 == 0):
			kind = "nitro"
		elif seeded_index % 19 == 9:
			kind = "repair"
		elif seeded_index % 11 == 4:
			kind = "coins"
		elif seeded_index % 7 == 3:
			kind = "barrel"
		elif seeded_index % 11 == 8:
			kind = "wreck"
		var entity: Dictionary = {"meter": meter, "kind": kind, "done": false}
		if kind == "coins":
			entity["reward"] = 30
		elif kind == "fuel":
			entity["amount"] = 30.0 if active_world_index < 5 else 18.0
		elif kind == "nitro":
			entity["amount"] = 45.0
		elif kind == "repair":
			entity["amount"] = 30.0
		elif kind == "zombie":
			if String(active_world.get("id", "")) == "amsterdam":
				entity["group_size"] = 2 if posmod(int(meter / 210.0), 3) != 2 else 3
			else:
				entity["group_size"] = 1 if active_world_index < 5 else 2 if active_world_index < 14 else 2 + seeded_index % 3
			entity["reward"] = 9 + int(entity["group_size"]) * 2
		entities.append(entity)
	if String(active_world.get("id", "")) == "amsterdam":
		# The first route uses authored encounter rhythms: short zombie and
		# obstacle bursts, clear recovery gaps, then more demanding jump chains.
		# Replace the generic generated scatter so pickups never overlap hazards.
		entities.clear()
		var opening_encounters: Array[Dictionary] = [
			{"meter": 54.0, "kind": "zombie", "variant_id": 1, "group_size": 2, "reward": 13, "done": false},
			{"meter": 112.0, "kind": "coins", "reward": 24, "done": false},
			{"meter": 154.0, "kind": "zombie", "variant_id": 2, "group_size": 2, "reward": 13, "done": false},
			{"meter": 204.0, "kind": "setpiece", "hazard_kind": "timber_barrier", "hazard_label": "HOLZBARRIERE", "hit_width": 126.0, "hit_height": 62.0, "speed_retention": 0.82, "damage": 1.5, "break_reward": 14, "done": false},
			{"meter": 258.0, "kind": "launch_ramp", "style": "amsterdam_timber_ramp", "done": false},
			{"meter": 296.0, "kind": "nitro", "amount": 40.0, "done": false},
			{"meter": 338.0, "kind": "coins", "reward": 24, "done": false},
			{"meter": 362.0, "kind": "wreck", "done": false},
			{"meter": 421.0, "kind": "zombie", "variant_id": 2, "group_size": 3, "reward": 15, "done": false},
			{"meter": 452.0, "kind": "barrel", "done": false},
			{"meter": 478.0, "kind": "repair", "amount": 20.0, "done": false},
			{"meter": 512.0, "kind": "launch_ramp", "style": "amsterdam_timber_ramp", "done": false},
			{"meter": 531.0, "kind": "setpiece", "theme": "canals", "hazard_kind": "canal_debris", "hazard_label": "Grachtenbrücke", "speed_retention": 0.90, "damage": 0.0, "done": false},
			{"meter": 568.0, "kind": "zombie", "variant_id": 1, "group_size": 3, "reward": 15, "done": false},
			{"meter": 601.0, "kind": "fuel", "amount": 16.0, "done": false},
			{"meter": 628.0, "kind": "ramp_marker", "style": "amsterdam_timber_ramp", "done": false},
			{"meter": 648.0, "kind": "zombie", "variant_id": 1, "group_size": 2, "reward": 13, "done": false},
			{"meter": 683.0, "kind": "barrel", "done": false},
			{"meter": 704.0, "kind": "coins", "reward": 30, "done": false},
			{"meter": 728.0, "kind": "barrel", "done": false},
			{"meter": 738.0, "kind": "barrel", "done": false},
			{"meter": 748.0, "kind": "barrel", "done": false},
			{"meter": 778.0, "kind": "launch_ramp", "style": "amsterdam_timber_ramp", "done": false},
			{"meter": 818.0, "kind": "zombie", "variant_id": 1, "group_size": 3, "reward": 15, "done": false},
			{"meter": 858.0, "kind": "wreck", "done": false},
			{"meter": 872.0, "kind": "ramp_marker", "style": "amsterdam_timber_ramp", "done": false},
			{"meter": 902.0, "kind": "fuel", "amount": 18.0, "done": false},
			{"meter": 932.0, "kind": "zombie", "variant_id": 2, "group_size": 3, "reward": 15, "done": false},
			{"meter": 966.0, "kind": "barrel", "done": false},
			{"meter": 978.0, "kind": "barrel", "done": false},
			{"meter": 994.0, "kind": "repair", "amount": 20.0, "done": false},
			{"meter": 1046.0, "kind": "launch_ramp", "style": "amsterdam_schanze", "done": false},
			{"meter": 1120.0, "kind": "zombie", "variant_id": 1, "group_size": 4, "reward": 17, "done": false},
			{"meter": 1150.0, "kind": "nitro", "amount": 40.0, "done": false},
			{"meter": 1174.0, "kind": "wreck", "done": false},
			{"meter": 1192.0, "kind": "barrel", "done": false},
			{"meter": 1216.0, "kind": "zombie", "variant_id": 2, "group_size": 3, "reward": 15, "done": false},
			{"meter": 1252.0, "kind": "launch_ramp", "style": "amsterdam_timber_ramp", "done": false},
			{"meter": 1292.0, "kind": "coins", "reward": 30, "done": false},
			{"meter": 1328.0, "kind": "barrel", "done": false},
			{"meter": 1338.0, "kind": "barrel", "done": false},
			{"meter": 1364.0, "kind": "zombie", "variant_id": 1, "group_size": 4, "reward": 17, "done": false},
			{"meter": 1408.0, "kind": "wreck", "done": false},
			{"meter": 1456.0, "kind": "repair", "amount": 24.0, "done": false},
			{"meter": 1494.0, "kind": "zombie", "variant_id": 2, "group_size": 3, "reward": 15, "done": false},
			{"meter": 1514.0, "kind": "barrel", "done": false},
			{"meter": 1532.0, "kind": "fuel", "amount": 18.0, "done": false},
			{"meter": 1570.0, "kind": "launch_ramp", "style": "amsterdam_timber_ramp", "done": false},
			{"meter": 1608.0, "kind": "wreck", "done": false},
			{"meter": 1650.0, "kind": "zombie", "variant_id": 1, "group_size": 3, "reward": 15, "done": false},
			{"meter": 1692.0, "kind": "coins", "reward": 30, "done": false},
			{"meter": 1714.0, "kind": "barrel", "done": false},
			{"meter": 1734.0, "kind": "zombie", "variant_id": 2, "group_size": 4, "reward": 17, "done": false},
			{"meter": 1772.0, "kind": "barrel", "done": false}
		]
		entities.append_array(opening_encounters)
	# Verona's optional objective requires two kits; the shared spawn sequence yields one there.
	if String(active_world.get("id", "")) == "verona":
		entities.append({
			"meter": route_length_m * 0.43,
			"kind": "repair",
			"amount": 30.0,
			"done": false
		})
	if String(active_world.get("id", "")) == "reggio_calabria":
		entities.append({
			"meter": route_length_m * 0.90,
			"kind": "repair",
			"amount": 30.0,
			"done": false
		})
	var setpiece_meter: float = route_length_m * 0.64
	var setpiece_theme: String = String(active_world.get("theme", "urban"))
	if String(active_world.get("id", "")) == "amsterdam":
		# Amsterdam's first bridge encounter is part of the tuned preview opening.
		setpiece_meter = 531.0
	elif _challenge_jump_ramp_active:
		entities.append({"meter": setpiece_meter - 12.0, "kind": "launch_ramp", "done": false})
	if String(active_world.get("id", "")) != "amsterdam":
		var hazard: Dictionary = _setpiece_hazard_profile(setpiece_theme)
		entities.append({
			"meter": setpiece_meter,
			"kind": "setpiece",
			"theme": setpiece_theme,
			"hazard_kind": String(hazard["kind"]),
			"hazard_label": String(hazard["label"]),
			"speed_retention": float(hazard["speed_retention"]),
			"damage": float(hazard["damage"]),
			"done": false
		})
	entities.append({
		"meter": route_length_m * (0.48 if final_rescue_mode else 0.51),
		"kind": "story_log",
		"story_log_index": 0,
		"reward": 20,
		"done": not story_log_available
	})
	entities.append({"meter": route_length_m * 0.38, "kind": "checkpoint", "label": "VORRATSDEPOT", "done": false})
	entities.append({"meter": route_length_m * 0.72, "kind": "checkpoint", "label": "LETZTER KONTROLLPUNKT", "done": false})
	for entity in entities:
		if String(entity.get("kind", "")) != "zombie":
			continue
		var seeded_index: int = int(round(float(entity.get("meter", 0.0))))
		var world_id: String = String(active_world.get("id", ""))
		var default_variant: int = ZOMBIE_DATA.variant_for_world(world_id, active_world_index, seeded_index)
		var variant_id: int = int(entity.get("variant_id", default_variant))
		_apply_zombie_variant(entity, variant_id)

func _apply_zombie_variant(entity: Dictionary, variant_id: int) -> void:
	var safe_id: int = clampi(variant_id, 1, 5)
	var profile: Dictionary = ZOMBIE_DATA.profile(safe_id)
	entity["variant_id"] = safe_id
	entity["class"] = String(profile["class"])
	entity["damage"] = float(profile["hit_damage"])
	entity["speed_retention"] = float(profile["speed_retention"])
	entity["stop_duration"] = float(profile.get("stop_duration", 0.0))
	entity["visual_height_px"] = float(profile.get("visual_height", 78.0))
	entity["group_spacing_px"] = clampf(float(profile.get("visual_height", 78.0)) * 0.8, 56.0, 82.0)
	entity["contact_radius_px"] = float(profile.get("contact_radius_px", 39.0))
	entity["chase_speed_mps"] = float(profile.get("chase_speed_mps", 9.0))
	entity["minimum_charge"] = float(profile.get("minimum_charge", 0.2))
	entity["zombie_profile"] = profile

func _setpiece_hazard_profile(theme: String) -> Dictionary:
	var kind: String = "barrier"
	var label: String = "Straßensperre"
	var late_speed_retention: float = 0.62
	var base_damage: float = 9.0
	var world_id: String = String(active_world.get("id", ""))
	var authored_profile: Dictionary = CAMPAIGN_DATA.WORLD_SETPIECE_PROFILES.get(world_id, {})
	if not authored_profile.is_empty():
		kind = String(authored_profile.get("kind", kind))
		label = String(authored_profile.get("label", label))
		late_speed_retention = float(authored_profile.get("speed_retention", late_speed_retention))
		base_damage = float(authored_profile.get("damage", base_damage))
	if authored_profile.is_empty():
		if theme in ["canals", "flooded_city", "venice_flood", "coastal_crossing", "naples_coast"]:
			kind = "flood"
			label = "Überflutete Fahrbahn"
			late_speed_retention = 0.84
			base_damage = 0.0
		elif theme in ["gravel_road", "dry_coast", "arid_industrial", "calabria_coast"]:
			kind = "gravel"
			label = "Geröllfeld"
			late_speed_retention = 0.76
			base_damage = 4.0
		elif theme in ["mountain_tunnel", "tunnel_bridge", "coastal_tunnel"]:
			kind = "rockfall"
			label = "Steinschlag"
			late_speed_retention = 0.66
			base_damage = 8.0
		elif theme in ["overgrown_suburb", "barcelona_ruins", "paris_ruins", "rome_ruins", "verona_old_town", "florence_historic", "aircraft_industry", "madrid_highway", "milan_business", "bridge_suburb"]:
			kind = "rubble"
			label = "Trümmer auf der Straße"
			late_speed_retention = 0.70
			base_damage = 6.0
	var progression: float = clampf(float(active_world_index - 4) / 9.0, 0.0, 1.0)
	var speed_retention: float = lerpf(0.90, late_speed_retention, progression)
	var damage: float = base_damage * progression
	return {
		"kind": kind,
		"label": label,
		"speed_retention": speed_retention,
		"damage": damage
	}

func _draw() -> void:
	if not _first_draw_reported:
		_first_draw_reported = true
		if QA_DIAGNOSTICS.enabled():
			print("[PERF] terrain_first_draw_ms=%d" % Time.get_ticks_msec())
	var camera := get_viewport().get_camera_2d()
	var view_width: float = get_viewport_rect().size.x
	var center_x: float = camera.global_position.x if camera != null else 500.0
	var left: float = maxf(0.0, center_x - view_width * 0.95)
	var right: float = minf(WORLD_END_M * PIXELS_PER_METER, center_x + view_width * 1.05)
	var x: float = floor(left / DRAW_STEP) * DRAW_STEP
	var point_count: int = int(floor((right + DRAW_STEP - x) / DRAW_STEP)) + 1
	if point_count < 2:
		return
	_draw_road_points.resize(point_count)
	_draw_road_surface.resize(point_count * 2)
	_draw_road_surface_uvs.resize(point_count * 2)
	_draw_road_underside.resize(point_count)
	_draw_road_wear.resize(point_count)
	_draw_ground_fill.resize(point_count + 2)
	_draw_ground_uvs.resize(point_count + 2)
	_draw_verge_points.resize(point_count)
	for point_index in range(point_count):
		var point_x: float = x + float(point_index) * DRAW_STEP
		var ground_point := Vector2(point_x, _cached_draw_ground_height(point_x))
		_draw_road_points[point_index] = ground_point
		_draw_road_surface[point_index] = ground_point + Vector2(0.0, 2.0)
		_draw_road_surface[point_count * 2 - 1 - point_index] = ground_point + Vector2(0.0, ROAD_SURFACE_DEPTH)
		var cobble_size: Vector2 = AMSTERDAM_COBBLE_TILE.get_size()
		_draw_road_surface_uvs[point_index] = Vector2(point_x / cobble_size.x, (ground_point.y + 2.0) / cobble_size.y)
		_draw_road_surface_uvs[point_count * 2 - 1 - point_index] = Vector2(point_x / cobble_size.x, (ground_point.y + ROAD_SURFACE_DEPTH) / cobble_size.y)
		_draw_road_underside[point_index] = ground_point + Vector2(0.0, ROAD_SURFACE_DEPTH)
		_draw_road_wear[point_index] = ground_point + Vector2(0.0, 18.0)
		_draw_ground_fill[point_index] = ground_point
		_draw_verge_points[point_index] = ground_point + Vector2(0.0, 8.0)
	_draw_ground_fill[point_count] = Vector2(_draw_road_points[point_count - 1].x, 1100.0)
	_draw_ground_fill[point_count + 1] = Vector2(_draw_road_points[0].x, 1100.0)
	var palette: Dictionary = _surface_palette
	if active_world_index == 0 and not final_rescue_mode:
		var tile_size: Vector2 = AMSTERDAM_QUAY_BRICK_TILE.get_size()
		for uv_index in range(_draw_ground_fill.size()):
			var ground_point: Vector2 = _draw_ground_fill[uv_index]
			_draw_ground_uvs[uv_index] = Vector2(ground_point.x / tile_size.x, ground_point.y / tile_size.y)
		draw_colored_polygon(_draw_ground_fill, Color.WHITE, _draw_ground_uvs, AMSTERDAM_QUAY_BRICK_TILE)
	else:
		draw_colored_polygon(_draw_ground_fill, Color(palette["ground"]))
	_draw_rideable_construction_supports(left, right)
	_draw_amsterdam_structures(left, right)
	if active_world_index == 0 and not final_rescue_mode:
		draw_colored_polygon(_draw_road_surface, Color.WHITE, _draw_road_surface_uvs, AMSTERDAM_COBBLE_TILE)
	else:
		draw_colored_polygon(_draw_road_surface, Color(palette["road_face"]))
	_draw_rideable_construction_deck(left, right)
	draw_polyline(_draw_road_underside, Color(palette["road_shadow"]), 3.0, true)
	draw_polyline(_draw_road_wear, Color(palette["road_wear"]), 1.2, true)
	_draw_road_markings(left, right, palette)
	if active_world_index == 0 and not final_rescue_mode:
		_draw_route_potholes(left, right)
	draw_polyline(_draw_road_points, Color(palette["road_edge"]), 7.0, true)
	draw_polyline(_draw_verge_points, Color(palette["verge"]), 3.0, true)
	_draw_roadside(left, right)
	_draw_entities(left, right)
	_draw_shot_zombie_reactions()
	_draw_event_particles()

func _draw_amsterdam_structures(left: float, right: float) -> void:
	if active_world_index != 0 or final_rescue_mode:
		return
	_draw_amsterdam_canal_bridge(left, right)

func _draw_amsterdam_canal_bridge(left: float, right: float) -> void:
	# The bridge deck uses the same height chain as the road collision. These
	# girders and masonry piers make that drivable section read as a real structure.
	const BRIDGE_START_M: float = 350.0
	const DECK_START_M: float = 374.0
	const DECK_END_M: float = 448.0
	const BRIDGE_END_M: float = 472.0
	var start_x: float = route_meter_to_world_x(BRIDGE_START_M)
	var end_x: float = route_meter_to_world_x(BRIDGE_END_M)
	if end_x < left or start_x > right:
		return
	var deck_start_x: float = route_meter_to_world_x(DECK_START_M)
	var deck_end_x: float = route_meter_to_world_x(DECK_END_M)
	var beam_top := PackedVector2Array()
	var beam_bottom := PackedVector2Array()
	var sample_x: float = deck_start_x
	while sample_x <= deck_end_x + 1.0:
		var road_y: float = _cached_draw_ground_height(sample_x)
		beam_top.append(Vector2(sample_x, road_y + ROAD_SURFACE_DEPTH + 2.0))
		beam_bottom.append(Vector2(sample_x, road_y + ROAD_SURFACE_DEPTH + 27.0))
		sample_x += 36.0
	beam_top.append(Vector2(deck_end_x, _cached_draw_ground_height(deck_end_x) + ROAD_SURFACE_DEPTH + 2.0))
	beam_bottom.append(Vector2(deck_end_x, _cached_draw_ground_height(deck_end_x) + ROAD_SURFACE_DEPTH + 27.0))
	var girder := PackedVector2Array(beam_top)
	for index in range(beam_bottom.size() - 1, -1, -1):
		girder.append(beam_bottom[index])
	draw_colored_polygon(girder, Color8(47, 57, 56))
	draw_polyline(beam_top, Color8(173, 127, 78), 3.5, true)
	draw_polyline(beam_bottom, Color8(28, 39, 39), 3.0, true)
	# Short diagonal braces under the deck remain visible beneath the Kombi.
	var brace_x: float = deck_start_x + 24.0
	while brace_x < deck_end_x - 10.0:
		var brace_y: float = _cached_draw_ground_height(brace_x) + ROAD_SURFACE_DEPTH + 27.0
		draw_line(Vector2(brace_x - 12.0, brace_y - 1.0), Vector2(brace_x + 12.0, brace_y + 20.0), Color8(37, 48, 47), 5.0, true)
		draw_line(Vector2(brace_x - 11.0, brace_y), Vector2(brace_x + 12.0, brace_y + 20.0), Color8(145, 111, 73), 1.3, true)
		brace_x += 36.0
	# Three stone piers tie the elevated deck to the canal wall below it.
	for pier_meter in [382.0, 410.0, 438.0]:
		var pier_x: float = route_meter_to_world_x(pier_meter)
		if pier_x < left - 50.0 or pier_x > right + 50.0:
			continue
		var pier_top: float = _cached_draw_ground_height(pier_x) + ROAD_SURFACE_DEPTH + 23.0
		var pier_bottom: float = minf(pier_top + 168.0, 1088.0)
		draw_rect(Rect2(pier_x - 12.0, pier_top, 24.0, pier_bottom - pier_top), Color8(57, 63, 58))
		draw_rect(Rect2(pier_x - 8.0, pier_top + 4.0, 16.0, pier_bottom - pier_top - 8.0), Color8(116, 106, 84))
		var course_y: float = pier_top + 20.0
		while course_y < pier_bottom - 8.0:
			draw_line(Vector2(pier_x - 8.0, course_y), Vector2(pier_x + 8.0, course_y), Color8(64, 67, 57), 1.4, true)
			course_y += 24.0
	# Side railing and lamp posts trace the bridge approaches without obstructing
	# the road collision or hiding the car, which is drawn above this layer.
	var rail_top := PackedVector2Array()
	var rail_mid := PackedVector2Array()
	var rail_x: float = start_x
	while rail_x <= end_x + 1.0:
		var road_y: float = _cached_draw_ground_height(rail_x)
		rail_top.append(Vector2(rail_x, road_y - 28.0))
		rail_mid.append(Vector2(rail_x, road_y - 12.0))
		draw_line(Vector2(rail_x, road_y - 28.0), Vector2(rail_x, road_y + 2.0), Color8(42, 52, 50), 3.0, true)
		if int(round((rail_x - start_x) / (12.0 * PIXELS_PER_METER))) % 2 == 0:
			draw_circle(Vector2(rail_x, road_y - 32.0), 4.0, Color8(216, 169, 97))
		rail_x += 12.0 * PIXELS_PER_METER
	draw_polyline(rail_top, Color8(40, 51, 49), 4.0, true)
	draw_polyline(rail_mid, Color8(138, 124, 95), 2.0, true)

func _world_surface_palette() -> Dictionary:
	var palette: Dictionary = {
		"ground": Color8(55, 61, 48),
		"road_face": Color8(78, 81, 73),
		"road_shadow": Color8(31, 36, 33),
		"road_wear": Color8(126, 126, 111, 55),
		"lane_marking": Color8(219, 203, 165, 105),
		"road_edge": Color8(191, 158, 91),
		"verge": Color8(112, 116, 72)
	}
	match String(active_world.get("theme", "")):
		"container_port", "mediterranean_port", "genoa_hillside_port", "bari_port", "messina_evacuation_port":
			palette["ground"] = Color8(48, 58, 56)
			palette["road_face"] = Color8(70, 78, 76)
			palette["road_wear"] = Color8(150, 164, 153, 54)
			palette["lane_marking"] = Color8(207, 190, 149, 118)
			palette["road_edge"] = Color8(191, 157, 102)
			palette["verge"] = Color8(87, 112, 109)
		"flooded_city", "venice_flood", "canals", "coastal_crossing", "naples_coast":
			palette["ground"] = Color8(48, 59, 56)
			palette["road_face"] = Color8(67, 81, 80)
			palette["road_wear"] = Color8(163, 185, 178, 72)
			palette["lane_marking"] = Color8(215, 225, 205, 125)
			palette["road_edge"] = Color8(169, 183, 164)
			palette["verge"] = Color8(90, 120, 123)
		"dry_coast", "arid_industrial", "calabria_coast", "gravel_road", "madrid_highway":
			palette["ground"] = Color8(71, 58, 43)
			palette["road_face"] = Color8(89, 73, 54)
			palette["road_wear"] = Color8(191, 159, 110, 60)
			palette["lane_marking"] = Color8(225, 195, 140, 112)
			palette["road_edge"] = Color8(207, 166, 95)
			palette["verge"] = Color8(133, 109, 67)
		"mountain_tunnel", "coastal_tunnel", "tunnel_bridge", "genoa_hillside_port":
			palette["ground"] = Color8(47, 54, 51)
			palette["road_face"] = Color8(69, 74, 72)
			palette["road_wear"] = Color8(151, 158, 151, 60)
			palette["road_edge"] = Color8(174, 159, 125)
			palette["verge"] = Color8(83, 94, 83)
		"overgrown_suburb", "bridge_suburb", "verona_old_town", "florence_historic", "rome_ruins":
			palette["ground"] = Color8(53, 62, 48)
			palette["road_face"] = Color8(81, 81, 70)
			palette["road_wear"] = Color8(164, 155, 125, 61)
			palette["road_edge"] = Color8(176, 155, 103)
			palette["verge"] = Color8(88, 115, 73)
	return palette

func _draw_road_markings(left: float, right: float, palette: Dictionary) -> void:
	# Amsterdam uses close, readable markings and surface wear;
	# world-based placement prevents the road details from shimmering.
	var amsterdam_road: bool = active_world_index == 0
	var detailed_road: bool = amsterdam_road
	var mark_spacing_m: float = 7.2 if amsterdam_road else 54.5
	var mark_spacing_px: float = mark_spacing_m * PIXELS_PER_METER
	var physical_scale: float = PIXELS_PER_METER / CAMPAIGN_DATA.LEGACY_PIXEL_SCALE
	var first_mark: int = int(floor(left / mark_spacing_px)) - 1
	var last_mark: int = int(ceil(right / mark_spacing_px))
	var mark_color: Color = Color(palette["lane_marking"])
	for mark_index in range(first_mark, last_mark + 1):
		var mark_x: float = float(mark_index) * mark_spacing_px + (1.1 * PIXELS_PER_METER if amsterdam_road else 18.0 * physical_scale)
		var mark_y: float = _cached_draw_ground_height(mark_x)
		var dash_length: float = 2.15 * PIXELS_PER_METER if amsterdam_road else (24.0 + float(posmod(mark_index * 13, 3)) * 4.0) * physical_scale
		var end_y: float = _cached_draw_ground_height(mark_x + dash_length)
		var stripe_y: float = 18.0 if amsterdam_road else 11.0
		draw_line(Vector2(mark_x, mark_y + stripe_y), Vector2(mark_x + dash_length, end_y + stripe_y), mark_color, 3.0 if detailed_road else 2.0, true)
		if detailed_road:
			# Faded road paint and mismatched asphalt repairs add surface detail
			# without covering the car, pickups, or the actual collision profile.
			draw_line(Vector2(mark_x, mark_y + 5.0), Vector2(mark_x + dash_length, end_y + 5.0), Color8(204, 214, 193, 46), 1.0, true)
			var patch_stride: int = 3
			if posmod(mark_index, patch_stride) == 1:
				var patch_offset_m: float = 3.0
				var patch_width_m: float = 1.65
				var patch_x: float = mark_x + patch_offset_m * PIXELS_PER_METER
				var patch_width: float = patch_width_m * PIXELS_PER_METER
				var patch_y: float = _cached_draw_ground_height(patch_x)
				var patch_end_y: float = _cached_draw_ground_height(patch_x + patch_width)
				var patch := PackedVector2Array([
					Vector2(patch_x, patch_y + 8.0), Vector2(patch_x + patch_width, patch_end_y + 8.0),
					Vector2(patch_x + patch_width - 5.0, patch_end_y + 29.0), Vector2(patch_x + 3.0, patch_y + 29.0)
				])
				draw_colored_polygon(patch, Color8(39, 53, 52, 92))
				draw_polyline(PackedVector2Array([patch[0], patch[1]]), Color8(157, 172, 156, 45), 1.0, true)
			if amsterdam_road and posmod(mark_index, 5) == 2:
				var crack_x: float = mark_x + 4.9 * PIXELS_PER_METER
				var crack_y: float = _cached_draw_ground_height(crack_x)
				var crack_color := Color8(28, 38, 37, 150)
				draw_line(Vector2(crack_x, crack_y + 8.0), Vector2(crack_x + 8.0, crack_y + 14.0), crack_color, 1.4, true)
				draw_line(Vector2(crack_x + 8.0, crack_y + 14.0), Vector2(crack_x + 17.0, crack_y + 11.0), crack_color, 1.4, true)
		else:
			var crack_x: float = mark_x + 67.0 * physical_scale
			var crack_y: float = _cached_draw_ground_height(crack_x)
			var crack_color := Color8(35, 38, 34, 120)
			draw_line(Vector2(crack_x, crack_y + 24.0), Vector2(crack_x + 8.0, crack_y + 22.0), crack_color, 1.2, true)
			draw_line(Vector2(crack_x + 8.0, crack_y + 22.0), Vector2(crack_x + 15.0, crack_y + 26.0), crack_color, 1.2, true)

func _draw_route_potholes(left: float, right: float) -> void:
	var pothole_meters: Array[float] = AMSTERDAM_POTHOLE_METERS
	var radius_x: float = 1.7 * PIXELS_PER_METER
	for pothole_index in range(pothole_meters.size()):
		var center_x: float = route_meter_to_world_x(pothole_meters[pothole_index])
		if center_x < left - radius_x or center_x > right + radius_x:
			continue
		var chipped_rim: PackedVector2Array = PackedVector2Array()
		var dark_hole: PackedVector2Array = PackedVector2Array()
		for point_index in range(16):
			var angle: float = TAU * float(point_index) / 16.0
			var roughness: float = 1.0 + 0.10 * sin(angle * 3.0 + float(pothole_index)) + 0.05 * cos(angle * 5.0)
			var rim_dx: float = cos(angle) * radius_x * roughness
			var inner_dx: float = cos(angle) * radius_x * 0.76 * roughness
			var rim_ground: float = height_at(center_x + rim_dx)
			var inner_ground: float = height_at(center_x + inner_dx)
			chipped_rim.append(Vector2(center_x + rim_dx, rim_ground + 18.0 + sin(angle) * 12.0 * roughness))
			dark_hole.append(Vector2(center_x + inner_dx, inner_ground + 18.0 + sin(angle) * 8.5 * roughness))
		draw_colored_polygon(chipped_rim, Color8(36, 42, 40, 235))
		draw_colored_polygon(dark_hole, Color8(19, 26, 26, 250))
		for rim_index in range(1, 7):
			draw_line(chipped_rim[rim_index], chipped_rim[rim_index + 1], Color8(140, 133, 108, 165), 1.4, true)
		# Broken asphalt cracks radiate from the edges and stay on the road plane.
		for crack_side in [-1.0, 1.0]:
			var crack_x: float = center_x + crack_side * radius_x * 0.78
			var crack_y: float = height_at(crack_x) + 18.0
			draw_line(Vector2(crack_x, crack_y), Vector2(crack_x + crack_side * 13.0, crack_y - 3.0), Color8(24, 31, 30, 210), 1.8, true)
			draw_line(Vector2(crack_x + crack_side * 13.0, crack_y - 3.0), Vector2(crack_x + crack_side * 21.0, crack_y + 1.0), Color8(24, 31, 30, 180), 1.4, true)

func _draw_rideable_construction_supports(left: float, right: float) -> void:
	if final_rescue_mode or active_world_index != 0:
		return
	var start_meter: float = 362.0
	var end_meter: float = 466.0
	var support_spacing_m: float = 26.0
	var support_color: Color = Color8(70, 80, 75)
	var highlight_color: Color = Color8(154, 146, 120)
	var meter: float = start_meter
	while meter <= end_meter:
		var world_x: float = route_meter_to_world_x(meter)
		if world_x >= left - 80.0 and world_x <= right + 80.0:
			var road_y: float = height_at(world_x)
			var pier_top: float = road_y + ROAD_SURFACE_DEPTH - 1.0
			var pier_bottom: float = road_y + 145.0
			draw_rect(Rect2(world_x - 13.0, pier_top, 26.0, pier_bottom - pier_top), support_color)
			draw_line(Vector2(world_x - 13.0, pier_top), Vector2(world_x - 13.0, pier_bottom), highlight_color, 2.4, true)
			draw_line(Vector2(world_x + 13.0, pier_top), Vector2(world_x + 13.0, pier_bottom), Color8(31, 38, 36), 3.2, true)
			draw_line(Vector2(world_x - 12.0, pier_top + 12.0), Vector2(world_x + 12.0, pier_bottom - 12.0), Color8(38, 47, 44), 3.2, true)
			draw_line(Vector2(world_x + 12.0, pier_top + 12.0), Vector2(world_x - 12.0, pier_bottom - 12.0), highlight_color.darkened(0.28), 2.2, true)
			draw_rect(Rect2(world_x - 24.0, pier_bottom - 5.0, 48.0, 9.0), Color8(34, 42, 39))
			draw_line(Vector2(world_x - 24.0, pier_bottom - 5.0), Vector2(world_x + 24.0, pier_bottom - 5.0), highlight_color.darkened(0.18), 1.6, true)
		meter += support_spacing_m

func _draw_rideable_construction_deck(left: float, right: float) -> void:
	if final_rescue_mode or active_world_index != 0:
		return
	var start_meter: float = 350.0
	var end_meter: float = 472.0
	var accent: Color = Color8(189, 154, 97, 235)
	var plate: Color = Color8(51, 63, 60, 235)
	var meter: float = start_meter
	while meter < end_meter:
		var next_meter: float = minf(end_meter, meter + 7.0)
		var x1: float = route_meter_to_world_x(meter)
		var x2: float = route_meter_to_world_x(next_meter)
		if x2 >= left - 40.0 and x1 <= right + 40.0:
			var y1: float = height_at(x1)
			var y2: float = height_at(x2)
			var panel := PackedVector2Array([
				Vector2(x1, y1 + 4.0), Vector2(x2, y2 + 4.0),
				Vector2(x2, y2 + 17.0), Vector2(x1, y1 + 17.0)
			])
			draw_colored_polygon(panel, plate)
			draw_line(Vector2(x1, y1 + 4.0), Vector2(x2, y2 + 4.0), accent, 2.0, true)
			draw_line(Vector2(x1, y1 + 17.0), Vector2(x2, y2 + 17.0), Color8(30, 37, 35, 220), 1.5, true)
			draw_circle(Vector2(x1 + 7.0, y1 + 7.5), 1.5, accent)
		meter = next_meter

func _surface_color(progress: float, vienna: Color, plains: Color, border: Color, budapest: Color) -> Color:
	var toward_plains: float = smoothstep(0.22, 0.36, progress)
	var toward_border: float = smoothstep(0.45, 0.55, progress)
	var toward_budapest: float = smoothstep(0.72, 0.86, progress)
	return vienna.lerp(plains, toward_plains).lerp(border, toward_border).lerp(budapest, toward_budapest)

func _draw_roadside(left: float, right: float) -> void:
	var post_spacing_px: float = ROAD_POST_SPACING_M * PIXELS_PER_METER
	var post_jitter_scale: float = PIXELS_PER_METER / CAMPAIGN_DATA.LEGACY_PIXEL_SCALE
	var first_post: int = int(floor(left / post_spacing_px))
	var last_post: int = int(ceil(right / post_spacing_px))
	for post_index in range(first_post, last_post + 1):
		var world_x: float = float(post_index) * post_spacing_px + float((post_index * 53) % 67) * post_jitter_scale
		var ground: float = float(_roadside_ground_heights[post_index]) if _roadside_ground_heights.has(post_index) else height_at(world_x)
		var pebble_x: float = world_x + float((post_index * 29) % 31)
		draw_circle(Vector2(pebble_x, ground + 17.0), 2.0, Color8(112, 105, 78, 170))
		if post_index % 4 == 1:
			draw_line(Vector2(world_x + 18.0, ground - 4.0), Vector2(world_x + 18.0, ground - 32.0), Color8(111, 118, 96), 3.0)
			draw_circle(Vector2(world_x + 18.0, ground - 34.0), 3.0, Color8(223, 179, 93))

func _draw_entities(left: float, right: float) -> void:
	for entity in entities:
		var ramp_style: String = String(entity.get("style", ""))
		var keep_authored_ramp_visible: bool = ramp_style in ["amsterdam_schanze", "amsterdam_timber_ramp"]
		var ramp_profile: Dictionary = _amsterdam_ramp_profile_for_event(float(entity.get("meter", -9999.0))) if ramp_style == "amsterdam_timber_ramp" else {}
		if bool(entity["done"]) and not bool(entity.get("reacting", false)) and not keep_authored_ramp_visible:
			continue
		var world_x: float = float(entity["draw_world_x"]) if entity.has("draw_world_x") else route_meter_to_world_x(float(entity["meter"]))
		if String(entity["kind"]) == "zombie":
			world_x -= float(entity.get("chase_offset_px", 0.0))
		var entity_kind: String = String(entity["kind"])
		# A ramp is longer than the former 420 px draw window. Keep the whole
		# structure visible before approach and through its landing section.
		var entity_render_reach_px: float = 2400.0 if ramp_style == "amsterdam_schanze" else 2100.0 if ramp_style == "amsterdam_timber_ramp" else 70.0
		if world_x < left - entity_render_reach_px or world_x > right + entity_render_reach_px:
			continue
		var ground: float = height_at(world_x) if String(entity["kind"]) == "zombie" else float(entity["draw_ground_y"]) if entity.has("draw_ground_y") else height_at(world_x)
		if bool(entity.get("reacting", false)):
			var reaction_progress: float = 1.0 - float(entity["reaction_left"]) / maxf(0.01, float(entity["reaction_total"]))
			var reaction_count: int = int(entity.get("reaction_count", 1))
			for reaction_index in range(reaction_count):
				_draw_zombie_reaction(world_x, ground, reaction_progress, int(entity.get("variant_id", 1)), reaction_index, reaction_count, float(entity.get("reaction_speed_mps", 0.0)))
			continue
		match String(entity["kind"]):
			"zombie":
				var group_size: int = int(entity.get("group_size", 1))
				var zombie_class: String = String(entity.get("class", "slow"))
				var variant_id: int = int(entity.get("variant_id", 1))
				var distance_to_front_m: float = maxf(0.0, (world_x - _zombie_chase_target_x) / PIXELS_PER_METER)
				var charge: float = clampf(1.0 - distance_to_front_m / 92.0, 0.0, 1.0)
				charge = maxf(charge, float(entity.get("minimum_charge", 0.2)))
				var group_spacing: float = float(entity.get("group_spacing_px", 62.4))
				for zombie_index in range(group_size):
					var zombie_x: float = world_x + float(zombie_index) * group_spacing - float(group_size - 1) * group_spacing * 0.5
					_draw_zombie(zombie_x, height_at(zombie_x), variant_id, zombie_class, charge)
			"coins":
				_draw_coin_cache(world_x, ground)
			"fuel":
				_draw_fuel_can(world_x, ground)
			"nitro":
				_draw_nitro_canister(world_x, ground)
			"repair":
				_draw_repair_kit(world_x, ground)
			"barrel":
				_draw_barrel(world_x, ground)
			"wreck":
				_draw_wreck(world_x, ground)
			"setpiece":
				_draw_world_setpiece(world_x, ground, String(entity.get("hazard_kind", "barrier")))
			"launch_ramp":
				if String(entity.get("style", "")) == "amsterdam_schanze":
					_draw_amsterdam_schanze(world_x, ground)
				elif String(entity.get("style", "")) == "amsterdam_timber_ramp":
					_draw_amsterdam_timber_ramp(ramp_profile)
				else:
					_draw_launch_ramp(world_x, ground)
			"ramp_marker":
				if String(entity.get("style", "")) == "amsterdam_timber_ramp":
					_draw_amsterdam_timber_ramp(ramp_profile)
				else:
					_draw_launch_ramp(world_x, ground)
			"rescue_ship":
				_draw_rescue_ship_on_road(world_x, ground)
			"story_log":
				_draw_story_log(world_x, ground)
			"checkpoint":
				_draw_checkpoint(world_x, ground)

func _draw_zombie_reaction(world_x: float, ground: float, progress: float, variant: int, member_index: int, member_count: int, speed_mps: float) -> void:
	var motion: Vector3 = ZOMBIE_DATA.impact_pose(variant, speed_mps, progress, member_index, floori(world_x / PIXELS_PER_METER))
	var spread: float = (float(member_index) - float(member_count - 1) * 0.5) * 20.0
	var profile: Dictionary = ZOMBIE_DATA.profile(variant)
	var texture: Texture2D = _zombie_texture(variant)
	var image_height: float = float(profile.get("visual_height", 78.0))
	var image_size: Vector2 = texture.get_size()
	var image_width: float = image_height * image_size.x / maxf(1.0, image_size.y)
	var floor_extent: float = (absf(cos(motion.z)) * image_height + absf(sin(motion.z)) * image_width) * 0.46
	var impact := Vector2(world_x + spread + motion.x, ground - floor_extent - motion.y)
	draw_set_transform(impact, motion.z, Vector2.ONE)
	draw_texture_rect(texture, Rect2(Vector2(-image_width * 0.5, -image_height * 0.5), Vector2(image_width, image_height)), false, Color(1.0, 1.0, 1.0, 1.0 - smoothstep(0.76, 1.0, progress)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_shot_zombie_reactions() -> void:
	for reaction in _shot_zombie_reactions:
		var variant: int = clampi(int(reaction.get("variant_id", 1)), 1, 5)
		var texture: Texture2D = _zombie_texture(variant)
		var profile: Dictionary = ZOMBIE_DATA.profile(variant)
		var image_height: float = float(profile.get("visual_height", 78.0))
		var image_width: float = image_height * texture.get_width() / maxf(1.0, float(texture.get_height()))
		var life: float = float(reaction.get("life", 0.0))
		var fade: float = smoothstep(0.0, 0.24, life)
		draw_set_transform(Vector2(reaction.get("position", Vector2.ZERO)), float(reaction.get("rotation", 0.0)), Vector2.ONE)
		draw_texture_rect(texture, Rect2(Vector2(-image_width * 0.5, -image_height * 0.5), Vector2(image_width, image_height)), false, Color(1.0, 1.0, 1.0, fade))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_event_particles() -> void:
	for particle in _event_particles:
		var position: Vector2 = Vector2(particle["position"])
		var velocity: Vector2 = Vector2(particle["velocity"])
		var fade: float = clampf(float(particle["life"]) / maxf(0.01, float(particle["life_total"])), 0.0, 1.0)
		var color: Color = Color(particle["color"])
		color.a *= fade
		var size: float = float(particle["size"])
		if bool(particle.get("smoke", false)):
			draw_circle(position, size * (1.7 - fade * 0.45), Color(color.r, color.g, color.b, color.a * 0.35))
		elif bool(particle.get("debris", false)):
			var chip_axis := Vector2(size * 1.4, 0.0).rotated(float(particle.get("rotation", 0.0)))
			var chip_cross := Vector2(0.0, size * 0.65).rotated(float(particle.get("rotation", 0.0)))
			draw_colored_polygon(PackedVector2Array([
				position - chip_axis - chip_cross,
				position + chip_axis - chip_cross * 0.6,
				position + chip_axis * 0.65 + chip_cross,
				position - chip_axis * 0.8 + chip_cross * 0.45
			]), color)
		else:
			var direction: Vector2 = velocity.normalized()
			draw_line(position, position - direction * size * 2.8, color, maxf(1.2, size * 0.65), true)

func _draw_launch_ramp(world_x: float, ground: float) -> void:
	# Reflective arrows make the real raised road profile visible before the jump.
	for marker_index in range(3):
		var marker_x: float = world_x - 28.0 + float(marker_index) * 26.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(marker_x - 8.0, ground + 3.0),
			Vector2(marker_x + 4.0, ground - 6.0),
			Vector2(marker_x + 8.0, ground - 3.0),
			Vector2(marker_x - 4.0, ground + 6.0)
		]), Color8(214, 171, 96, 220))
	for side in [-1.0, 1.0]:
		var flag_x: float = world_x + side * 48.0
		draw_line(Vector2(flag_x, ground - 2.0), Vector2(flag_x, ground - 30.0), Color8(79, 88, 73), 2.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(flag_x, ground - 29.0),
			Vector2(flag_x + 12.0, ground - 25.0),
			Vector2(flag_x, ground - 21.0)
		]), Color8(193, 112, 72))

func _draw_amsterdam_timber_ramp(profile: Dictionary) -> void:
	# The timber deck follows the same height function as the physical road. This
	# keeps its visible edge attached during both the climb and the run-out.
	if profile.is_empty():
		return
	var start_x: float = route_meter_to_world_x(float(profile["start_m"]))
	var lip_x: float = route_meter_to_world_x(float(profile["lip_m"]))
	var end_x: float = route_meter_to_world_x(float(profile["end_m"]))
	var top_points := PackedVector2Array()
	var sample_count: int = clampi(int(ceil((end_x - start_x) / (4.0 * PIXELS_PER_METER))), 10, 24)
	for sample_index in range(sample_count + 1):
		var sample_x: float = lerpf(start_x, end_x, float(sample_index) / float(sample_count))
		top_points.append(Vector2(sample_x, _cached_draw_ground_height(sample_x)))
	var ramp_body := PackedVector2Array(top_points)
	for sample_index in range(top_points.size() - 1, -1, -1):
		ramp_body.append(top_points[sample_index] + Vector2(0.0, 34.0))
	draw_colored_polygon(ramp_body, Color8(83, 63, 43, 248))
	# Side stringers and triangular supports keep the structure visibly raised
	# even where the roadway itself climbs over the canal edge.
	draw_polyline(top_points, Color8(40, 43, 39), 14.0, true)
	draw_polyline(top_points, Color8(157, 107, 59), 10.0, true)
	draw_polyline(top_points, Color8(230, 184, 115), 2.0, true)
	var support_count: int = clampi(int(ceil((end_x - start_x) / (7.5 * PIXELS_PER_METER))), 4, 12)
	for support_index in range(1, support_count):
		var progress: float = float(support_index) / float(support_count)
		var support_x: float = lerpf(start_x, end_x, progress)
		var support_y: float = _cached_draw_ground_height(support_x)
		var foot_y: float = support_y + 58.0
		draw_line(Vector2(support_x - 9.0, support_y + 8.0), Vector2(support_x - 18.0, foot_y), Color8(43, 44, 39), 8.0, true)
		draw_line(Vector2(support_x + 8.0, support_y + 8.0), Vector2(support_x + 18.0, foot_y), Color8(43, 44, 39), 8.0, true)
		draw_line(Vector2(support_x - 16.0, foot_y - 3.0), Vector2(support_x + 15.0, foot_y - 3.0), Color8(111, 82, 51), 5.0, true)
		draw_line(Vector2(support_x - 8.0, support_y + 19.0), Vector2(support_x + 11.0, foot_y - 11.0), Color8(180, 131, 76), 3.0, true)
	# Crosswise boards and dark seams give the top a clear wooden surface.
	var plank_count: int = clampi(int(ceil((end_x - start_x) / (1.7 * PIXELS_PER_METER))), 8, 30)
	for plank_index in range(plank_count):
		var plank_x: float = lerpf(start_x + 3.0, end_x - 3.0, float(plank_index) / float(plank_count - 1))
		var plank_y: float = _cached_draw_ground_height(plank_x)
		var plank_color: Color = Color8(151, 105, 59) if plank_index % 2 == 0 else Color8(181, 129, 73)
		draw_line(Vector2(plank_x, plank_y - 4.0), Vector2(plank_x, plank_y + 8.0), Color8(65, 53, 42), 3.0, true)
		draw_line(Vector2(plank_x - 3.0, plank_y - 2.0), Vector2(plank_x - 3.0, plank_y + 5.0), plank_color, 1.3, true)
	# Painted lip marks remain visible when the vehicle is on the incline.
	var lip_y: float = _cached_draw_ground_height(lip_x)
	for stripe_index in range(6):
		var stripe_x: float = lip_x - 24.0 + float(stripe_index) * 9.0
		var stripe_color: Color = Color8(222, 185, 116) if stripe_index % 2 == 0 else Color8(53, 58, 51)
		draw_line(Vector2(stripe_x - 4.0, lip_y - 1.0), Vector2(stripe_x + 4.0, lip_y + 7.0), stripe_color, 5.0, true)

func _draw_timber_barrier(world_x: float, ground: float) -> void:
	# Cross-braced wooden roadworks sawhorse, with a red and cream warning board.
	for stand_x in [world_x - 43.0, world_x + 43.0]:
		var foot_left := Vector2(stand_x - 18.0, ground - 2.0)
		var foot_right := Vector2(stand_x + 18.0, ground - 2.0)
		var top := Vector2(stand_x, ground - 41.0)
		draw_line(foot_left, top, Color8(45, 42, 36), 9.0, true)
		draw_line(foot_right, top, Color8(45, 42, 36), 9.0, true)
		draw_line(foot_left, top, Color8(151, 103, 59), 5.0, true)
		draw_line(foot_right, top, Color8(174, 123, 70), 5.0, true)
		draw_line(Vector2(stand_x - 11.0, ground - 20.0), Vector2(stand_x + 12.0, ground - 5.0), Color8(89, 67, 45), 4.0, true)
	draw_rect(Rect2(world_x - 67.0, ground - 39.0, 134.0, 19.0), Color8(48, 43, 37))
	draw_rect(Rect2(world_x - 64.0, ground - 37.0, 128.0, 15.0), Color8(211, 185, 135))
	for stripe_index in range(9):
		var stripe_x: float = world_x - 58.0 + float(stripe_index) * 15.0
		var stripe_color: Color = Color8(172, 69, 49) if stripe_index % 2 == 0 else Color8(240, 220, 173)
		draw_line(Vector2(stripe_x - 4.0, ground - 37.0), Vector2(stripe_x + 4.0, ground - 22.0), stripe_color, 7.0, true)
	draw_line(Vector2(world_x - 64.0, ground - 36.0), Vector2(world_x + 64.0, ground - 36.0), Color8(240, 211, 157), 1.5, true)
	for bolt_x in [world_x - 57.0, world_x + 57.0]:
		draw_circle(Vector2(bolt_x, ground - 29.0), 2.4, Color8(53, 51, 45))

func _draw_amsterdam_schanze(lip_x: float, lip_y: float) -> void:
	# A built-up launch mound gives the route one unmistakable ski-jump beat.
	# Its top follows height_at(), the same profile used for road collision.
	var start_x: float = route_meter_to_world_x(1024.0)
	var landing_x: float = route_meter_to_world_x(1084.0)
	var start_y: float = _cached_draw_ground_height(start_x)
	var landing_y: float = _cached_draw_ground_height(landing_x)
	var support_drop: float = 76.0
	var schanze_body := PackedVector2Array([
		Vector2(start_x, start_y + 4.0), Vector2(lip_x, lip_y + 4.0), Vector2(landing_x, landing_y + 4.0),
		Vector2(landing_x, landing_y + support_drop), Vector2(lip_x, lip_y + support_drop + 10.0),
		Vector2(start_x, start_y + support_drop)
	])
	draw_colored_polygon(schanze_body, Color8(63, 68, 61))
	draw_polyline(PackedVector2Array([
		Vector2(start_x, start_y + 5.0), Vector2(lip_x, lip_y + 5.0), Vector2(landing_x, landing_y + 5.0)
	]), Color8(24, 31, 30), 10.0, true)
	draw_polyline(PackedVector2Array([
		Vector2(start_x, start_y + 5.0), Vector2(lip_x, lip_y + 5.0), Vector2(landing_x, landing_y + 5.0)
	]), Color8(230, 187, 103), 6.0, true)
	draw_polyline(PackedVector2Array([
		Vector2(start_x, start_y + 8.0), Vector2(lip_x, lip_y + 8.0), Vector2(landing_x, landing_y + 8.0)
	]), Color8(248, 219, 152, 180), 1.8, true)
	draw_polyline(PackedVector2Array([
		Vector2(start_x, start_y + 31.0), Vector2(lip_x, lip_y + 41.0), Vector2(landing_x, landing_y + 31.0)
	]), Color8(35, 43, 42), 4.0, true)
	for brace_index in range(1, 8):
		var progress: float = float(brace_index) / 8.0
		var brace_x: float = lerpf(start_x, landing_x, progress)
		var brace_y: float = _cached_draw_ground_height(brace_x)
		draw_line(Vector2(brace_x, brace_y + 12.0), Vector2(brace_x - 4.0, brace_y + 66.0), Color8(37, 45, 43), 5.0, true)
		draw_line(Vector2(brace_x - 4.0, brace_y + 64.0), Vector2(brace_x + 18.0, brace_y + 74.0), Color8(112, 121, 104), 2.0, true)
	for stripe_index in range(1, 7):
		var stripe_x: float = lerpf(start_x, lip_x, float(stripe_index) / 7.0)
		var stripe_y: float = _cached_draw_ground_height(stripe_x)
		var stripe_color: Color = Color8(222, 180, 99, 190) if stripe_index % 2 == 0 else Color8(72, 81, 74, 215)
		draw_line(Vector2(stripe_x - 4.0, stripe_y + 5.0), Vector2(stripe_x - 9.0, stripe_y + 29.0), stripe_color, 8.0, true)
		draw_line(Vector2(stripe_x - 9.0, stripe_y + 29.0), Vector2(stripe_x + 3.0, stripe_y + 24.0), stripe_color, 5.0, true)
	for side in [-1.0, 1.0]:
		var flag_x: float = lip_x + side * 62.0
		draw_line(Vector2(flag_x, lip_y - 1.0), Vector2(flag_x, lip_y - 55.0), Color8(49, 60, 56), 3.0, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(flag_x, lip_y - 54.0), Vector2(flag_x + 25.0, lip_y - 45.0),
			Vector2(flag_x, lip_y - 35.0)
		]), Color8(205, 103, 63))

func _zombie_texture(variant_id: int) -> Texture2D:
	match clampi(variant_id, 1, 5):
		2:
			return ZOMBIE_RUNNER_TEXTURE
		3:
			return ZOMBIE_WORKER_TEXTURE
		4:
			return ZOMBIE_RIOT_TEXTURE
		5:
			return ZOMBIE_BRUTE_TEXTURE
		_:
			return ZOMBIE_NORMAL_TEXTURE

func _draw_zombie(world_x: float, ground: float, variant: int, zombie_class: String = "slow", approach: float = 0.0) -> void:
	var variant_id: int = clampi(variant, 1, 5)
	var profile: Dictionary = ZOMBIE_DATA.profile(variant_id)
	var texture: Texture2D = ZOMBIE_NORMAL_RUN_TEXTURE if variant_id == 1 else _zombie_texture(variant_id)
	var image_height: float = float(profile.get("visual_height", 78.0))
	var charge: float = clampf(approach, 0.0, 1.0)
	var gait_rate: float = 0.008 if zombie_class != "fast" else 0.012
	var phase: float = float(Time.get_ticks_msec()) * gait_rate + sin(world_x * 0.001) * 0.4
	var gait: Dictionary = ZOMBIE_DATA.walk_motion(phase, charge)
	var bob: float = float(gait["bob"])
	var lean: float = -charge * 0.055 + float(gait["body_roll"]) * 0.5
	var squash: float = float(gait["squash"])
	var frame_source: Rect2 = Rect2(Vector2.ZERO, texture.get_size())
	if variant_id == 1:
		var frame_index: int = posmod(int(floor(fposmod(phase, TAU) / TAU * float(ZOMBIE_NORMAL_RUN_FRAMES.size()))), ZOMBIE_NORMAL_RUN_FRAMES.size())
		frame_source = ZOMBIE_NORMAL_RUN_FRAMES[frame_index]
	elif variant_id == 2:
		texture = ZOMBIE_DATA.RUNNER_CHARGE_TEXTURE
		frame_source = ZOMBIE_DATA.runner_charge_frame(floori(phase / TAU * 4.0))
	elif variant_id >= 3:
		texture = ZOMBIE_DATA.HEAVY_WALK_TEXTURES[variant_id]
		frame_source = ZOMBIE_DATA.heavy_walk_frame(variant_id, floori(phase / TAU * 4.0))
		image_height *= ZOMBIE_DATA.heavy_frame_height_scale(variant_id, frame_source)
	var image_width: float = image_height * frame_source.size.x / maxf(1.0, frame_source.size.y)
	draw_set_transform(Vector2(world_x - charge * 4.0, ground - bob), lean, Vector2(1.0 + squash, 1.0 - squash * 0.6))
	draw_texture_rect_region(texture, Rect2(Vector2(-image_width * 0.5 - 0.9, -image_height), Vector2(image_width, image_height)), frame_source, Color8(23, 23, 20, 175))
	draw_texture_rect_region(texture, Rect2(Vector2(-image_width * 0.5, -image_height), Vector2(image_width, image_height)), frame_source)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_zombie_procedural(world_x: float, ground: float, variant: int, zombie_class: String = "slow", approach: float = 0.0) -> void:
	var safe_variant: int = posmod(variant, 3)
	var is_fast: bool = zombie_class == "fast"
	var is_robust: bool = zombie_class == "robust"
	var charge: float = clampf(approach, 0.0, 1.0)
	var height_scale: float = 1.30 if is_robust else 1.16 if is_fast else 1.10
	var run_rate: float = lerpf(0.008, 0.026, charge)
	if is_fast:
		run_rate = maxf(run_rate, 0.020)
	var phase: float = float(Time.get_ticks_msec()) * run_rate + world_x * 0.012 + float(safe_variant) * 1.3
	var stride: float = sin(phase) * lerpf(5.0, 16.0, charge)
	var arm_swing: float = cos(phase) * lerpf(3.0, 13.5, charge)
	var bob: float = absf(sin(phase)) * lerpf(1.2, 5.0, charge)
	var lean: float = -charge * 11.0 + (-2.0 if is_robust else 0.0)
	var shoulder_width: float = 13.0 if is_robust else 9.6 if is_fast else 10.5
	var skin_palette: Array[Color] = [Color8(125, 151, 111), Color8(170, 146, 99), Color8(120, 144, 126)]
	var shirt_palette: Array[Color] = [Color8(82, 100, 69), Color8(125, 83, 57), Color8(78, 79, 68)]
	var fast_skin_palette: Array[Color] = [Color8(177, 119, 88), Color8(192, 146, 87), Color8(140, 100, 131)]
	var fast_shirt_palette: Array[Color] = [Color8(151, 73, 52), Color8(151, 102, 49), Color8(110, 60, 77)]
	var pants_palette: Array[Color] = [Color8(54, 61, 49), Color8(68, 56, 48), Color8(48, 56, 52)]
	var skin: Color = skin_palette[safe_variant]
	var shirt: Color = shirt_palette[safe_variant]
	if is_fast:
		skin = fast_skin_palette[safe_variant]
		shirt = fast_shirt_palette[safe_variant]
	elif is_robust:
		skin = Color8(99, 122, 91)
		shirt = Color8(65, 78, 62)
	var pants: Color = pants_palette[safe_variant]
	var torso_top_y: float = -35.0 + bob
	var hip_y: float = -15.0 + bob
	var body_angle: float = -0.035 - charge * 0.27 + (0.025 if is_robust else 0.0)
	draw_set_transform(Vector2(world_x + lean, ground), body_angle, Vector2(height_scale, height_scale))
	draw_circle(Vector2(0.0, 3.0), 10.0 if is_robust else 8.0, Color8(25, 30, 27, 90))
	if charge > 0.28:
		var dust_alpha: int = int(round(44.0 + charge * 64.0))
		for puff_index in range(2):
			var puff_phase: float = fposmod(phase * 0.24 + float(puff_index) * 0.52, 1.0)
			var puff_x: float = 10.0 + float(puff_index) * 6.0 + puff_phase * 4.0
			draw_circle(Vector2(puff_x, 0.0), 2.5 + puff_phase * 2.2, Color8(126, 105, 75, int(dust_alpha * (1.0 - puff_phase * 0.35))))

	# Heavy boots and bent knees give the three enemy classes a readable gait.
	var left_hip := Vector2(-4.0, hip_y)
	var right_hip := Vector2(4.0, hip_y)
	var left_knee := left_hip + Vector2(-3.0 + stride * 0.34, 8.0)
	var right_knee := right_hip + Vector2(3.0 - stride * 0.34, 8.0)
	var left_foot := left_hip + Vector2(-6.0 + stride, 15.0 + bob)
	var right_foot := right_hip + Vector2(6.0 - stride, 15.0 + bob)
	var leg_width: float = 7.0 if is_robust else 4.7 if is_fast else 5.5
	var ink: Color = Color8(28, 31, 28)
	draw_line(left_hip, left_knee, ink, leg_width + 2.4, true)
	draw_line(left_knee, left_foot, ink, leg_width + 2.4, true)
	draw_line(right_hip, right_knee, ink, leg_width + 2.4, true)
	draw_line(right_knee, right_foot, ink, leg_width + 2.4, true)
	draw_line(left_hip, left_knee, pants, leg_width)
	draw_line(left_knee, left_foot, pants, leg_width - 0.8)
	draw_line(right_hip, right_knee, pants.darkened(0.16), leg_width)
	draw_line(right_knee, right_foot, pants.darkened(0.16), leg_width - 0.8)
	draw_circle(left_knee, leg_width * 0.44, pants.lightened(0.08))
	draw_circle(right_knee, leg_width * 0.44, pants.darkened(0.08))
	draw_line(left_foot, left_foot + Vector2(5.0, -1.0), Color8(35, 39, 34), leg_width * 0.72)
	draw_line(right_foot, right_foot + Vector2(5.0, -1.0), Color8(35, 39, 34), leg_width * 0.72)

	# A torn jacket/vest silhouette replaces the old single stick torso.
	var shoulder_y: float = torso_top_y + 5.0
	var torso_points := PackedVector2Array([
		Vector2(-shoulder_width, shoulder_y + 2.0), Vector2(-shoulder_width * 0.72, torso_top_y),
		Vector2(shoulder_width * 0.72, torso_top_y), Vector2(shoulder_width, shoulder_y + 2.0),
		Vector2(6.0, hip_y + 2.0), Vector2(2.0, hip_y - 1.0), Vector2(-2.0, hip_y + 2.0),
		Vector2(-6.0, hip_y - 1.0)
	])
	draw_colored_polygon(torso_points, shirt)
	var torso_outline: PackedVector2Array = torso_points.duplicate()
	torso_outline.append(torso_points[0])
	draw_polyline(torso_outline, ink, 2.7, true)
	draw_polyline(PackedVector2Array([torso_points[0], torso_points[1], torso_points[2], torso_points[3]]), shirt.lightened(0.22), 1.7, true)
	draw_line(Vector2(0.0, torso_top_y + 4.0), Vector2(1.0, hip_y - 3.0), shirt.darkened(0.3), 1.2)
	draw_line(Vector2(-4.0, hip_y - 3.0), Vector2(-1.0, hip_y - 1.0), Color8(190, 164, 105), 1.5)
	if is_robust:
		# The late-game bruiser wears a broad chest guard and shoulder plates.
		draw_colored_polygon(PackedVector2Array([
			Vector2(-shoulder_width + 1.0, torso_top_y + 5.0), Vector2(0.0, torso_top_y + 8.0),
			Vector2(shoulder_width - 1.0, torso_top_y + 5.0), Vector2(6.0, hip_y - 2.0),
			Vector2(-6.0, hip_y - 2.0)
		]), Color8(86, 96, 76))
		draw_line(Vector2(-shoulder_width + 2.0, torso_top_y + 5.0), Vector2(-shoulder_width - 2.0, torso_top_y + 10.0), Color8(125, 135, 101), 4.0)
		draw_line(Vector2(shoulder_width - 2.0, torso_top_y + 5.0), Vector2(shoulder_width + 2.0, torso_top_y + 10.0), Color8(125, 135, 101), 4.0)
	else:
		# Ragged cloth strips flick with the run cycle without adding physics objects.
		var cloth_sway: float = arm_swing * 0.2
		draw_line(Vector2(-5.0, hip_y), Vector2(-8.0 + cloth_sway, hip_y + 8.0), shirt.lightened(0.12), 2.0)
		draw_line(Vector2(3.0, hip_y), Vector2(6.0 - cloth_sway, hip_y + 6.0), shirt.darkened(0.15), 2.0)

	# Extended arms reach toward the road, with visible elbows, wrists and hands.
	var left_shoulder := Vector2(-shoulder_width + 1.0, shoulder_y + 1.0)
	var right_shoulder := Vector2(shoulder_width - 1.0, shoulder_y + 1.0)
	var arm_reach: float = lerpf(1.0, 17.0, charge)
	var left_elbow := left_shoulder + Vector2(-arm_reach - arm_swing * 0.24, 5.0 + charge * 2.0)
	var right_elbow := right_shoulder + Vector2(4.0 + arm_swing * 0.34, 6.5)
	var left_hand := left_elbow + Vector2(-5.0 - arm_swing * 0.32, 3.0)
	var right_hand := right_elbow + Vector2(5.0 + arm_swing * 0.46, 5.0)
	var arm_width: float = 6.0 if is_robust else 3.8
	draw_line(left_shoulder, left_elbow, ink, arm_width + 3.2, true)
	draw_line(right_shoulder, right_elbow, ink, arm_width + 3.2, true)
	draw_line(left_elbow, left_hand, ink, arm_width + 2.4, true)
	draw_line(right_elbow, right_hand, ink, arm_width + 2.4, true)
	draw_line(left_shoulder, left_elbow, shirt, arm_width + 1.0)
	draw_line(right_shoulder, right_elbow, shirt.darkened(0.12), arm_width + 1.0)
	draw_line(left_elbow, left_hand, skin, arm_width * 0.72)
	draw_line(right_elbow, right_hand, skin.darkened(0.08), arm_width * 0.72)
	draw_circle(left_elbow, arm_width * 0.4, skin)
	draw_circle(right_elbow, arm_width * 0.4, skin.darkened(0.08))
	draw_circle(left_hand, 3.1, skin)
	draw_circle(right_hand, 3.1, skin.darkened(0.08))
	for finger_index in range(2):
		var finger_offset: float = float(finger_index) * 2.0
		draw_line(left_hand + Vector2(-1.0, finger_offset), left_hand + Vector2(2.0, 3.0 + finger_offset), skin, 1.1)
		draw_line(right_hand + Vector2(1.0, finger_offset), right_hand + Vector2(4.0, 3.0 + finger_offset), skin, 1.1)

	# Face, torn hair and exposed jaw stay visible at the game's small road scale.
	var neck := Vector2(0.0, torso_top_y + 2.0)
	var head := Vector2(2.0, torso_top_y - 7.0)
	draw_line(neck, head + Vector2(0.0, 5.0), skin.darkened(0.35), 4.0)
	var head_radius: float = 7.2 if is_fast else 8.2 if is_robust else 7.6
	draw_circle(head, head_radius + 1.5, ink)
	draw_circle(head, head_radius, skin)
	draw_colored_polygon(PackedVector2Array([
		head + Vector2(-7.0, -1.0), head + Vector2(-5.0, -7.0),
		head + Vector2(-1.0, -6.0), head + Vector2(2.0, -8.0),
		head + Vector2(6.0, -4.0), head + Vector2(5.0, -1.0)
	]), Color8(45, 49, 41))
	draw_circle(head + Vector2(3.0, -1.0), 1.5, Color8(226, 103, 67))
	draw_circle(head + Vector2(5.2, 1.0), 0.9, Color8(240, 204, 126))
	draw_line(head + Vector2(2.0, 4.0), head + Vector2(6.0, 3.0), Color8(62, 48, 42), 1.3)
	if safe_variant == 1:
		draw_line(head + Vector2(-5.0, 2.0), head + Vector2(-8.0, 7.0), Color8(111, 43, 39), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_barrel(world_x: float, ground: float) -> void:
	draw_rect(Rect2(world_x - 11.0, ground - 31.0, 22.0, 30.0), Color8(166, 91, 54))
	draw_rect(Rect2(world_x - 11.0, ground - 25.0, 22.0, 4.0), Color8(61, 64, 54))
	draw_rect(Rect2(world_x - 11.0, ground - 13.0, 22.0, 4.0), Color8(61, 64, 54))

func _draw_wreck(world_x: float, ground: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 32, ground - 7), Vector2(world_x - 27, ground - 28),
		Vector2(world_x - 11, ground - 37), Vector2(world_x + 20, ground - 31),
		Vector2(world_x + 32, ground - 16), Vector2(world_x + 31, ground - 6)
	]), Color8(91, 83, 63))
	draw_line(Vector2(world_x - 25, ground - 28), Vector2(world_x - 11, ground - 36), Color8(169, 148, 101), 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 20, ground - 27), Vector2(world_x - 10, ground - 34),
		Vector2(world_x + 4, ground - 32), Vector2(world_x + 5, ground - 23)
	]), Color8(76, 106, 101))
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x + 9, ground - 32), Vector2(world_x + 19, ground - 29),
		Vector2(world_x + 26, ground - 18), Vector2(world_x + 8, ground - 21)
	]), Color8(70, 97, 94))
	draw_circle(Vector2(world_x - 17, ground - 4), 7.0, Color8(34, 38, 35))
	draw_circle(Vector2(world_x - 17, ground - 4), 3.0, Color8(147, 133, 94))
	draw_circle(Vector2(world_x + 19, ground - 4), 7.0, Color8(34, 38, 35))
	draw_circle(Vector2(world_x + 19, ground - 4), 3.0, Color8(147, 133, 94))
	draw_line(Vector2(world_x - 29, ground - 13), Vector2(world_x - 20, ground - 13), Color8(198, 117, 69), 3.0)
	draw_line(Vector2(world_x + 24, ground - 14), Vector2(world_x + 31, ground - 11), Color8(216, 181, 119), 3.0)

func _draw_world_setpiece(world_x: float, ground: float, hazard_kind: String) -> void:
	# A low, soft ground shadow separates small hazards from dark terrain on phones.
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 62.0, ground - 1.0), Vector2(world_x - 46.0, ground - 5.0),
		Vector2(world_x + 45.0, ground - 5.0), Vector2(world_x + 63.0, ground - 1.0),
		Vector2(world_x + 44.0, ground + 2.0), Vector2(world_x - 43.0, ground + 2.0)
	]), Color8(22, 29, 26, 115))
	match hazard_kind:
		"flood":
			draw_rect(Rect2(world_x - 57.0, ground - 5.0, 114.0, 12.0), Color8(65, 127, 139, 235))
			draw_line(Vector2(world_x - 54.0, ground - 4.0), Vector2(world_x + 54.0, ground - 4.0), Color8(157, 198, 188), 2.0)
			for wave_index in range(3):
				var wave_x: float = world_x - 35.0 + float(wave_index) * 34.0
				draw_line(Vector2(wave_x - 9.0, ground - 1.0), Vector2(wave_x + 9.0, ground - 1.0), Color8(195, 219, 200), 2.0)
			_draw_hazard_marker(world_x - 48.0, ground - 3.0, Color8(105, 176, 165))
		"canal_debris":
			_draw_world_setpiece(world_x, ground, "flood")
			# Broken stone parapets frame the water, so this reads as a damaged canal crossing.
			draw_line(Vector2(world_x - 49.0, ground - 13.0), Vector2(world_x - 30.0, ground - 17.0), Color8(136, 145, 125), 3.0)
			draw_line(Vector2(world_x + 19.0, ground - 15.0), Vector2(world_x + 49.0, ground - 10.0), Color8(136, 145, 125), 3.0)
			for chunk_index in range(5):
				var chunk_x: float = world_x - 36.0 + float(chunk_index) * 18.0
				var chunk_height: float = 8.0 + float(chunk_index % 3) * 2.0
				draw_colored_polygon(PackedVector2Array([
					Vector2(chunk_x - 8.0, ground - 1.0), Vector2(chunk_x - 5.0, ground - chunk_height),
					Vector2(chunk_x + 3.0, ground - chunk_height + 2.0), Vector2(chunk_x + 8.0, ground - 1.0)
				]), Color8(137, 132, 112))
				draw_line(Vector2(chunk_x - 4.0, ground - chunk_height + 1.0), Vector2(chunk_x + 2.0, ground - chunk_height + 3.0), Color8(188, 171, 135), 1.5)
		"gravel":
			for stone_index in range(11):
				var stone_x: float = world_x - 46.0 + float(stone_index) * 9.0
				var stone_y: float = ground - 4.0 - float(stone_index % 3) * 3.0
				var stone_color: Color = Color8(163, 145, 108) if stone_index % 2 == 0 else Color8(124, 118, 96)
				draw_circle(Vector2(stone_x, stone_y), 4.0 + float(stone_index % 3), stone_color)
				draw_line(Vector2(stone_x - 2.0, stone_y - 2.0), Vector2(stone_x + 1.0, stone_y - 3.0), Color8(204, 184, 143), 1.0)
			_draw_hazard_marker(world_x - 50.0, ground - 2.0, Color8(204, 174, 94))
		"rockfall":
			for rock_index in range(5):
				var rock_x: float = world_x - 30.0 + float(rock_index) * 15.0
				var rock_size: float = 11.0 + float(rock_index % 2) * 5.0
				draw_colored_polygon(PackedVector2Array([
					Vector2(rock_x - rock_size, ground - 3.0),
					Vector2(rock_x - rock_size * 0.55, ground - rock_size * 1.2),
					Vector2(rock_x + rock_size * 0.5, ground - rock_size * 0.9),
					Vector2(rock_x + rock_size, ground - 3.0)
				]), Color8(126, 117, 95))
				draw_line(Vector2(rock_x - rock_size * 0.45, ground - rock_size * 0.95), Vector2(rock_x + rock_size * 0.35, ground - rock_size * 0.83), Color8(179, 161, 125), 1.5)
			_draw_hazard_marker(world_x - 51.0, ground - 2.0, Color8(203, 131, 82))
		"tunnel_rockfall":
			_draw_tunnel_rockfall(world_x, ground)
		"rubble", "boulevard_rubble":
			_draw_rubble_pile(world_x, ground, hazard_kind == "boulevard_rubble")
			_draw_hazard_marker(world_x - 51.0, ground - 2.0, Color8(190, 139, 78))
		"column_rubble":
			_draw_rubble_pile(world_x, ground, true)
			_draw_broken_columns(world_x, ground)
			_draw_hazard_marker(world_x - 51.0, ground - 2.0, Color8(190, 139, 78))
		"stone_arch":
			_draw_stone_arch(world_x, ground)
			_draw_hazard_marker(world_x - 51.0, ground - 2.0, Color8(190, 139, 78))
		"barrier", "military_blockade", "narrow_gate":
			_draw_blockade(world_x, ground, hazard_kind)
		"timber_barrier":
			_draw_timber_barrier(world_x, ground)
		"container_gate", "port_blockade":
			_draw_container_gate(world_x, ground, hazard_kind == "port_blockade")
		"wreck_ramp", "harbor_wreck":
			_draw_wreck_ramp(world_x, ground, hazard_kind == "harbor_wreck")
		"convoy_wreck", "highway_wreck":
			_draw_wreck(world_x - 21.0, ground)
			_draw_wreck(world_x + 22.0, ground - 2.0)
			if hazard_kind == "highway_wreck":
				draw_circle(Vector2(world_x + 47.0, ground - 7.0), 8.0, Color8(42, 46, 42))
				draw_circle(Vector2(world_x + 47.0, ground - 7.0), 3.0, Color8(142, 128, 94))
			_draw_hazard_marker(world_x - 54.0, ground - 2.0, Color8(201, 128, 80))
		"fallen_tree":
			_draw_fallen_tree(world_x, ground)
		"bridge_debris":
			_draw_bridge_debris(world_x, ground)
		"tanker_spill":
			_draw_tanker_spill(world_x, ground)
		"aircraft_debris":
			_draw_aircraft_debris(world_x, ground)
		"landslide":
			_draw_landslide(world_x, ground)
		"tram_wreck":
			_draw_tram_wreck(world_x, ground)
		_:
			_draw_blockade(world_x, ground, "barrier")

func _draw_tunnel_rockfall(world_x: float, ground: float) -> void:
	# A broken tunnel mouth makes this encounter distinct from a generic rock pile.
	var tunnel_center := Vector2(world_x, ground - 2.0)
	var inner_hole := PackedVector2Array()
	for arc_index in range(9):
		var angle: float = PI + PI * float(arc_index) / 8.0
		inner_hole.append(tunnel_center + Vector2(cos(angle), sin(angle)) * 43.0)
	inner_hole.append(Vector2(world_x + 43.0, ground + 1.0))
	inner_hole.append(Vector2(world_x - 43.0, ground + 1.0))
	draw_colored_polygon(inner_hole, Color8(42, 49, 45))
	var arch_ring := PackedVector2Array()
	for arc_index in range(9):
		var angle: float = PI + PI * float(arc_index) / 8.0
		arch_ring.append(tunnel_center + Vector2(cos(angle), sin(angle)) * 60.0)
	for arc_index in range(8, -1, -1):
		var angle: float = PI + PI * float(arc_index) / 8.0
		arch_ring.append(tunnel_center + Vector2(cos(angle), sin(angle)) * 44.0)
	draw_colored_polygon(arch_ring, Color8(115, 108, 89))
	draw_arc(tunnel_center, 52.0, PI, TAU, 16, Color8(177, 159, 122), 2.0, true)
	for light_offset in [-51.0, 51.0]:
		draw_circle(Vector2(world_x + light_offset, ground - 34.0), 5.0, Color8(191, 91, 63))
		draw_circle(Vector2(world_x + light_offset - 1.0, ground - 35.0), 1.5, Color8(255, 195, 124))
	for rock_index in range(6):
		var rock_x: float = world_x - 31.0 + float(rock_index) * 12.0
		var rock_size: float = 9.0 + float(rock_index % 3) * 3.0
		var rock_top: float = ground - 5.0 - float((rock_index * 5) % 9)
		draw_colored_polygon(PackedVector2Array([
			Vector2(rock_x - rock_size, ground - 2.0), Vector2(rock_x - rock_size * 0.5, rock_top - rock_size),
			Vector2(rock_x + rock_size * 0.7, rock_top - rock_size * 0.65), Vector2(rock_x + rock_size, ground - 2.0)
		]), Color8(133, 125, 101))
		draw_line(Vector2(rock_x - rock_size * 0.25, rock_top - rock_size * 0.78), Vector2(rock_x + rock_size * 0.5, rock_top - rock_size * 0.57), Color8(190, 173, 136), 1.5)
	_draw_hazard_marker(world_x - 58.0, ground - 2.0, Color8(214, 138, 82))

func _draw_rubble_pile(world_x: float, ground: float, large_blocks: bool) -> void:
	var rubble_color: Color = Color8(142, 119, 87) if large_blocks else Color8(125, 108, 82)
	var block_width: float = 17.0 if large_blocks else 13.0
	var block_height: float = 13.0 if large_blocks else 9.0
	var block_offsets: Array[Vector2] = [
		Vector2(-39.0, -4.0), Vector2(-22.0, -8.0), Vector2(-5.0, -3.0),
		Vector2(12.0, -10.0), Vector2(31.0, -4.0), Vector2(45.0, -2.0)
	]
	for block_index in range(block_offsets.size()):
		var block_offset: Vector2 = block_offsets[block_index]
		var width: float = block_width + float(block_index % 3) * 3.0
		var height: float = block_height + float(block_index % 2) * 4.0
		var block_rect := Rect2(world_x + block_offset.x, ground + block_offset.y - height, width, height)
		draw_rect(block_rect, rubble_color if block_index % 2 == 0 else Color8(105, 103, 85))
		draw_line(block_rect.position, block_rect.position + Vector2(width, 0.0), Color8(185, 160, 119), 1.5)
		if block_index % 2 == 1:
			draw_line(block_rect.position + Vector2(width * 0.55, 1.0), block_rect.position + Vector2(width * 0.42, height * 0.7), Color8(67, 72, 65), 1.0)
	if large_blocks:
		draw_colored_polygon(PackedVector2Array([
			Vector2(world_x - 55.0, ground - 2.0), Vector2(world_x - 43.0, ground - 17.0),
			Vector2(world_x - 27.0, ground - 10.0), Vector2(world_x - 18.0, ground - 2.0)
		]), Color8(111, 105, 87))
		draw_line(Vector2(world_x - 43.0, ground - 15.0), Vector2(world_x - 29.0, ground - 9.0), Color8(177, 155, 121), 1.5)

func _draw_blockade(world_x: float, ground: float, variant: String) -> void:
	var barrier_color: Color = Color8(184, 142, 81)
	if variant == "military_blockade":
		barrier_color = Color8(130, 126, 87)
	elif variant == "narrow_gate":
		barrier_color = Color8(151, 119, 83)
	for post_offset in [-42.0, 42.0]:
		var post_x: float = world_x + post_offset
		var post_color: Color = Color8(88, 82, 68) if variant != "narrow_gate" else Color8(135, 105, 74)
		draw_rect(Rect2(post_x - 4.0, ground - 27.0, 8.0, 27.0), post_color)
	draw_rect(Rect2(world_x - 49.0, ground - 25.0, 98.0, 16.0), barrier_color)
	draw_rect(Rect2(world_x - 49.0, ground - 25.0, 98.0, 16.0), Color8(52, 57, 51), false, 2.0)
	for stripe_index in range(5):
		var stripe_x: float = world_x - 38.0 + float(stripe_index) * 19.0
		var stripe_color: Color = Color8(55, 56, 49) if stripe_index % 2 == 0 else Color8(222, 187, 110)
		draw_line(Vector2(stripe_x - 4.0, ground - 10.0), Vector2(stripe_x + 5.0, ground - 24.0), stripe_color, 4.0)
	if variant == "military_blockade":
		for light_offset in [-31.0, 31.0]:
			draw_circle(Vector2(world_x + light_offset, ground - 31.0), 6.0, Color8(110, 63, 48, 100))
			draw_circle(Vector2(world_x + light_offset, ground - 31.0), 4.0, Color8(229, 113, 80))
			draw_circle(Vector2(world_x + light_offset - 1.0, ground - 32.0), 1.4, Color8(255, 198, 132))
	if variant == "narrow_gate":
		for bar_index in range(4):
			var bar_x: float = world_x - 29.0 + float(bar_index) * 19.0
			draw_rect(Rect2(bar_x, ground - 38.0, 4.0, 38.0), Color8(92, 80, 62))
			draw_circle(Vector2(bar_x + 2.0, ground - 38.0), 3.0, Color8(194, 157, 101))
	_draw_hazard_marker(world_x - 57.0, ground - 2.0, Color8(205, 143, 77))

func _draw_container_gate(world_x: float, ground: float, port_variant: bool) -> void:
	var top_color: Color = Color8(119, 119, 88) if port_variant else Color8(119, 106, 79)
	var bottom_color: Color = Color8(85, 108, 101) if port_variant else Color8(101, 91, 72)
	draw_rect(Rect2(world_x - 49.0, ground - 43.0, 49.0, 21.0), top_color)
	draw_rect(Rect2(world_x + 1.0, ground - 35.0, 49.0, 19.0), bottom_color)
	for rib_index in range(4):
		var rib_x: float = world_x - 42.0 + float(rib_index) * 11.0
		draw_line(Vector2(rib_x, ground - 41.0), Vector2(rib_x, ground - 24.0), Color8(57, 66, 61), 2.0)
		rib_x = world_x + 8.0 + float(rib_index) * 10.0
		draw_line(Vector2(rib_x, ground - 33.0), Vector2(rib_x, ground - 18.0), Color8(57, 66, 61), 2.0)
	for corner_x in [world_x - 45.0, world_x - 4.0, world_x + 6.0, world_x + 46.0]:
		draw_rect(Rect2(corner_x, ground - 40.0, 4.0, 5.0), Color8(192, 147, 82))
		draw_rect(Rect2(corner_x, ground - 23.0, 4.0, 5.0), Color8(192, 147, 82))
	draw_line(Vector2(world_x - 50.0, ground - 21.0), Vector2(world_x + 50.0, ground - 21.0), Color8(177, 147, 95), 3.0)
	if port_variant:
		draw_line(Vector2(world_x - 46.0, ground - 47.0), Vector2(world_x - 46.0, ground - 59.0), Color8(75, 77, 65), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(world_x - 45.0, ground - 58.0), Vector2(world_x - 30.0, ground - 54.0), Vector2(world_x - 45.0, ground - 50.0)]), Color8(195, 102, 72))
	_draw_hazard_marker(world_x - 57.0, ground - 2.0, Color8(205, 143, 77))

func _draw_wreck_ramp(world_x: float, ground: float, harbor_variant: bool) -> void:
	_draw_wreck(world_x - 12.0, ground)
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x + 2.0, ground - 3.0), Vector2(world_x + 14.0, ground - 24.0),
		Vector2(world_x + 48.0, ground - 24.0), Vector2(world_x + 51.0, ground - 3.0)
	]), Color8(123, 101, 73))
	draw_line(Vector2(world_x + 14.0, ground - 24.0), Vector2(world_x + 48.0, ground - 24.0), Color8(201, 166, 105), 3.0)
	if harbor_variant:
		draw_line(Vector2(world_x - 45.0, ground - 3.0), Vector2(world_x - 45.0, ground - 23.0), Color8(83, 105, 100), 3.0)
		draw_circle(Vector2(world_x - 45.0, ground - 26.0), 4.0, Color8(205, 143, 77))
	_draw_hazard_marker(world_x - 57.0, ground - 2.0, Color8(201, 128, 80))

func _draw_fallen_tree(world_x: float, ground: float) -> void:
	draw_line(Vector2(world_x - 45.0, ground - 4.0), Vector2(world_x + 39.0, ground - 35.0), Color8(104, 79, 54), 13.0)
	draw_line(Vector2(world_x - 39.0, ground - 8.0), Vector2(world_x + 33.0, ground - 35.0), Color8(163, 124, 77), 2.0)
	draw_circle(Vector2(world_x - 44.0, ground - 4.0), 6.0, Color8(185, 144, 92))
	draw_line(Vector2(world_x - 14.0, ground - 16.0), Vector2(world_x - 26.0, ground - 35.0), Color8(81, 96, 63), 7.0)
	draw_line(Vector2(world_x + 10.0, ground - 25.0), Vector2(world_x + 19.0, ground - 44.0), Color8(81, 96, 63), 8.0)
	draw_line(Vector2(world_x - 21.0, ground - 26.0), Vector2(world_x - 37.0, ground - 28.0), Color8(81, 96, 63), 5.0)
	draw_line(Vector2(world_x + 15.0, ground - 33.0), Vector2(world_x + 34.0, ground - 31.0), Color8(81, 96, 63), 5.0)
	draw_circle(Vector2(world_x - 30.0, ground - 38.0), 13.0, Color8(75, 102, 67))
	draw_circle(Vector2(world_x - 34.0, ground - 42.0), 6.0, Color8(110, 133, 83))
	draw_circle(Vector2(world_x + 23.0, ground - 47.0), 14.0, Color8(84, 108, 69))
	draw_circle(Vector2(world_x + 19.0, ground - 51.0), 6.0, Color8(122, 143, 88))
	_draw_hazard_marker(world_x - 54.0, ground - 2.0, Color8(173, 151, 94))

func _draw_bridge_debris(world_x: float, ground: float) -> void:
	_draw_world_setpiece(world_x, ground, "rubble")
	draw_line(Vector2(world_x - 55.0, ground - 20.0), Vector2(world_x - 20.0, ground - 29.0), Color8(116, 123, 111), 3.0)
	draw_line(Vector2(world_x + 17.0, ground - 26.0), Vector2(world_x + 55.0, ground - 16.0), Color8(116, 123, 111), 3.0)
	for post_offset in [-42.0, 42.0]:
		draw_line(Vector2(world_x + post_offset, ground - 2.0), Vector2(world_x + post_offset, ground - 25.0), Color8(94, 104, 93), 3.0)

func _draw_tanker_spill(world_x: float, ground: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 53.0, ground - 2.0), Vector2(world_x - 40.0, ground - 8.0),
		Vector2(world_x - 12.0, ground - 10.0), Vector2(world_x + 21.0, ground - 8.0),
		Vector2(world_x + 57.0, ground - 2.0), Vector2(world_x + 23.0, ground + 2.0),
		Vector2(world_x - 25.0, ground + 2.0)
	]), Color8(65, 76, 67, 235))
	draw_line(Vector2(world_x - 46.0, ground - 3.0), Vector2(world_x - 17.0, ground - 8.0), Color8(138, 151, 123, 190), 2.0)
	draw_line(Vector2(world_x + 7.0, ground - 8.0), Vector2(world_x + 43.0, ground - 3.0), Color8(138, 151, 123, 190), 2.0)
	draw_rect(Rect2(world_x - 34.0, ground - 25.0, 58.0, 18.0), Color8(151, 112, 66))
	draw_circle(Vector2(world_x - 34.0, ground - 16.0), 9.0, Color8(151, 112, 66))
	draw_circle(Vector2(world_x + 24.0, ground - 16.0), 9.0, Color8(151, 112, 66))
	draw_circle(Vector2(world_x - 24.0, ground - 5.0), 6.0, Color8(42, 46, 42))
	draw_circle(Vector2(world_x + 17.0, ground - 5.0), 6.0, Color8(42, 46, 42))
	draw_line(Vector2(world_x - 28.0, ground - 20.0), Vector2(world_x + 15.0, ground - 20.0), Color8(202, 161, 103), 2.0)
	_draw_hazard_marker(world_x - 54.0, ground - 2.0, Color8(204, 174, 94))

func _draw_aircraft_debris(world_x: float, ground: float) -> void:
	# Broken airliner parts keep the wing, fuselage, and tail silhouette readable at driving scale.
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 53.0, ground - 11.0), Vector2(world_x - 15.0, ground - 16.0),
		Vector2(world_x - 7.0, ground - 24.0), Vector2(world_x + 39.0, ground - 18.0),
		Vector2(world_x + 52.0, ground - 10.0), Vector2(world_x + 37.0, ground - 5.0),
		Vector2(world_x - 44.0, ground - 5.0)
	]), Color8(126, 138, 128))
	draw_line(Vector2(world_x - 40.0, ground - 12.0), Vector2(world_x + 36.0, ground - 14.0), Color8(196, 190, 155), 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 7.0, ground - 16.0), Vector2(world_x + 6.0, ground - 39.0),
		Vector2(world_x + 16.0, ground - 17.0), Vector2(world_x + 41.0, ground - 10.0),
		Vector2(world_x + 12.0, ground - 8.0)
	]), Color8(101, 117, 111))
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 46.0, ground - 11.0), Vector2(world_x - 30.0, ground - 14.0),
		Vector2(world_x - 48.0, ground - 34.0), Vector2(world_x - 56.0, ground - 29.0)
	]), Color8(116, 127, 114))
	for panel_index in range(4):
		var panel_x: float = world_x - 25.0 + float(panel_index) * 16.0
		draw_line(Vector2(panel_x, ground - 18.0), Vector2(panel_x + 3.0, ground - 13.0), Color8(214, 205, 165), 2.0)
	draw_line(Vector2(world_x + 39.0, ground - 14.0), Vector2(world_x + 49.0, ground - 10.0), Color8(197, 109, 75), 3.0)
	_draw_hazard_marker(world_x - 55.0, ground - 2.0, Color8(203, 131, 82))

func _draw_landslide(world_x: float, ground: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 55.0, ground - 2.0), Vector2(world_x - 35.0, ground - 17.0),
		Vector2(world_x - 13.0, ground - 11.0), Vector2(world_x + 3.0, ground - 28.0),
		Vector2(world_x + 27.0, ground - 15.0), Vector2(world_x + 53.0, ground - 2.0)
	]), Color8(126, 107, 76))
	draw_line(Vector2(world_x - 34.0, ground - 16.0), Vector2(world_x + 2.0, ground - 27.0), Color8(185, 153, 105), 2.0)
	draw_line(Vector2(world_x - 21.0, ground - 10.0), Vector2(world_x + 35.0, ground - 13.0), Color8(99, 99, 77), 2.0)
	for rock_index in range(5):
		var rock_x: float = world_x - 34.0 + float(rock_index) * 17.0
		var rock_radius: float = 7.0 + float(rock_index % 3) * 2.0
		draw_circle(Vector2(rock_x, ground - 7.0 - float(rock_index % 2) * 5.0), rock_radius, Color8(145, 133, 101))
		draw_arc(Vector2(rock_x - 1.0, ground - 8.0), rock_radius - 2.0, PI + 0.2, TAU - 0.4, 8, Color8(193, 174, 133), 1.5, true)
	_draw_hazard_marker(world_x - 55.0, ground - 2.0, Color8(203, 131, 82))

func _draw_tram_wreck(world_x: float, ground: float) -> void:
	draw_line(Vector2(world_x - 58.0, ground - 1.0), Vector2(world_x + 58.0, ground - 1.0), Color8(118, 112, 83), 3.0)
	draw_line(Vector2(world_x - 52.0, ground + 2.0), Vector2(world_x + 52.0, ground + 2.0), Color8(75, 80, 67), 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 52.0, ground - 5.0), Vector2(world_x - 48.0, ground - 33.0),
		Vector2(world_x - 34.0, ground - 42.0), Vector2(world_x + 44.0, ground - 35.0),
		Vector2(world_x + 53.0, ground - 11.0), Vector2(world_x + 48.0, ground - 5.0)
	]), Color8(139, 118, 76))
	draw_line(Vector2(world_x - 44.0, ground - 31.0), Vector2(world_x - 33.0, ground - 40.0), Color8(198, 164, 100), 2.0)
	for window_index in range(4):
		var window_x: float = world_x - 34.0 + float(window_index) * 19.0
		draw_rect(Rect2(window_x, ground - 32.0, 13.0, 12.0), Color8(78, 104, 98))
	draw_circle(Vector2(world_x - 29.0, ground - 3.0), 7.0, Color8(41, 45, 42))
	draw_circle(Vector2(world_x + 32.0, ground - 3.0), 7.0, Color8(41, 45, 42))
	_draw_hazard_marker(world_x - 55.0, ground - 2.0, Color8(201, 128, 80))

func _draw_broken_columns(world_x: float, ground: float) -> void:
	for column_offset in [-34.0, 12.0]:
		draw_rect(Rect2(world_x + column_offset + 2.0, ground - 25.0, 12.0, 25.0), Color8(144, 129, 103))
		draw_rect(Rect2(world_x + column_offset, ground - 30.0, 20.0, 6.0), Color8(176, 153, 117))
		draw_line(Vector2(world_x + column_offset + 4.0, ground - 22.0), Vector2(world_x + column_offset + 11.0, ground - 25.0), Color8(194, 173, 137), 1.5)
		for crack_index in range(3):
			var crack_y: float = ground - 21.0 + float(crack_index) * 7.0
			draw_line(Vector2(world_x + column_offset + 2.0, crack_y), Vector2(world_x + column_offset + 8.0, crack_y + 3.0), Color8(89, 88, 75), 1.0)

func _draw_stone_arch(world_x: float, ground: float) -> void:
	draw_rect(Rect2(world_x - 49.0, ground - 36.0, 21.0, 35.0), Color8(143, 123, 93))
	draw_rect(Rect2(world_x + 28.0, ground - 36.0, 21.0, 35.0), Color8(143, 123, 93))
	draw_arc(Vector2(world_x, ground - 30.0), 39.0, PI, TAU, 18, Color8(172, 149, 111), 12.0, true)
	draw_arc(Vector2(world_x, ground - 30.0), 27.0, PI, TAU, 18, Color8(83, 87, 74), 2.0, true)
	_draw_bridge_debris(world_x, ground)

func _draw_hazard_marker(world_x: float, ground: float, marker_color: Color) -> void:
	draw_line(Vector2(world_x, ground - 2.0), Vector2(world_x, ground - 23.0), Color8(58, 62, 52), 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x + 1.0, ground - 22.0),
		Vector2(world_x + 15.0, ground - 19.0),
		Vector2(world_x + 1.0, ground - 14.0)
	]), marker_color)
	draw_line(Vector2(world_x + 2.0, ground - 21.0), Vector2(world_x + 10.0, ground - 19.0), Color8(245, 211, 145), 1.2)
	draw_circle(Vector2(world_x, ground - 23.0), 2.4, Color8(220, 115, 77))

func _draw_coin_cache(world_x: float, ground: float) -> void:
	for index in range(3):
		var coin_center: Vector2 = Vector2(world_x + float(index - 1) * 11.0, ground - 13.0 - (5.0 if index == 1 else 0.0))
		draw_circle(coin_center, 6.0, Color8(104, 77, 42))
		draw_circle(coin_center, 4.5, Color8(222, 174, 77))
		draw_circle(coin_center + Vector2(-1.0, -1.0), 1.2, Color8(255, 226, 151))

func _draw_fuel_can(world_x: float, ground: float) -> void:
	draw_rect(Rect2(world_x - 10.0, ground - 28.0, 20.0, 26.0), Color8(184, 135, 61))
	draw_rect(Rect2(world_x - 5.0, ground - 32.0, 10.0, 5.0), Color8(184, 135, 61))
	draw_rect(Rect2(world_x - 3.0, ground - 26.0, 6.0, 8.0), Color8(79, 73, 56))
	draw_line(Vector2(world_x - 10.0, ground - 5.0), Vector2(world_x + 10.0, ground - 5.0), Color8(230, 189, 98), 2.0)

func _draw_nitro_canister(world_x: float, ground: float) -> void:
	var bob: float = sin(float(Time.get_ticks_msec()) * 0.003 + world_x * 0.1) * 2.0
	var center := Vector2(world_x, ground - 20.0 + bob)
	draw_circle(center + Vector2(0.0, 2.0), 22.0, Color8(65, 168, 174, 42))
	draw_rect(Rect2(center.x - 11.0, center.y - 14.0, 22.0, 29.0), Color8(40, 129, 142))
	draw_rect(Rect2(center.x - 7.0, center.y - 19.0, 14.0, 6.0), Color8(60, 151, 160))
	draw_rect(Rect2(center.x - 4.0, center.y - 11.0, 8.0, 11.0), Color8(184, 222, 190))
	draw_line(Vector2(center.x - 8.0, center.y + 11.0), Vector2(center.x + 8.0, center.y + 11.0), Color8(25, 76, 82), 2.0)

func _draw_repair_kit(world_x: float, ground: float) -> void:
	# A bright first-aid mark makes the repair pickup readable against the road.
	draw_rect(Rect2(world_x - 15.0, ground - 25.0, 30.0, 24.0), Color8(66, 91, 71))
	draw_rect(Rect2(world_x - 8.0, ground - 30.0, 16.0, 6.0), Color8(96, 117, 85))
	draw_rect(Rect2(world_x - 9.0, ground - 20.0, 18.0, 14.0), Color8(229, 217, 180))
	draw_rect(Rect2(world_x - 3.0, ground - 18.0, 6.0, 10.0), Color8(176, 83, 63))
	draw_rect(Rect2(world_x - 7.0, ground - 14.0, 14.0, 4.0), Color8(176, 83, 63))

func _draw_story_log(world_x: float, ground: float) -> void:
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.004 + world_x * 0.015)
	draw_circle(Vector2(world_x, ground - 18.0), 30.0 + pulse * 3.0, Color8(204, 166, 93, 24))
	draw_rect(Rect2(world_x - 19.0, ground - 31.0, 38.0, 28.0), Color8(46, 57, 50))
	draw_rect(Rect2(world_x - 16.0, ground - 28.0, 32.0, 22.0), Color8(190, 151, 82))
	draw_rect(Rect2(world_x - 11.0, ground - 24.0, 22.0, 14.0), Color8(54, 68, 60))
	draw_circle(Vector2(world_x, ground - 17.0), 5.2, Color8(213, 183, 112))
	draw_circle(Vector2(world_x, ground - 17.0), 2.5, Color8(56, 66, 57))
	draw_line(Vector2(world_x - 11.0, ground - 33.0), Vector2(world_x - 18.0, ground - 43.0), Color8(194, 180, 128), 2.0, true)
	draw_circle(Vector2(world_x + 13.0, ground - 25.0), 2.5, Color8(225, 101, 67))
	draw_line(Vector2(world_x - 18.0, ground - 4.0), Vector2(world_x + 18.0, ground - 4.0), Color8(227, 202, 144), 1.0, true)

func _draw_checkpoint(world_x: float, ground: float) -> void:
	# A bare, damaged service arch marks supplies without road signs or text.
	draw_rect(Rect2(world_x - 57.0, ground - 4.0, 114.0, 7.0), Color8(40, 46, 39, 150))
	draw_line(Vector2(world_x - 47.0, ground - 5.0), Vector2(world_x - 47.0, ground - 96.0), Color8(78, 84, 66), 6.0, true)
	draw_line(Vector2(world_x + 47.0, ground - 5.0), Vector2(world_x + 47.0, ground - 96.0), Color8(78, 84, 66), 6.0, true)
	draw_line(Vector2(world_x - 49.0, ground - 96.0), Vector2(world_x + 49.0, ground - 96.0), Color8(93, 104, 83), 6.0, true)
	draw_line(Vector2(world_x - 43.0, ground - 89.0), Vector2(world_x - 26.0, ground - 73.0), Color8(93, 104, 83), 2.0, true)
	draw_line(Vector2(world_x + 43.0, ground - 89.0), Vector2(world_x + 27.0, ground - 73.0), Color8(93, 104, 83), 2.0, true)
	draw_line(Vector2(world_x - 33.0, ground - 60.0), Vector2(world_x + 33.0, ground - 60.0), Color8(122, 145, 112), 3.0, true)
	draw_circle(Vector2(world_x, ground - 60.0), 8.0, Color8(116, 157, 101))
	draw_circle(Vector2(world_x, ground - 60.0), 3.0, Color8(233, 210, 143))
	for light_index in range(3):
		var lamp_x: float = world_x - 20.0 + float(light_index) * 20.0
		draw_circle(Vector2(lamp_x, ground - 47.0), 2.5, Color8(210, 185, 113, 190))

func _draw_rescue_ship_on_road(world_x: float, ground: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(world_x - 54.0, ground - 5.0), Vector2(world_x + 57.0, ground - 5.0), Vector2(world_x + 42.0, ground + 10.0), Vector2(world_x - 39.0, ground + 10.0)]), Color8(174, 186, 167))
	draw_rect(Rect2(world_x - 14.0, ground - 32.0, 47.0, 27.0), Color8(187, 182, 150))
	draw_rect(Rect2(world_x + 1.0, ground - 43.0, 17.0, 11.0), Color8(213, 199, 157))
	draw_line(Vector2(world_x - 40.0, ground + 13.0), Vector2(world_x + 45.0, ground + 13.0), Color8(105, 152, 158), 2.0)
