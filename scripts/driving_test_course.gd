extends Node2D
class_name DrivingTestCourse

signal encounter_hit(kind: String, resistance: float, variant_id: int, group_size: int, world_x: float, ground_y: float, speed_mps: float)

signal zombie_shot

const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const ZOMBIE_DATA = preload("res://scripts/zombie_data.gd")

const PIXELS_PER_METER: float = CAMPAIGN_DATA.PIXELS_PER_METER
const COURSE_LENGTH_M: float = 900.0
const START_M: float = 7.0
const DRAW_SAMPLE_M: float = 0.75
const COLLISION_SAMPLE_M: float = 0.25
const BASELINE_Y: float = 520.0
const JUMP_RAMP_START_M: float = 470.0
const JUMP_LIP_M: float = 492.0
const JUMP_LANDING_M: float = 500.0
const ZOMBIE_NORMAL_RUN_TEXTURE: Texture2D = preload("res://assets/zombie_normal_run_0.7.1.png")
const ZOMBIE_RUNNER_TEXTURE: Texture2D = preload("res://assets/zombie_runner_0.7.0.png")
const ZOMBIE_WORKER_TEXTURE: Texture2D = preload("res://assets/zombie_worker_0.7.0.png")
const ZOMBIE_RIOT_TEXTURE: Texture2D = preload("res://assets/zombie_riot_0.7.0.png")
const ZOMBIE_BRUTE_TEXTURE: Texture2D = preload("res://assets/zombie_brute_0.7.0.png")
const ZOMBIE_NORMAL_RUN_FRAMES: Array[Rect2] = [
	Rect2(0.0, 0.0, 650.0, 713.0), Rect2(650.0, 0.0, 425.0, 713.0),
	Rect2(1075.0, 0.0, 635.0, 713.0), Rect2(1710.0, 0.0, 496.0, 713.0)
]
const ENCOUNTER_LAYOUT: Array[Dictionary] = [
	{"kind": "zombie_group", "meter": 82.0, "variant": 1, "members": 3, "resistance": 0.0},
	{"kind": "light_obstacle", "meter": 165.0, "variant": 0, "members": 1, "resistance": 0.28},
	{"kind": "heavy_obstacle", "meter": 248.0, "variant": 0, "members": 1, "resistance": 0.95},
	{"kind": "runner_group", "meter": 357.0, "variant": 2, "members": 2, "resistance": 0.0},
	{"kind": "light_obstacle", "meter": 435.0, "variant": 0, "members": 1, "resistance": 0.28},
	{"kind": "zombie_group", "meter": 610.0, "variant": 1, "members": 2, "resistance": 0.0},
	{"kind": "heavy_obstacle", "meter": 713.0, "variant": 0, "members": 1, "resistance": 0.80},
	{"kind": "light_obstacle", "meter": 786.0, "variant": 0, "members": 1, "resistance": 0.28},
	{"kind": "heavy_obstacle", "meter": 854.0, "variant": 0, "members": 1, "resistance": 0.72}
]

var _wall_tile: Texture2D
var _wagon: EscapeWagon
var _encounters: Array[Dictionary] = []
var _reactions: Array[Dictionary] = []
var _impact_particles: Array[Dictionary] = []
var _elapsed_s: float = 0.0
var _zombie_data = ZOMBIE_DATA.new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_build_road_collision()
	queue_redraw()

func preview_city_name() -> String:
	return ""

func preview_title_text() -> String:
	return ""

func zombie_approach_distance_m() -> float:
	return 58.0

func setup_test_run(wagon: EscapeWagon) -> void:
	_wagon = wagon
	_build_encounters()

func reset_test_run(wagon: EscapeWagon) -> void:
	_wagon = wagon
	_elapsed_s = 0.0
	_reactions.clear()
	_impact_particles.clear()
	for old_event in _encounters:
		for old_area in old_event.get("areas", []):
			var area: Area2D = old_area as Area2D
			if is_instance_valid(area):
				area.queue_free()
	_encounters.clear()
	_build_encounters()
	queue_redraw()

func height_at(world_x: float) -> float:
	var meter: float = world_x / PIXELS_PER_METER
	var rolling_hills: float = sin(meter * 0.054) * 17.0 + sin(meter * 0.022 + 0.7) * 13.0 + sin(meter * 0.13) * 5.0
	var hills: float = 0.0
	hills += _hump_offset(meter, 34.0, 53.0, 78.0, 28.0, 6.0)
	hills += _hump_offset(meter, 115.0, 138.0, 160.0, 24.0, 4.0)
	hills += _hump_offset(meter, 202.0, 226.0, 250.0, 52.0, 12.0)
	hills += _hump_offset(meter, 293.0, 322.0, 349.0, 34.0, 8.0)
	hills += _hump_offset(meter, 389.0, 418.0, 442.0, 46.0, 7.0)
	hills += _hump_offset(meter, 565.0, 591.0, 616.0, 25.0, 5.0)
	hills += _hump_offset(meter, 678.0, 707.0, 735.0, 37.0, 8.0)
	hills += _hump_offset(meter, 766.0, 793.0, 820.0, 24.0, 5.0)
	return BASELINE_Y + rolling_hills + hills + _jump_profile_offset(meter)

func slope_at(world_x: float) -> float:
	var half_span: float = 0.5 * PIXELS_PER_METER
	return atan((height_at(world_x + half_span) - height_at(world_x - half_span)) / (half_span * 2.0))

func _hump_offset(meter: float, start_m: float, crest_m: float, end_m: float, height_px: float, landing_drop_px: float) -> float:
	if meter < start_m or meter >= end_m + 5.0:
		return 0.0
	if meter < crest_m:
		return lerpf(0.0, -height_px, smoothstep(start_m, crest_m, meter))
	if meter < end_m:
		return lerpf(-height_px, landing_drop_px, smoothstep(crest_m, end_m, meter))
	return lerpf(landing_drop_px, 0.0, smoothstep(end_m, end_m + 5.0, meter))

func _jump_profile_offset(meter: float) -> float:
	if meter < JUMP_RAMP_START_M:
		return 0.0
	if meter < JUMP_LIP_M:
		return lerpf(0.0, -72.0, smoothstep(JUMP_RAMP_START_M, JUMP_LIP_M, meter))
	if meter < JUMP_LANDING_M:
		return -72.0
	if meter < 519.0:
		return lerpf(-72.0, -39.0, smoothstep(JUMP_LANDING_M, 519.0, meter))
	if meter < 541.0:
		return lerpf(-39.0, 0.0, smoothstep(519.0, 541.0, meter))
	return 0.0

func fuel_factor() -> float:
	return 1.0

func road_end_m() -> float:
	return COURSE_LENGTH_M

func has_road_surface(meter: float) -> bool:
	return meter < JUMP_LIP_M or meter >= JUMP_LANDING_M

func encounter_layout() -> Array[Dictionary]:
	return ENCOUNTER_LAYOUT

func _build_road_collision() -> void:
	var collider := StaticBody2D.new()
	collider.name = "RoadCollision"
	collider.collision_layer = 1
	collider.collision_mask = 0
	var collision := CollisionShape2D.new()
	collision.name = "RoadSegments"
	var road_shape := ConcavePolygonShape2D.new()
	var segments := PackedVector2Array()
	var sample_count: int = int(road_end_m() / COLLISION_SAMPLE_M)
	var has_previous: bool = false
	var previous_point := Vector2.ZERO
	for sample_index in range(sample_count + 1):
		var meter: float = float(sample_index) * COLLISION_SAMPLE_M
		var point := Vector2(meter * PIXELS_PER_METER, height_at(meter * PIXELS_PER_METER))
		if not has_road_surface(meter):
			has_previous = false
			continue
		if has_previous:
			segments.append(previous_point)
			segments.append(point)
		previous_point = point
		has_previous = true
	road_shape.segments = segments
	collision.shape = road_shape
	collider.add_child(collision)
	add_child(collider)

func _build_encounters() -> void:
	_encounters.clear()
	var layout: Array[Dictionary] = encounter_layout()
	for layout_index in range(layout.size()):
		var event: Dictionary = layout[layout_index].duplicate(true)
		event["done"] = false
		event["areas"] = []
		event["members_data"] = []
		var kind: String = String(event["kind"])
		var member_count: int = int(event["members"])
		var group_spacing: float = 45.0 if int(event["variant"]) == 2 else 41.0
		for member_index in range(member_count):
			var x: float = float(event["meter"]) * PIXELS_PER_METER
			if kind in ["zombie_group", "runner_group"]:
				x += float(member_index) * group_spacing - float(member_count - 1) * group_spacing * 0.5
			var ground_y: float = height_at(x)
			var area_size: Vector2
			if kind in ["zombie_group", "runner_group"]:
				var visual_height: float = float(ZOMBIE_DATA.profile(int(event["variant"])).get("visual_height", 78.0))
				area_size = Vector2(visual_height * 0.52, visual_height * 0.84)
			else:
				var prop: String = String(event.get("prop", ""))
				match prop:
					"tram_wreck": area_size = Vector2(152.0, 69.0)
					"barrel_stack": area_size = Vector2(66.0, 53.0)
					"canal_cart": area_size = Vector2(86.0, 48.0)
					"scaffold": area_size = Vector2(120.0, 61.0)
					_: area_size = Vector2(38.0, 29.0) if kind == "light_obstacle" else Vector2(78.0, 43.0)
			var area := Area2D.new()
			area.name = "Encounter_%02d_%02d" % [layout_index, member_index]
			area.position = Vector2(x, ground_y - area_size.y * 0.5)
			area.collision_layer = 0
			area.collision_mask = 1
			area.monitoring = true
			area.monitorable = false
			var collision := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = area_size
			collision.shape = shape
			area.add_child(collision)
			area.body_entered.connect(_on_encounter_body_entered.bind(layout_index, member_index))
			add_child(area)
			(event["areas"] as Array).append(area)
			(event["members_data"] as Array).append({"x": x, "area": area, "area_height": area_size.y, "phase": float(member_index) * 0.8, "hit": false})
		_encounters.append(event)

func _encounter_ground_at(world_x: float, _event: Dictionary) -> float:
	return height_at(world_x)

func _physics_process(delta: float) -> void:
	_elapsed_s += delta
	if _wagon == null:
		return
	var has_visible_animation: bool = false
	var chase_target_x: float = _wagon.position.x + _wagon.front_contact_offset_px()
	for event_index in range(_encounters.size()):
		var event: Dictionary = _encounters[event_index]
		if _wagon.freeze:
			continue
		if bool(event.get("done", false)):
			continue
		var kind: String = String(event["kind"])
		if kind not in ["zombie_group", "runner_group"]:
			continue
		var areas: Array = event.get("areas", [])
		var members_data: Array = event.get("members_data", [])
		var chase_speed: float = 15.0 if int(event["variant"]) == 2 else 8.0
		if bool(event.get("agile_chase", false)):
			chase_speed = float(ZOMBIE_DATA.profile(int(event["variant"]))["chase_speed_mps"])
		for member_index in range(members_data.size()):
			var member: Dictionary = members_data[member_index]
			if bool(member.get("hit", false)):
				continue
			var area: Area2D = areas[member_index] as Area2D
			if not is_instance_valid(area):
				continue
			var member_x: float = float(member.get("x", 0.0))
			if member_x - chase_target_x <= zombie_approach_distance_m() * PIXELS_PER_METER:
				var pace: float = chase_speed
				if bool(event.get("agile_chase", false)):
					var distance_m: float = (member_x - chase_target_x) / PIXELS_PER_METER
					var close_charge: float = 1.0 - smoothstep(4.0, 16.0, absf(distance_m))
					var stride: float = sin(float(member.get("run_phase", 0.0)))
					var intent: float = float(member.get("alert_s", 0.0)) + delta
					member["alert_s"] = intent
					pace *= lerpf(0.28, 1.0, smoothstep(0.0, 0.28, intent)) * (0.68 + 0.55 * close_charge + 0.06 * stride)
					member["facing"] = -1.0 if distance_m < 0.0 else 1.0
					var target_x: float = chase_target_x
					if member_x < _wagon.position.x - 40.0:
						target_x = _wagon.position.x - 100.0
						pace *= 1.18
					member_x = move_toward(member_x, target_x, pace * PIXELS_PER_METER * delta)
				else:
					member_x -= pace * PIXELS_PER_METER * delta
				member["x"] = member_x
				member["run_phase"] = float(member.get("run_phase", member.get("phase", 0.0))) + delta * (4.0 + pace * 0.65)
				area.position = Vector2(member_x, _encounter_ground_at(member_x, event) - float(member.get("area_height", 64.0)) * 0.5)
				members_data[member_index] = member
				if absf(member_x - get_viewport().get_camera_2d().global_position.x) < get_viewport_rect().size.x:
					has_visible_animation = true
		_encounters[event_index] = event
		var furthest_member_x: float = -INF
		for member in members_data:
			if not bool(member.get("hit", false)):
				furthest_member_x = maxf(furthest_member_x, float(member["x"]))
		if _wagon.position.x - furthest_member_x > 30.0 * PIXELS_PER_METER:
			_clear_encounter(event_index)
	for reaction_index in range(_reactions.size() - 1, -1, -1):
		var reaction: Dictionary = _reactions[reaction_index]
		reaction["time_left"] = maxf(0.0, float(reaction.get("time_left", 0.0)) - delta)
		if float(reaction["time_left"]) <= 0.0:
			_reactions.remove_at(reaction_index)
		else:
			_reactions[reaction_index] = reaction
			has_visible_animation = true
	for particle_index in range(_impact_particles.size() - 1, -1, -1):
		var particle: Dictionary = _impact_particles[particle_index]
		var life: float = maxf(0.0, float(particle.get("life", 0.0)) - delta)
		if life <= 0.0:
			_impact_particles.remove_at(particle_index)
			continue
		var velocity: Vector2 = Vector2(particle.get("velocity", Vector2.ZERO))
		velocity.y += 340.0 * delta
		particle["velocity"] = velocity
		particle["position"] = Vector2(particle.get("position", Vector2.ZERO)) + velocity * delta
		if particle.has("spin"):
			particle["angle"] = float(particle["angle"]) + float(particle["spin"]) * delta
		particle["life"] = life
		_impact_particles[particle_index] = particle
		has_visible_animation = true
	if has_visible_animation:
		queue_redraw()

func _on_encounter_body_entered(body: Node2D, event_index: int, member_index: int) -> void:
	if body != _wagon or _wagon.freeze or event_index < 0 or event_index >= _encounters.size():
		return
	var event: Dictionary = _encounters[event_index]
	if bool(event.get("done", false)):
		return
	var members_data: Array = event.get("members_data", [])
	var areas: Array = event.get("areas", [])
	if member_index < 0 or member_index >= areas.size():
		return
	var hit_area: Area2D = areas[member_index] as Area2D
	if not is_instance_valid(hit_area):
		return
	var kind: String = String(event["kind"])
	if bool(members_data[member_index].get("hit", false)):
		return
	var world_x: float = hit_area.position.x
	var ground_y: float = _encounter_ground_at(world_x, event)
	var is_zombie: bool = kind in ["zombie_group", "runner_group"]
	var live_members: Array = [members_data[member_index]] if is_zombie else members_data
	var group_size: int = live_members.size()
	var variant_id: int = int(event["variant"])
	var resistance: float = float(event["resistance"])
	var speed_mps: float = absf(_wagon.speed_mps)
	for hit_member: Dictionary in live_members:
		var encounter_area: Area2D = hit_member["area"] as Area2D
		if is_instance_valid(encounter_area):
			encounter_area.set_deferred("monitoring", false)
		hit_member["hit"] = true
	event["done"] = members_data.all(func(member: Dictionary) -> bool: return bool(member.get("hit", false)))
	_encounters[event_index] = event
	var previous_latches: int = _wagon.zombie_latches.size()
	var reported_kind: String = String(event.get("prop", kind))
	encounter_hit.emit(reported_kind, resistance, variant_id, group_size, world_x, ground_y, speed_mps)
	if is_zombie:
		if _wagon.zombie_latches.size() > previous_latches:
			live_members.erase(members_data[member_index])
		if not live_members.is_empty():
			var duration: float = lerpf(1.1, 1.4, smoothstep(2.0, 38.0, speed_mps))
			_reactions.append({"variant": variant_id, "members": live_members.duplicate(true), "time_left": duration, "duration": duration, "ground_y": ground_y, "speed_mps": speed_mps, "seed": event_index * 7 + member_index})
	queue_redraw()

func _clear_encounter(event_index: int) -> void:
	var event: Dictionary = _encounters[event_index]
	event["done"] = true
	for area_variant in event.get("areas", []):
		var area: Area2D = area_variant as Area2D
		if is_instance_valid(area):
			area.set_deferred("monitoring", false)
	_encounters[event_index] = event

func spawn_impact_particles(world_x: float, ground_y: float, intensity: float, landing_dust: bool = false) -> void:
	var particle_count: int = 5 if landing_dust else 8 + int(round(clampf(intensity, 0.0, 1.0) * 8.0))
	for _particle_index in range(particle_count):
		var velocity := Vector2(randf_range(-190.0, 120.0), randf_range(-240.0, -55.0)) * (0.65 + intensity * 0.5)
		_impact_particles.append({
			"position": Vector2(world_x + randf_range(-10.0, 10.0), ground_y - randf_range(8.0, 28.0)),
			"velocity": velocity,
			"life": randf_range(0.22, 0.52),
			"size": randf_range(2.0, 4.2),
			"color": Color8(183, 166, 139, 145) if landing_dust else (Color8(255, 192, 100, 240) if randf() > 0.32 else Color8(141, 132, 107, 230))
		})
	queue_redraw()

func spawn_timber_fragments(world_x: float, ground_y: float, speed_mps: float) -> void:
	for index in range(5):
		_impact_particles.append({
			"position": Vector2(world_x + float(index - 2) * 16.0, ground_y - 46.0),
			"velocity": Vector2(clampf(speed_mps * 7.0, 35.0, 230.0) + randf_range(-35.0, 65.0), randf_range(-245.0, -110.0)),
			"life": randf_range(0.43, 0.69), "size": randf_range(12.0, 23.0),
			"color": Color8(157, 68, 48) if index % 2 == 0 else Color8(222, 199, 146),
			"angle": randf_range(-0.25, 0.25), "spin": randf_range(-11.0, 11.0)
		})
	queue_redraw()

func _draw() -> void:
	_draw_environment()
	_draw_track()
	_draw_roadside_markers()
	_draw_encounters()
	_draw_reactions()
	_draw_impact_particles()

func _draw_environment() -> void:
	draw_rect(Rect2(-1600.0, -1200.0, COURSE_LENGTH_M * PIXELS_PER_METER + 3200.0, 2100.0), Color8(108, 132, 132))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-1600.0, 180.0), Vector2(6000.0, 235.0), Vector2(14000.0, 180.0),
		Vector2(23500.0, 240.0), Vector2(33800.0, 190.0), Vector2(33800.0, 760.0), Vector2(-1600.0, 760.0)
	]), Color8(122, 138, 127, 110))
	draw_circle(Vector2(2750.0, 226.0), 39.0, Color8(225, 181, 126, 215))
	draw_rect(Rect2(-1600.0, 430.0, COURSE_LENGTH_M * PIXELS_PER_METER + 3200.0, 330.0), Color8(68, 91, 89, 120))
	for building_index in range(24):
		var x: float = -700.0 + float(building_index) * 1450.0
		var height: float = 70.0 + float((building_index * 37) % 115)
		var width: float = 115.0 + float((building_index * 23) % 75)
		var top: float = 420.0 - height
		draw_rect(Rect2(x, top, width, height), Color8(63, 78, 73, 145))
		draw_rect(Rect2(x + 11.0, top - 8.0, width * 0.56, 8.0), Color8(75, 87, 77, 145))
		for window_index in range(3):
			var window_x: float = x + 14.0 + float(window_index) * 27.0
			draw_rect(Rect2(window_x, top + 15.0, 9.0, 13.0), Color8(191, 151, 99, 115))
		if building_index % 3 == 1:
			var mast_x: float = x + width + 52.0
			draw_line(Vector2(mast_x, 420.0), Vector2(mast_x, 305.0), Color8(48, 65, 63, 170), 3.0, true)
			draw_line(Vector2(mast_x - 48.0, 328.0), Vector2(mast_x + 55.0, 328.0), Color8(48, 65, 63, 170), 2.0, true)
			draw_line(Vector2(mast_x, 307.0), Vector2(mast_x - 48.0, 328.0), Color8(48, 65, 63, 170), 1.6, true)
			draw_line(Vector2(mast_x, 307.0), Vector2(mast_x + 55.0, 328.0), Color8(48, 65, 63, 170), 1.6, true)
	for pylon_index in range(7):
		var pylon_x: float = 700.0 + float(pylon_index) * 4550.0
		var top_y: float = 230.0 + float(pylon_index % 2) * 42.0
		draw_line(Vector2(pylon_x - 36.0, 430.0), Vector2(pylon_x, top_y), Color8(51, 65, 62, 160), 2.1, true)
		draw_line(Vector2(pylon_x + 38.0, 430.0), Vector2(pylon_x, top_y), Color8(51, 65, 62, 160), 2.1, true)
		draw_line(Vector2(pylon_x - 51.0, top_y + 44.0), Vector2(pylon_x + 50.0, top_y + 44.0), Color8(51, 65, 62, 160), 2.0, true)
		draw_line(Vector2(pylon_x - 31.0, top_y + 88.0), Vector2(pylon_x + 31.0, top_y + 88.0), Color8(51, 65, 62, 160), 1.8, true)
		draw_line(Vector2(pylon_x - 55.0, top_y + 44.0), Vector2(pylon_x + 55.0, top_y + 44.0), Color8(51, 65, 62, 160), 1.8, true)

func _draw_track() -> void:
	var road_top := PackedVector2Array()
	var sample_count: int = int(COURSE_LENGTH_M / DRAW_SAMPLE_M)
	for sample_index in range(sample_count + 1):
		var meter: float = float(sample_index) * DRAW_SAMPLE_M
		if not has_road_surface(meter):
			_draw_road_segment(road_top)
			road_top.clear()
			continue
		road_top.append(Vector2(meter * PIXELS_PER_METER, height_at(meter * PIXELS_PER_METER)))
	_draw_road_segment(road_top)
	for marker_meter in [68.0, 137.0, 221.0, 317.0, 407.0, 454.0, 585.0, 699.0, 780.0]:
		var marker_x: float = marker_meter * PIXELS_PER_METER
		var ground_y: float = height_at(marker_x)
		for chevron_index in range(3):
			var x: float = marker_x + float(chevron_index) * 32.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - 7.0, ground_y + 3.0), Vector2(x + 4.0, ground_y - 5.0),
				Vector2(x + 8.0, ground_y - 2.0), Vector2(x - 3.0, ground_y + 6.0)
			]), Color8(207, 169, 100, 220))
	var lip_x: float = JUMP_LIP_M * PIXELS_PER_METER
	var land_x: float = JUMP_LANDING_M * PIXELS_PER_METER
	draw_line(Vector2(lip_x - 18.0, height_at(lip_x) - 3.0), Vector2(lip_x + 4.0, height_at(lip_x) + 15.0), Color8(234, 150, 73), 4.0, true)
	draw_line(Vector2(land_x - 16.0, height_at(land_x) + 19.0), Vector2(land_x + 30.0, height_at(land_x) - 2.0), Color8(234, 150, 73), 3.0, true)

func _draw_road_segment(top_edge: PackedVector2Array) -> void:
	if top_edge.size() < 2:
		return
	# A textured retaining wall continues below the same physical road strip.
	# This prevents the lower background panorama from peeking through as sky.
	const WALL_BOTTOM_Y: float = 1120.0
	var wall_top := PackedVector2Array()
	for point in top_edge:
		wall_top.append(point + Vector2(0.0, 40.0))
	var wall := PackedVector2Array(wall_top)
	wall.append(Vector2(top_edge[top_edge.size() - 1].x, WALL_BOTTOM_Y))
	wall.append(Vector2(top_edge[0].x, WALL_BOTTOM_Y))
	if _wall_tile == null:
		_wall_tile = load("res://assets/amsterdam_quay_brick_tile.svg")
	var tile_size: Vector2 = _wall_tile.get_size()
	var wall_uvs := PackedVector2Array()
	for point in wall:
		wall_uvs.append(Vector2(point.x / tile_size.x, point.y / tile_size.y))
	draw_colored_polygon(wall, Color.WHITE, wall_uvs, _wall_tile)
	var road_polygon := PackedVector2Array(top_edge)
	for index in range(top_edge.size() - 1, -1, -1):
		road_polygon.append(top_edge[index] + Vector2(0.0, 40.0))
	draw_colored_polygon(road_polygon, Color8(47, 57, 53))
	draw_polyline(top_edge, Color8(204, 172, 107), 7.0, true)
	var lane_marks := PackedVector2Array()
	for point in top_edge:
		lane_marks.append(point + Vector2(0.0, 14.0))
	draw_polyline(lane_marks, Color8(122, 127, 113), 2.0, true)
	var under_edge := PackedVector2Array()
	for point in top_edge:
		under_edge.append(point + Vector2(0.0, 40.0))
	draw_polyline(under_edge, Color8(29, 35, 32), 3.0, true)

func _draw_roadside_markers() -> void:
	var post_meter: float = 25.0
	while post_meter < COURSE_LENGTH_M:
		var post_x: float = post_meter * PIXELS_PER_METER
		var ground: float = height_at(post_x)
		draw_line(Vector2(post_x, ground - 4.0), Vector2(post_x, ground - 33.0), Color8(91, 102, 83), 2.0, true)
		draw_circle(Vector2(post_x, ground - 35.0), 3.0, Color8(226, 180, 97))
		post_meter += 38.0

func _draw_encounters(draw_zombies: bool = true) -> void:
	var camera := get_viewport().get_camera_2d()
	var view_center: float = camera.get_screen_center_position().x if camera != null else 0.0
	var view_reach: float = get_viewport_rect().size.x * 0.5 / maxf(0.1, camera.zoom.x) + 250.0 if camera != null else INF
	for event in _encounters:
		var kind: String = String(event["kind"])
		if kind in ["zombie_group", "runner_group"]:
			if not draw_zombies:continue
			if bool(event.get("done", false)):
				continue
			var members_data: Array = event.get("members_data", [])
			var profile: Dictionary = ZOMBIE_DATA.profile(int(event["variant"]))
			for member in members_data:
				if bool(member.get("hit", false)):
					continue
				var area: Area2D = member.get("area") as Area2D
				if is_instance_valid(area):
					var x: float = area.position.x
					if absf(x - view_center) > view_reach:
						continue
					var ground: float = _encounter_ground_at(x, event)
					var charge: float = clampf(1.0 - (x - _wagon.position.x - _wagon.front_contact_offset_px()) / (90.0 * PIXELS_PER_METER), 0.25, 1.0) if _wagon != null else 0.25
					_draw_zombie(x, ground, int(event["variant"]), "fast" if kind == "runner_group" else "slow", charge, float(member.get("run_phase", member.get("phase", 0.0))), float(member.get("facing", 1.0)))
		else:
			var x: float = float(event["meter"]) * PIXELS_PER_METER
			if absf(x - view_center) > view_reach:
				continue
			var ground: float = height_at(x)
			_draw_encounter_object(x, ground, event)

func _draw_encounter_object(world_x: float, ground: float, event: Dictionary) -> void:
	var kind: String = String(event["kind"])
	if bool(event.get("done", false)):
		_draw_broken_debris(world_x, ground, kind)
	elif kind == "light_obstacle":
		_draw_light_barrier(world_x, ground)
	else:
		_draw_heavy_wreck(world_x, ground)

func _draw_zombie(world_x: float, ground: float, variant: int, zombie_class: String, charge: float, member_phase: float, facing: float = 1.0) -> void:
	var texture: Texture2D = _zombie_texture_for_variant(variant)
	var image_height: float = float(ZOMBIE_DATA.profile(variant).get("visual_height", 78.0))
	var phase: float = member_phase
	var gait: Dictionary = _zombie_data.walk_motion(phase, charge)
	var bob: float = float(gait["bob"])
	var squash: float = float(gait["squash"])
	var frame_source: Rect2 = Rect2(Vector2.ZERO, texture.get_size())
	if variant == 1:
		var frame_index: int = posmod(int(floor(fposmod(phase, TAU) / TAU * ZOMBIE_NORMAL_RUN_FRAMES.size())), ZOMBIE_NORMAL_RUN_FRAMES.size())
		frame_source = ZOMBIE_NORMAL_RUN_FRAMES[frame_index]
	elif variant == 2:
		texture = ZOMBIE_DATA.RUNNER_CHARGE_TEXTURE
		frame_source = ZOMBIE_DATA.runner_charge_frame(floori(phase / TAU * 4.0))
	elif variant >= 3:
		texture = ZOMBIE_DATA.HEAVY_WALK_TEXTURES[variant]
		frame_source = ZOMBIE_DATA.heavy_walk_frame(variant, floori(phase / TAU * 4.0))
		image_height *= ZOMBIE_DATA.heavy_frame_height_scale(variant, frame_source)
	var image_width: float = image_height * frame_source.size.x / maxf(1.0, frame_source.size.y)
	var lean: float = -charge * 0.055 + float(gait["body_roll"]) * 0.5
	draw_set_transform(Vector2(world_x, ground), 0.0, Vector2(image_height * 0.27, 2.5))
	draw_circle(Vector2.ZERO, 1.0, Color8(24, 31, 27, 95))
	draw_set_transform(Vector2(world_x - facing * charge * 4.0, ground - bob), lean * facing, Vector2(facing * (1.0 + squash), 1.0 - squash * 0.6))
	draw_texture_rect_region(texture, Rect2(Vector2(-image_width * 0.5 - 0.9, -image_height), Vector2(image_width, image_height)), frame_source, Color8(23, 23, 20, 175))
	draw_texture_rect_region(texture, Rect2(Vector2(-image_width * 0.5, -image_height), Vector2(image_width, image_height)), frame_source)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_light_barrier(world_x: float, ground: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 18.0, ground - 3.0), Vector2(world_x - 18.0, ground - 21.0),
		Vector2(world_x + 18.0, ground - 21.0), Vector2(world_x + 18.0, ground - 3.0)
	]), Color8(163, 94, 57))
	draw_rect(Rect2(world_x - 19.0, ground - 16.0, 38.0, 5.0), Color8(213, 190, 143))
	draw_rect(Rect2(world_x - 19.0, ground - 7.0, 38.0, 4.0), Color8(49, 57, 51))
	for stripe_index in range(4):
		var x: float = world_x - 16.0 + float(stripe_index) * 11.0
		draw_line(Vector2(x, ground - 21.0), Vector2(x + 7.0, ground - 16.0), Color8(235, 187, 111), 2.0, true)

func _draw_heavy_wreck(world_x: float, ground: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 39.0, ground - 5.0), Vector2(world_x - 32.0, ground - 30.0),
		Vector2(world_x - 14.0, ground - 43.0), Vector2(world_x + 21.0, ground - 36.0),
		Vector2(world_x + 39.0, ground - 18.0), Vector2(world_x + 37.0, ground - 5.0)
	]), Color8(72, 78, 68))
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 23.0, ground - 30.0), Vector2(world_x - 12.0, ground - 39.0),
		Vector2(world_x + 5.0, ground - 36.0), Vector2(world_x + 8.0, ground - 25.0)
	]), Color8(70, 103, 100))
	draw_line(Vector2(world_x - 37.0, ground - 5.0), Vector2(world_x + 38.0, ground - 5.0), Color8(173, 137, 86), 3.0, true)
	for wheel_x in [-22.0, 25.0]:
		draw_circle(Vector2(world_x + wheel_x, ground - 3.0), 8.0, Color8(32, 37, 34))
		draw_circle(Vector2(world_x + wheel_x, ground - 3.0), 3.0, Color8(157, 140, 98))
	draw_line(Vector2(world_x - 3.0, ground - 34.0), Vector2(world_x + 30.0, ground - 30.0), Color8(193, 142, 90), 2.0, true)

func _draw_broken_debris(world_x: float, ground: float, kind: String) -> void:
	if kind == "light_obstacle":
		draw_colored_polygon(PackedVector2Array([
			Vector2(world_x - 24.0, ground - 3.0), Vector2(world_x - 15.0, ground - 10.0),
			Vector2(world_x - 4.0, ground - 4.0), Vector2(world_x + 7.0, ground - 9.0),
			Vector2(world_x + 23.0, ground - 2.0)
		]), Color8(154, 94, 58, 205))
		return
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 37.0, ground - 4.0), Vector2(world_x - 31.0, ground - 20.0),
		Vector2(world_x + 25.0, ground - 10.0), Vector2(world_x + 36.0, ground - 3.0)
	]), Color8(61, 70, 63))
	draw_line(Vector2(world_x - 25.0, ground - 11.0), Vector2(world_x + 25.0, ground - 6.0), Color8(164, 126, 82), 2.0, true)

func _draw_reactions() -> void:
	for reaction in _reactions:
		var progress: float = 1.0 - float(reaction["time_left"]) / maxf(0.01, float(reaction["duration"]))
		var members_data: Array = reaction.get("members", [])
		var variant_id: int = int(reaction.get("variant", 1))
		var texture: Texture2D = _zombie_texture_for_variant(variant_id)
		var profile: Dictionary = ZOMBIE_DATA.profile(variant_id)
		var image_height: float = float(profile.get("visual_height", 78.0))
		var frame_source: Rect2 = Rect2(Vector2.ZERO, texture.get_size())
		if variant_id == 1:
			frame_source = ZOMBIE_NORMAL_RUN_FRAMES[1]
		var image_width: float = image_height * frame_source.size.x / maxf(1.0, frame_source.size.y)
		for member_index in range(members_data.size()):
			var member: Dictionary = members_data[member_index]
			var start_x: float = float(member.get("x", 0.0))
			var ground: float = float(reaction.get("ground_y", BASELINE_Y))
			var shot: bool = not reaction.has("speed_mps")
			var motion: Vector3 = Vector3(-progress * 66.0, sin(progress * PI) * 52.0, -progress * 1.9) if shot else ZOMBIE_DATA.impact_pose(variant_id, float(reaction["speed_mps"]), progress, member_index, int(reaction["seed"]))
			var angle: float = motion.z
			var floor_extent: float = (absf(cos(angle)) * image_height + absf(sin(angle)) * image_width) * 0.46
			var center := Vector2(start_x + motion.x, ground - floor_extent - motion.y)
			var size := Vector2(image_width, image_height)
			draw_set_transform(center, angle, Vector2.ONE)
			draw_texture_rect_region(texture, Rect2(-size * 0.5, size), frame_source, Color(1.0, 1.0, 1.0, 1.0 - smoothstep(0.76, 1.0, progress)))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _zombie_texture_for_variant(variant_id: int) -> Texture2D:
	match variant_id:
		1:
			return ZOMBIE_NORMAL_RUN_TEXTURE
		2:
			return ZOMBIE_RUNNER_TEXTURE
		3:
			return ZOMBIE_WORKER_TEXTURE
		4:
			return ZOMBIE_RIOT_TEXTURE
		_:
			return ZOMBIE_BRUTE_TEXTURE

func _draw_impact_particles() -> void:
	for particle in _impact_particles:
		var position: Vector2 = Vector2(particle.get("position", Vector2.ZERO))
		var velocity: Vector2 = Vector2(particle.get("velocity", Vector2.ZERO))
		var life_fraction: float = clampf(float(particle.get("life", 0.0)) / 0.52, 0.0, 1.0)
		var color: Color = Color(particle.get("color", Color.WHITE))
		color.a *= life_fraction
		var size: float = float(particle.get("size", 2.0))
		if particle.has("spin"):
			if particle.has("texture"):
				draw_set_transform(position,float(particle["angle"]))
				draw_texture_rect_region(particle["texture"],Rect2(-size*.55,-2.5,size*1.05,5),particle["source"],Color(1,1,1,life_fraction))
				draw_set_transform(Vector2.ZERO)
				continue
			var edge: Vector2 = Vector2.from_angle(float(particle["angle"]))
			var side: Vector2 = edge.orthogonal()
			draw_colored_polygon(PackedVector2Array([
				position - edge * size * 0.55 - side * 2.4,
				position + edge * size * 0.5 - side * 2.1,
				position + edge * size * 0.35 + side * 2.7,
				position - edge * size * 0.44 + side * 2.0
			]), color)
			continue
		draw_line(position, position - velocity.normalized() * size * 2.4, color, maxf(1.2, size * 0.65), true)

func debris_floor_at(world_x: float) -> float:
	return height_at(world_x)

func _shoot_close_zombie() -> bool:
	var front_x: float = _wagon.position.x + _wagon.front_contact_offset_px()
	var closest: float = 6.0 * PIXELS_PER_METER
	var target: Dictionary = {}
	var target_event: Dictionary = {}
	for event in _encounters:
		if bool(event["done"]) or String(event["kind"]) not in ["zombie_group", "runner_group"]:
			continue
		for member: Dictionary in event["members_data"]:
			var area: Area2D = member["area"]
			if bool(member["hit"]) or not is_instance_valid(area):
				continue
			var gap: float = area.position.x - front_x
			if gap >= 0.0 and gap <= closest and absf(area.position.y - _wagon.position.y) <= 80.0:
				closest = gap
				target = member
				target_event = event
	if target.is_empty():
		return false
	var hit_area: Area2D = target["area"]
	var ground: float = _encounter_ground_at(hit_area.position.x, target_event)
	target["hit"] = true
	target_event["done"] = (target_event["members_data"] as Array).all(func(member: Dictionary) -> bool: return bool(member.get("hit", false)))
	hit_area.set_deferred("monitoring", false)
	_wagon.show_weapon_shot(hit_area.position)
	spawn_impact_particles(hit_area.position.x, ground, 0.42)
	_reactions.append({"variant": target_event["variant"], "members": [target.duplicate()], "time_left": 1.1, "duration": 1.1, "ground_y": ground, "speed_mps": minf(9.0, absf(_wagon.speed_mps) * 0.30), "seed": floori(hit_area.position.x / PIXELS_PER_METER)})
	zombie_shot.emit()
	return true

