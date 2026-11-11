extends DrivingTestCourse

signal worksite_event(message: String, impact: float)
signal oil_drums_shot
signal motor_part_found
signal loading_edge_broke
signal route_decided(route_name: String, upper_route: bool)
signal bonus_coin_collected(amount: int)

const BRANCH_DECISION_M: float = 399.0
const BRANCH_START_M: float = 405.0
const BRANCH_END_M: float = 478.0
const BONUS_M: float = 444.0
const MIN_BRIDGE_SPEED_KMH: float = 65.0
const ART = preload("res://levels/utrecht/worksite_art.gd")

const PUMP_ENTRY_M := 1124.0
const PUMP_DECK_M := 1152.8
const PUMP_DROP_M := 1160.2
const PUMP_EXIT_M := 1175.0
const PUMP_DECK_Y := 445.0
const PUMP_TIME := 0.46
const PUMP_BONUS := 14
const TILT_START_M := 888.0
const TILT_FLOOR_M := 903.0
const TILT_EXIT_M := 914.0
const TILT_DEPTH := 110.0
const Crossing = preload("res://levels/utrecht/tilting_crossing.gd")
const LOADING_START_M := 597.0
const LOADING_EDGE_M := 614.0
const LOADING_LIP_M := 617.0
const LOADING_KAI_M := 635.0
const LOADING_END_M := 663.0
const LOADING_HEIGHT := 451.0
const PLATE_START_M := 683.0
const PLATE_JOIN_M := 698.0
const PLATE_CREST_M := 707.0
const LOAD_GATE_M := 1210.0
const LOAD_OFFSET := 240.0
const LOAD_CLEAR_TIME := 3.5
const LOADING_BONUS := 18
const ROLL_BONUS := 8
const SAND_START_M := 923.0
const SAND_LIP_M := 947.0
const GIRDER_START_M := 979.0
const GIRDER_DESCENT_M := 1017.0
const GIRDER_END_M := 1044.0
const GIRDER_DECK_Y := 410.0
const SCAFFOLD_START_M := 990.0
const SCAFFOLD_END_M := 997.0
const SCAFFOLD_LOAD_TIME := 0.70
const SCAFFOLD_BONUS := 16
const FORMWORK_M := 1066.0
const LENGTH_M: float = 1400.0
const PART_M: float = 679.0
const DOCK_DRUM_M := 580.0
const DOCK_FENCE_M := 590.0
const LAYOUT: Array[Dictionary] = [
	{"kind":"light_obstacle", "meter":48.0, "variant":0, "members":1, "resistance":0.12, "prop":"work_fence"},
	{"kind":"light_obstacle", "meter":103.0, "variant":0, "members":1, "resistance":0.16, "prop":"pallet_stack"},
	{"kind":"light_obstacle", "meter":233.0, "variant":0, "members":1, "resistance":0.18, "prop":"oil_drums", "blast_zone":"entry"},
	{"kind":"light_obstacle", "meter":237.0, "variant":0, "members":1, "resistance":0.18, "prop":"oil_drums", "blast_zone":"entry"},
	{"kind":"light_obstacle", "meter":241.0, "variant":0, "members":1, "resistance":0.23, "prop":"work_fence", "blast_zone":"entry"},
	{"kind":"runner_group", "meter":243.0, "variant":2, "members":1, "resistance":0.0, "blast_zone":"entry"},
	{"kind":"zombie_group", "meter":74.0, "variant":1, "members":2, "resistance":0.0},
	{"kind":"light_obstacle", "meter":138.0, "variant":0, "members":1, "resistance":0.30, "prop":"road_sign"},
	{"kind":"runner_group", "meter":196.0, "variant":2, "members":2, "resistance":0.0},
	{"kind":"light_obstacle", "meter":304.0, "variant":0, "members":1, "resistance":0.38, "prop":"work_fence"},
	{"kind":"zombie_group", "meter":350.0, "variant":3, "members":2, "resistance":0.0},
	{"kind":"heavy_obstacle", "meter":442.0, "variant":0, "members":1, "resistance":0.62, "prop":"drain_pipes"},
	{"kind":"runner_group", "meter":541.0, "variant":2, "members":2, "resistance":0.0, "agile_chase":true},
	{"kind":"light_obstacle", "meter":DOCK_DRUM_M, "variant":0, "members":1, "resistance":0.21, "prop":"cable_spool"},
	{"kind":"light_obstacle", "meter":DOCK_FENCE_M, "variant":0, "members":1, "resistance":0.22, "prop":"work_fence"},
	{"kind":"light_obstacle", "meter":629.0, "variant":0, "members":1, "resistance":0.14, "prop":"pallet_stack"},
	{"kind":"light_obstacle", "meter":651.0, "variant":0, "members":1, "resistance":0.15, "prop":"work_fence"},
	{"kind":"runner_group", "meter":724.0, "variant":2, "members":1, "resistance":0.0},
	{"kind":"zombie_group", "meter":737.0, "variant":3, "members":2, "resistance":0.0, "agile_chase":true},
	{"kind":"light_obstacle", "meter":765.0, "variant":0, "members":1, "resistance":0.28, "prop":"pallet_stack"},
	{"kind":"zombie_group", "meter":806.0, "variant":1, "members":1, "resistance":0.0},
	{"kind":"light_obstacle", "meter":851.0, "variant":0, "members":1, "resistance":0.18, "prop":"pallet_stack"},
	{"kind":"light_obstacle", "meter":859.0, "variant":0, "members":1, "resistance":0.26, "prop":"oil_drums"},
	{"kind":"runner_group", "meter":864.0, "variant":2, "members":1, "resistance":0.0},
	{"kind":"light_obstacle", "meter":879.0, "variant":0, "members":1, "resistance":0.18, "prop":"road_sign"},
	{"kind":"zombie_group", "meter":1009.0, "variant":3, "members":1, "resistance":0.0, "agile_chase":true, "blast_zone":"excavation"},
	{"kind":"light_obstacle", "meter":1012.0, "variant":0, "members":1, "resistance":0.20, "prop":"oil_drums", "blast_zone":"excavation"},
	{"kind":"light_obstacle", "meter":1016.5, "variant":0, "members":1, "resistance":0.16, "prop":"oil_drums", "blast_zone":"excavation"},
	{"kind":"light_obstacle", "meter":1018.0, "variant":0, "members":1, "resistance":0.18, "prop":"work_fence", "blast_zone":"excavation"},
	{"kind":"runner_group", "meter":1019.0, "variant":2, "members":1, "resistance":0.0, "blast_zone":"excavation"},
	{"kind":"light_obstacle", "meter":FORMWORK_M, "variant":0, "members":1, "resistance":0.23, "prop":"work_fence"},
	{"kind":"light_obstacle", "meter":1004.0, "variant":0, "members":1, "resistance":0.0, "prop":"supply_crate"},
	{"kind":"light_obstacle", "meter":1030.0, "variant":0, "members":1, "resistance":0.20, "prop":"pallet_stack", "girder":true},
	{"kind":"light_obstacle", "meter":1044.0, "variant":0, "members":1, "resistance":0.0, "prop":"supply_crate"},
	{"kind":"light_obstacle", "meter":1134.0, "variant":0, "members":1, "resistance":0.30, "prop":"work_fence"},
	{"kind":"light_obstacle", "meter":1210.0, "variant":0, "members":1, "resistance":0.14, "prop":"load_chock"},
	{"kind":"light_obstacle", "meter":1244.0, "variant":0, "members":1, "resistance":0.0, "prop":"supply_crate"},
	{"kind":"light_obstacle", "meter":1274.0, "variant":0, "members":1, "resistance":0.22, "prop":"oil_drums", "blast_zone":"scrapyard"},
	{"kind":"light_obstacle", "meter":1280.0, "variant":0, "members":1, "resistance":0.22, "prop":"oil_drums", "blast_zone":"scrapyard"},
	{"kind":"zombie_group", "meter":1284.0, "variant":4, "members":2, "resistance":0.0, "blast_zone":"scrapyard"},
	{"kind":"heavy_obstacle", "meter":1286.0, "variant":0, "members":1, "resistance":0.62, "prop":"scrap_wall", "blast_zone":"scrapyard"},
	{"kind":"zombie_group", "meter":1320.0, "variant":1, "members":2, "resistance":0.0, "agile_chase":true},
]

var _weapon_cooldown := 0.0
var pump_deck: StaticBody2D
var pump_exit: StaticBody2D
var pump_load := -1.0
var pump_fell := false
var pump_cleared := false
var _pump_art_layer := Node2D.new()
var collapse_site := preload("res://scripts/route_collapse.gd").new()
var part_found: bool = false
var upper_route: bool = false
var bonus_taken: bool = false
var _route_committed: bool = false
var _lower_body: StaticBody2D
var _upper_body: StaticBody2D
var _rolling_pipes: Array[Dictionary] = []
var _barrel_bursts: Array[Dictionary] = []
var _blast_queue: Array[Dictionary] = []
var _dock_spool: Dictionary = {}
var girder_landed := false
var girder_bonus := false
var _clean_girder_landing := false
var _girder_body: StaticBody2D
var _scaffold_body: StaticBody2D
var _girder_exit_body: StaticBody2D
var scaffold_load := -1.0
var scaffold_sag := 0.0
var scaffold_fall := -1.0
var scaffold_crossed := false
var formwork_fall := -1.0
var _art := ART.new()
var _impact_art := preload("res://levels/utrecht/impact_art.gd").new()
var _wheel_dust_left := 0.0
var loading_edge: StaticBody2D
var loading_kai: StaticBody2D
var loading_timer := -1.0
var loading_broken := false
var loading_landed := false
var loading_missed := false
var loading_bonus_paid := false
var rolling_load: Dictionary = {}
var roll_bonus_paid := false
var tilt_crossing: AnimatableBody2D
var tilt_in_pit := false
var tilt_bonus_paid := false

func _ready() -> void:
	super._ready()
	encounter_hit.connect(_on_worksite_hit)
	collapse_site.setup(self, {
		"meter": 1156.5, "title": "PUMPWERK", "lead": 700.0, "fuse": 0.05, "stagger": 0.44, "slide": -0.62, "manual_trigger": true,
		"floor_height": func(x: float) -> float: return _lower_height(x / PIXELS_PER_METER),
		"building": "res://levels/utrecht/art/collapse_pumpworks.png",
		"source": Rect2(94, 7, 961, 1296), "rows": [0.0, 0.37, 0.55, 0.73, 1.0], "height": 318.0,
	})
	collapse_site.name = "CollapseSite"
	add_child(collapse_site)
	add_child(_pump_art_layer)
	_pump_art_layer.draw.connect(_draw_pump_route)

func preview_city_name() -> String:
	return "Utrecht"

func preview_length_m() -> float:
	return LENGTH_M

func fuel_factor() -> float:
	return 0.70

func road_end_m() -> float:
	return START_M + LENGTH_M + 25.0

func has_road_surface(_meter: float) -> bool:
	return true

func encounter_layout() -> Array[Dictionary]:
	return LAYOUT

func zombie_approach_distance_m() -> float:
	return 22.0

func height_at(world_x: float) -> float:
	var meter := world_x / PIXELS_PER_METER
	if upper_route and meter >= BRANCH_START_M and meter <= BRANCH_END_M:
		return _upper_height(meter)
	if meter >= LOADING_START_M and meter < LOADING_LIP_M and (not loading_broken or meter < LOADING_EDGE_M):
		return loading_ramp_height(meter)
	if loading_landed and meter >= LOADING_KAI_M and meter < LOADING_END_M:
		return loading_kai_height(meter)
	if meter >= PUMP_ENTRY_M and meter < PUMP_DECK_M:
		return pump_ramp_height(meter)
	if not pump_fell and meter >= PUMP_DECK_M and meter <= PUMP_EXIT_M:
		return pump_upper_height(meter)
	if meter >= SAND_START_M and meter <= SAND_LIP_M:
		return _sand_height(meter)
	if girder_landed and scaffold_fall < 0.0 and meter >= GIRDER_START_M and meter <= GIRDER_END_M:
		return _girder_height(meter) + (scaffold_sag if meter >= SCAFFOLD_START_M and meter < SCAFFOLD_END_M else 0.0)
	return _lower_height(meter)

func loading_ramp_height(meter: float) -> float:
	var t := clampf(inverse_lerp(LOADING_START_M, LOADING_LIP_M, meter), 0.0, 1.0)
	return 520.0 - 92.0 * t * t

func loading_kai_height(meter: float) -> float:
	return lerpf(LOADING_HEIGHT, 520.0, smoothstep(646.0, LOADING_END_M, meter))

func pump_ramp_height(meter: float) -> float:
	return lerpf(_lower_height(PUMP_ENTRY_M), PUMP_DECK_Y, smoothstep(PUMP_ENTRY_M, PUMP_DECK_M, meter))

func pump_upper_height(meter: float) -> float:
	var merge := smoothstep(PUMP_DROP_M, PUMP_EXIT_M, meter)
	return lerpf(PUMP_DECK_Y, _lower_height(meter), merge)

func _sand_height(meter: float) -> float:
	var progress := clampf(inverse_lerp(SAND_START_M, SAND_LIP_M, meter), 0.0, 1.0)
	return 520.0 - 135.0 * progress * progress

func _girder_height(meter: float) -> float:
	return lerpf(GIRDER_DECK_Y, _lower_height(meter), smoothstep(GIRDER_DESCENT_M, GIRDER_END_M, meter))

func _encounter_ground_at(world_x: float, event: Dictionary) -> float:
	var meter := world_x / PIXELS_PER_METER
	if event.get("girder", false):
		return _girder_height(meter)
	if meter >= SAND_START_M and meter <= GIRDER_END_M:
		return _lower_height(meter)
	return super._encounter_ground_at(world_x, event)

func _lower_height(meter: float) -> float:
	var depot_dip := 42.0 * smoothstep(813.0, 835.0, meter) * (1.0 - smoothstep(874.0, 887.0, meter))
	var roughness := smoothstep(281.0, 293.0, meter) * (1.0 - smoothstep(369.0, 387.0, meter))
	roughness += smoothstep(755.0, 770.0, meter) * (1.0 - smoothstep(825.0, 842.0, meter))
	roughness += smoothstep(1162.0, 1180.0, meter) * (1.0 - smoothstep(1235.0, 1250.0, meter))
	var pit := TILT_DEPTH * smoothstep(TILT_START_M, TILT_START_M + 6.0, meter) * (1.0 - smoothstep(TILT_FLOOR_M, TILT_EXIT_M, meter))
	var excavation := 54.0 * smoothstep(969.0, 987.0, meter) * (1.0 - smoothstep(1021.0, 1041.0, meter))
	var pipe_crown := 27.0 * smoothstep(1018.5, 1021.0, meter) * (1.0 - smoothstep(1021.0, 1024.5, meter))
	return 520.0 + depot_dip + pit + excavation - pipe_crown + (sin(meter * 0.52) * 4.0 + sin(meter * 0.92) * 1.25) * roughness \
		+ _hump_offset(meter, 211.0, 232.0, 279.0, 180.0, 0.0) \
		- _hump_offset(meter, 405.0, 423.0, 478.0, 106.0, 0.0) + _hump_offset(meter, 485.0, 511.0, 554.0, 138.0, 0.0) \
		+ 43.0 * smoothstep(LOADING_START_M, 620.0, meter) * (1.0 - smoothstep(643.0, LOADING_END_M, meter)) \
		+ 32.0 * smoothstep(PLATE_START_M, PLATE_JOIN_M, meter) * (1.0 - smoothstep(PLATE_JOIN_M, PLATE_CREST_M, meter)) \
		+ 7.0 * smoothstep(697.0, 698.0, meter) * (1.0 - smoothstep(698.0, 702.0, meter)) \
		+ _hump_offset(meter, 1045.0, 1074.0, 1130.0, 160.0, 0.0) + _hump_offset(meter, 1158.0, 1162.0, 1168.0, 12.0, 0.0)

func _upper_height(meter: float) -> float:
	return 520.0 + _hump_offset(meter, BRANCH_START_M, 433.0, BRANCH_END_M, 44.0, 0.0)

func _build_road_collision() -> void:
	_build_surface(0.0, BRANCH_START_M, _lower_height, "QuayApproach")
	_lower_body = _build_surface(BRANCH_START_M, BRANCH_END_M, _lower_height, "SteelPlateLane")
	_upper_body = _build_surface(BRANCH_START_M, BRANCH_END_M, _upper_height, "TemporaryBridge")
	_upper_body.collision_layer = 0
	_build_surface(BRANCH_END_M, road_end_m(), _lower_height, "QuayExit")
	_build_surface(LOADING_START_M, LOADING_EDGE_M, loading_ramp_height, "LoadingRamp")
	loading_edge = _build_surface(LOADING_EDGE_M, LOADING_LIP_M, loading_ramp_height, "BreakawayBoards")
	loading_kai = _build_surface(LOADING_KAI_M, LOADING_END_M, loading_kai_height, "RaisedQuay")
	_build_surface(SAND_START_M, SAND_LIP_M, _sand_height, "SandRamp")
	_girder_body = _build_surface(GIRDER_START_M, SCAFFOLD_START_M, _girder_height, "GirderLanding")
	_scaffold_body = _build_surface(SCAFFOLD_START_M, SCAFFOLD_END_M, _girder_height, "BreakawayScaffold")
	_girder_exit_body = _build_surface(SCAFFOLD_END_M, GIRDER_END_M, _girder_height, "GirderExit")
	_build_surface(PUMP_ENTRY_M, PUMP_DECK_M, pump_ramp_height, "PumpApproach")
	pump_deck = _build_surface(PUMP_DECK_M, PUMP_DROP_M, pump_upper_height, "PumpBreakawayFloor")
	pump_exit = _build_surface(PUMP_DROP_M, PUMP_EXIT_M, pump_upper_height, "PumpExitRamp")
	tilt_crossing = Crossing.new()
	tilt_crossing.position = Vector2(TILT_START_M * PIXELS_PER_METER, 520.0)
	add_child(tilt_crossing)
	tilt_crossing.creaking.connect(_on_crossing_creak)
	tilt_crossing.support_broke.connect(_on_crossing_break)

func _build_surface(from_m: float, to_m: float, surface: Callable, label: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = label
	body.collision_mask = 0
	var segments := PackedVector2Array()
	var count := ceili((to_m - from_m) / COLLISION_SAMPLE_M)
	var previous := Vector2(from_m * PIXELS_PER_METER, float(surface.call(from_m)))
	for index in range(1, count + 1):
		var meter := lerpf(from_m, to_m, float(index) / float(count))
		var point := Vector2(meter * PIXELS_PER_METER, float(surface.call(meter)))
		segments.append(previous)
		segments.append(point)
		previous = point
	var shape := ConcavePolygonShape2D.new()
	shape.segments = segments
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body

func _build_encounters() -> void:
	super._build_encounters()
	for event in _encounters:
		var prop := String(event.get("prop", ""))
		if not _art.has_prop(prop) and prop != "supply_crate":
			continue
		var area := event.areas[0] as Area2D
		var shape := (area.get_child(0) as CollisionShape2D).shape as RectangleShape2D
		shape.size = Vector2(68.0, 43.0) if prop == "supply_crate" else _art.prop_size(prop) * Vector2(0.90, 0.95)
		area.position.y = _encounter_ground_at(area.position.x, event) - shape.size.y * 0.5
		if event.get("girder", false):
			area.monitoring = false

func reset_test_run(wagon: EscapeWagon) -> void:
	collapse_site.reset()
	_weapon_cooldown = 0.0
	pump_load = -1.0
	pump_fell = false
	pump_cleared = false
	pump_deck.collision_layer = 1
	pump_exit.collision_layer = 1
	upper_route = false
	loading_edge.collision_layer = 1
	loading_kai.collision_layer = 1
	loading_timer = -1.0
	loading_broken = false
	loading_landed = false
	loading_missed = false
	loading_bonus_paid = false
	rolling_load.clear()
	roll_bonus_paid = false
	tilt_crossing.reset()
	tilt_in_pit = false
	tilt_bonus_paid = false
	girder_landed = false
	girder_bonus = false
	_clean_girder_landing = false
	_girder_body.collision_layer = 1
	_scaffold_body.collision_layer = 1
	_girder_exit_body.collision_layer = 1
	scaffold_load = -1.0
	scaffold_sag = 0.0
	_scaffold_body.position.y = 0.0
	scaffold_fall = -1.0
	scaffold_crossed = false
	formwork_fall = -1.0
	if not wagon.landed.is_connected(_on_gravel_touchdown):
		wagon.landed.connect(_on_gravel_touchdown)
	bonus_taken = false
	_route_committed = false
	_rolling_pipes.clear()
	_impact_art.reset()
	_wheel_dust_left = 0.0
	_barrel_bursts.clear()
	_blast_queue.clear()
	_dock_spool.clear()
	_lower_body.collision_layer = 1
	_upper_body.collision_layer = 0
	part_found = false
	super.reset_test_run(wagon)

func _physics_process(delta: float) -> void:
	_update_weapon(delta)
	super._physics_process(delta)
	if not is_instance_valid(_wagon) or _wagon.freeze:
		return
	_apply_climb_resistance()
	_update_branch()
	_update_crossing(delta)
	_update_pumpworks(delta)
	_update_loading_ramp(delta)
	_update_rolling_load(delta)
	_update_dock_spool(delta)
	_update_blast_queue(delta)
	_update_girder_landing()
	_update_scaffold(delta)
	if formwork_fall >= 0.0:
		formwork_fall = minf(formwork_fall + delta, 1.0)
	_update_pipes(delta)
	_impact_art.tick(delta, height_at)
	_update_wheel_dust(delta)
	for index in range(_barrel_bursts.size() - 1, -1, -1):
		_barrel_bursts[index].age += delta
		if _barrel_bursts[index].age >= 1.0:
			_barrel_bursts.remove_at(index)
	if not part_found and _wagon.chassis_overlaps_world_rect(_part_bounds()):
		part_found = true
		motor_part_found.emit()
	queue_redraw()

func _update_weapon(delta: float) -> void:
	if not is_instance_valid(_wagon) or _wagon.freeze or not _wagon.weapon_active or _wagon.weapon_level <= 0:
		return
	_weapon_cooldown = maxf(0.0, _weapon_cooldown - delta)
	if _weapon_cooldown <= 0.0 and (_shoot_oil_drums() or _shoot_close_zombie()):
		_weapon_cooldown = 0.12

func _shoot_oil_drums() -> bool:
	var bumper := _wagon.position.x + _wagon.front_contact_offset_px()
	for index in range(_encounters.size()):
		var event: Dictionary = _encounters[index]
		if bool(event["done"]) or event.get("prop", "") != "oil_drums":
			continue
		var x := float(event["meter"]) * PIXELS_PER_METER
		var gap := x - bumper
		if gap < 0.0 or gap > 6.0 * PIXELS_PER_METER:
			continue
		var floor_y := _encounter_ground_at(x, event)
		var target := Vector2(x, floor_y - 30.0)
		if absf(target.y - _wagon.position.y) > 65.0:
			continue
		_clear_encounter(index)
		_wagon.show_weapon_shot(target)
		_on_worksite_hit("oil_drums", float(event["resistance"]), 0, 1, x, floor_y, absf(_wagon.speed_mps))
		oil_drums_shot.emit()
		return true
	return false


func _update_pumpworks(delta: float) -> void:
	if pump_fell or pump_cleared:
		return
	var front := _wagon.front_spring
	var rear := _wagon.rear_spring
	var front_floor := front.get_collider()
	var rear_floor := rear.get_collider()
	if pump_load < 0.0:
		if front_floor != pump_deck and rear_floor != pump_deck:
			return
		pump_load = 0.0
	pump_load += delta
	if rear_floor == pump_exit:
		pump_cleared = true
		bonus_coin_collected.emit(PUMP_BONUS)
	elif pump_load >= PUMP_TIME:
		pump_fell = true
		pump_deck.collision_layer = 0
		pump_exit.collision_layer = 0
		collapse_site.arm()

func _update_loading_ramp(delta: float) -> void:
	var x := _wagon.position.x / PIXELS_PER_METER
	var front := _wagon.front_spring
	var rear := _wagon.rear_spring
	if not loading_broken and (loading_timer >= 0.0 or front.get_collider() == loading_edge or rear.get_collider() == loading_edge):
		loading_timer = maxf(0.0, loading_timer) + delta
		if loading_timer >= 0.20:
			loading_broken = true
			loading_edge.collision_layer = 0
			loading_edge_broke.emit()
			var lip := (LOADING_EDGE_M + 1.0) * PIXELS_PER_METER
			_impact_art.burst(Vector2(lip, loading_ramp_height(LOADING_EDGE_M) + 5.0), 6.0, 0.30, "work_fence")
	if x < LOADING_LIP_M or x >= LOADING_END_M or loading_landed or loading_missed:
		return
	if front.get_collider() == loading_kai and rear.get_collider() == loading_kai:
		loading_landed = true
		if loading_broken and absf(_wagon.rotation) < 0.28:
			loading_bonus_paid = true
			bonus_coin_collected.emit(LOADING_BONUS)
	elif front.get_collider() != loading_kai and rear.get_collider() != loading_kai and _wagon.position.y > LOADING_HEIGHT - 32.0:
		loading_kai.collision_layer = 0
		loading_missed = true

func _update_rolling_load(delta: float) -> void:
	if rolling_load.is_empty():
		return
	rolling_load.age += delta
	var travel: float = rolling_load.speed * delta
	rolling_load.x += travel
	rolling_load.speed = move_toward(rolling_load.speed, 0.0, 108.0 * delta)
	rolling_load.angle += travel / 24.0
	var x: float = rolling_load.x
	var ground := _lower_height(x / PIXELS_PER_METER)
	var depth := smoothstep(3.12, LOAD_CLEAR_TIME, rolling_load.age)
	var radius := lerpf(24.0, 17.0, depth)
	if rolling_load.age < LOAD_CLEAR_TIME and not rolling_load.pushed and _wagon.chassis_overlaps_world_rect(Rect2(x - radius, ground - radius * 2.0 - depth * 25.0, radius * 2.0, radius * 2.0)):
		rolling_load.pushed = true
		var relative := absf(_wagon.linear_velocity.x - rolling_load.speed)
		_wagon.record_damage_contact(Vector2(x, ground - 22.0))
		var damage := _wagon.hit_weighted_obstacle(lerpf(0.08, 0.31, smoothstep(85.0, 650.0, relative)), true)
		_impact_art.burst(Vector2(x, ground - 16.0), relative / PIXELS_PER_METER, 0.18, "cable_spool")
		rolling_load.speed = minf(410.0, relative * 0.42 + 90.0)
		encounter_hit.emit("rolling_feedback", float(damage.get("damage", 0.0)), 0, 1, x, ground, 0.0)
	if not roll_bonus_paid and not rolling_load.pushed and _wagon.position.x > x + 95.0:
		roll_bonus_paid = true
		bonus_coin_collected.emit(ROLL_BONUS)

func _update_crossing(delta: float) -> void:
	var x := _wagon.position.x / PIXELS_PER_METER
	if x < TILT_START_M - 7.0 or x > SAND_START_M + 4.0:
		return
	var loaded := _wagon.front_spring.get_collider() == tilt_crossing or _wagon.rear_spring.get_collider() == tilt_crossing
	tilt_crossing.advance(delta, loaded)
	if x >= TILT_START_M and x < TILT_EXIT_M:
		for spring in [_wagon.front_spring, _wagon.rear_spring]:
			if spring.is_colliding() and spring.get_collider() != tilt_crossing and spring.get_collision_point().y > 556.0:
				tilt_in_pit = true
	if x >= TILT_EXIT_M and tilt_crossing.elapsed >= 0.0 and not tilt_in_pit and not tilt_bonus_paid:
		if _wagon.front_spring.is_colliding() or _wagon.rear_spring.is_colliding():
			tilt_bonus_paid = true
			bonus_coin_collected.emit(25)

func _on_crossing_creak() -> void:
	var foot := Vector2(TILT_FLOOR_M * PIXELS_PER_METER - 56.0, 520.0 + TILT_DEPTH - 3.0)
	_impact_art.puff(foot, 0.4, 4)

func _on_crossing_break() -> void:
	var foot := Vector2(TILT_FLOOR_M * PIXELS_PER_METER - 56.0, 565.0)
	_impact_art.burst(foot, 10.0, 0.2, "work_fence")

func _update_branch() -> void:
	var meter := _wagon.position.x / PIXELS_PER_METER
	if not _route_committed and meter >= BRANCH_DECISION_M:
		_route_committed = true
		upper_route = _wagon.boost_active and _wagon.linear_velocity.x / PIXELS_PER_METER * 3.6 >= MIN_BRIDGE_SPEED_KMH
		if upper_route:
			_lower_body.collision_layer = 0
			_upper_body.collision_layer = 1
		route_decided.emit("BEHELFSBRÜCKE" if upper_route else "STAHLPLATTEN", upper_route)
	if upper_route and not bonus_taken:
		var x := BONUS_M * PIXELS_PER_METER
		var y := _upper_height(BONUS_M)
		if _wagon.chassis_overlaps_world_rect(Rect2(x - 26.0, y - 65.0, 52.0, 65.0)):
			bonus_taken = true
			bonus_coin_collected.emit(30)

func _update_girder_landing() -> void:
	if girder_landed:
		return
	if _wagon.position.x < (SAND_LIP_M + 3.0) * PIXELS_PER_METER:
		_girder_body.collision_layer = 1
		return
	var front := _wagon.front_spring
	var rear := _wagon.rear_spring
	var upper_surfaces := [_girder_body, _scaffold_body, _girder_exit_body]
	var front_on_deck := front.get_collider() in upper_surfaces
	var rear_on_deck := rear.get_collider() in upper_surfaces
	if front_on_deck and rear_on_deck:
		girder_landed = true
		_impact_art.puff(Vector2(_wagon.position.x, _girder_height(_wagon.position.x / PIXELS_PER_METER) - 2.0), 0.65, 5)
		spawn_impact_particles(_wagon.position.x, _girder_height(_wagon.position.x / PIXELS_PER_METER) + 15.0, 0.29, true)
		_clean_girder_landing = absf(_wagon.rotation) < 0.30 and absf(_wagon.linear_velocity.y) < 9.0 * PIXELS_PER_METER
		for event in _encounters:
			if event.get("girder", false):
				event.areas[0].set_deferred("monitoring", true)
	# Once both wheels are below the catch height, keep the underside passable.
	elif not front_on_deck and not rear_on_deck and _wagon.position.y > GIRDER_DECK_Y - 31.0:
		_girder_body.collision_layer = 0
		_scaffold_body.collision_layer = 0
		_girder_exit_body.collision_layer = 0

func _update_scaffold(delta: float) -> void:
	if scaffold_fall >= 0.0:
		scaffold_fall = minf(scaffold_fall + delta, 1.0)
		if _wagon.position.y > GIRDER_DECK_Y - 8.0:
			_girder_exit_body.collision_layer = 0
		return
	if scaffold_crossed or not girder_landed:
		return
	var front := _wagon.front_spring.get_collider()
	var rear := _wagon.rear_spring.get_collider()
	if scaffold_load < 0.0:
		if front != _scaffold_body and rear != _scaffold_body:
			return
		scaffold_load = 0.0
		worksite_event.emit("GERÜSTBOHLEN KNARREN", 0.0)
	scaffold_load += delta
	scaffold_sag = 4.5 * smoothstep(0.0, SCAFFOLD_LOAD_TIME, scaffold_load)
	_scaffold_body.position.y = scaffold_sag
	if rear == _girder_exit_body:
		scaffold_crossed = true
		bonus_coin_collected.emit(SCAFFOLD_BONUS)
	elif scaffold_load >= SCAFFOLD_LOAD_TIME:
		scaffold_fall = 0.0
		_clean_girder_landing = false
		_scaffold_body.collision_layer = 0
		for event in _encounters:
			if event.get("girder", false):
				event.areas[0].set_deferred("monitoring", false)
		_impact_art.burst(Vector2(_wagon.position.x, GIRDER_DECK_Y + 20.0), 12.0, 0.75, "pallet_stack")
		worksite_event.emit("GERÜST BRICHT · UNTEN WEITER", 0.14)

func _on_gravel_touchdown(_impact_speed: float) -> void:
	var meter := _wagon.position.x / PIXELS_PER_METER
	if (not girder_landed or scaffold_fall >= 0.0) and meter > SAND_LIP_M and meter < GIRDER_END_M and _wagon.position.y > GIRDER_DECK_Y + 20.0:
		spawn_impact_particles(_wagon.position.x, _lower_height(meter) + 15.0, 0.47, true)
		_impact_art.puff(Vector2(_wagon.position.x, _lower_height(meter) - 2.0), 0.85, 8)

func _update_wheel_dust(delta: float) -> void:
	_wheel_dust_left = maxf(0.0, _wheel_dust_left - delta)
	var meter := _wagon.position.x / PIXELS_PER_METER
	var on_sand := meter >= SAND_START_M and meter <= SAND_LIP_M
	var on_gravel := meter >= SAND_LIP_M and meter < GIRDER_END_M and (not girder_landed or scaffold_fall >= 0.0)
	if not (on_sand or on_gravel) or _wheel_dust_left > 0.0 or absf(_wagon.speed_mps) < 3.0:
		return
	if _wagon.rear_spring.is_colliding():
		var point := _wagon.rear_spring.get_collision_point()
		_impact_art.puff(point - Vector2(12, 3), 0.35, 2)
		_wheel_dust_left = 0.12

func _on_worksite_hit(kind: String, _resistance: float, _variant: int, _members: int, x: float, ground: float, speed: float) -> void:
	if kind == "work_fence" and absf(x / PIXELS_PER_METER - FORMWORK_M) < 0.3 and formwork_fall < 0.0:
		formwork_fall = 0.0
		_impact_art.burst(Vector2(x - 95.0, ground - 70.0), speed, 0.9, "pallet_stack")
		worksite_event.emit("SCHALUNG STÜRZT EIN", 0.14)
	if kind == "pallet_stack" and scaffold_crossed and _clean_girder_landing and not girder_bonus and x / PIXELS_PER_METER > GIRDER_DESCENT_M:
		girder_bonus = true
		bonus_coin_collected.emit(12)
	if kind in ["pallet_stack", "work_fence", "scrap_wall", "oil_drums", "road_sign", "cable_spool"]:
		_impact_art.burst(Vector2(x, ground - 20.0), speed, _resistance, kind)
	match kind:
		"load_chock":
			rolling_load = {"x": x + LOAD_OFFSET, "angle": 0.0, "speed": 360.0, "age": 0.0, "pushed": false}
			_impact_art.burst(Vector2(x, ground - 16.0), speed, 0.2, "work_fence")
		"oil_drums":
			_explode_barrels(x, ground)
		"cable_spool":
			if absf(x / PIXELS_PER_METER - DOCK_DRUM_M) < 0.35:
				_dock_spool = {"x": x, "speed": clampf(speed * PIXELS_PER_METER * 1.32, 260.0, 1050.0), "angle": 0.0}
		"drain_pipes":
			_impact_art.burst(Vector2(x, ground - 9.0), speed, 0.38, "drain_pipes")
			for index in range(3):
				_rolling_pipes.append({
					"x": x + float(index - 1) * 25.0,
					"speed": clampf(speed * (6.0 + float(index) * 3.0), 65.0, 310.0),
					"angle": 0.0,
				})

func _update_dock_spool(delta: float) -> void:
	if _dock_spool.is_empty() or _dock_spool.speed <= 0.0:
		return
	var previous: float = _dock_spool.x
	var fence_x := DOCK_FENCE_M * PIXELS_PER_METER
	var travel: float = _dock_spool.speed * delta
	_dock_spool.x += travel
	_dock_spool.angle += travel / 25.0
	_dock_spool.speed = move_toward(_dock_spool.speed, 0.0, 125.0 * delta)
	if previous < fence_x - 33.0 and _dock_spool.x >= fence_x - 33.0:
		for index in range(_encounters.size()):
			var event: Dictionary = _encounters[index]
			if not event.done and is_equal_approx(float(event.meter), DOCK_FENCE_M):
				_clear_encounter(index)
				_impact_art.burst(Vector2(fence_x, _lower_height(DOCK_FENCE_M) - 18.0), _dock_spool.speed / PIXELS_PER_METER, 0.6, "work_fence")
				_dock_spool.speed *= 0.42
				worksite_event.emit("KABELTROMMEL DURCHBRICHT KAI-SPERRE", 0.08)
				break

func _update_blast_queue(delta: float) -> void:
	for index in range(_blast_queue.size() - 1, -1, -1):
		var pending: Dictionary = _blast_queue[index]
		pending.time -= delta
		if pending.time > 0.0:
			continue
		_blast_queue.remove_at(index)
		var event: Dictionary = _encounters[pending.encounter]
		if not event.done:
			_clear_encounter(pending.encounter)
			var x := float(event.meter) * PIXELS_PER_METER
			_explode_barrels(x, _encounter_ground_at(x, event))

func _explode_barrels(x: float, ground: float) -> void:
	var center := Vector2(x, ground - 32.0)
	_barrel_bursts.append({"center": center, "age": 0.0})
	spawn_impact_particles(x, ground - 12.0, 0.9)
	var zone := ""
	for event in _encounters:
		if event.get("prop", "") == "oil_drums" and absf(float(event.meter) * PIXELS_PER_METER - x) < 2.0:
			zone = String(event.get("blast_zone", ""))
			break
	if zone.is_empty():
		return
	worksite_event.emit("FASS-KETTENREAKTION", 0.12)
	for index in range(_encounters.size()):
		var event: Dictionary = _encounters[index]
		if event.done or event.get("blast_zone", "") != zone:
			continue
		var hit: Array = []
		for member: Dictionary in event.members_data:
			var area := member.area as Area2D
			if member.hit or area.position.distance_to(center) > 235.0:
				continue
			if event.get("prop", "") == "oil_drums":
				if not _blast_queue.any(func(pending: Dictionary) -> bool: return pending.encounter == index):
					_blast_queue.append({"time": 0.18 + absf(area.position.x - x) / 1600.0, "encounter": index})
				continue
			member.hit = true
			hit.append(member.duplicate())
			area.set_deferred("monitoring", false)
		if hit.is_empty():
			continue
		event.done = event.members_data.all(func(member: Dictionary) -> bool: return member.hit)
		var at: Vector2 = hit[0].area.position
		if event.kind in ["zombie_group", "runner_group"]:
			_reactions.append({"variant": event.variant, "members": hit, "time_left": 1.15, "duration": 1.15,
				"ground_y": _encounter_ground_at(at.x, event), "speed_mps": 12.0, "seed": index})
		else:
			_impact_art.burst(at, 22.0, 0.5, String(event.get("prop", "work_fence")))

func _update_pipes(delta: float) -> void:
	for pipe in _rolling_pipes:
		var travel := float(pipe.speed) * delta
		pipe.x += travel
		pipe.angle += travel / 13.0
		pipe.speed = move_toward(float(pipe.speed), 0.0, 105.0 * delta)

func _apply_climb_resistance() -> void:
	if not _wagon.front_spring.is_colliding() and not _wagon.rear_spring.is_colliding():
		return
	var uphill := -slope_at(_wagon.position.x)
	var load_factor := smoothstep(0.09, 0.34, uphill)
	if load_factor <= 0.0:
		return
	var tangent := Vector2.RIGHT.rotated(-uphill)
	var uphill_speed := maxf(0.0, _wagon.linear_velocity.dot(tangent))
	# Rolling load rises with grade and speed. The suspension and gravity still
	# determine takeoff and landing after the tires leave the road.
	var resistance := _wagon.mass * uphill_speed * load_factor * 0.66
	_wagon.apply_central_force(-tangent * resistance)

func _part_bounds() -> Rect2:
	var x := PART_M * PIXELS_PER_METER
	var size: Vector2 = _art.prop_size("motor_crate")
	return Rect2(Vector2(x - size.x * 0.5, height_at(x) - size.y), size)

func _view_span() -> Vector2:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return Vector2(-2000.0, 2000.0)
	var reach := get_viewport_rect().size.x / maxf(camera.zoom.x, 0.1) * 0.5 + 220.0
	var center := camera.get_screen_center_position().x
	return Vector2(center - reach, center + reach)

func _draw() -> void:
	_art.begin_track_draw()
	super._draw()
	_pump_art_layer.queue_redraw()
	_art.draw_quay_foreground(self, _view_span(), get_viewport().get_camera_2d())

func _draw_environment() -> void:
	var view := _view_span()
	_art.draw_skyline(self, view, get_viewport().get_camera_2d())
	_art.draw_yard(self, 359.0 * PIXELS_PER_METER, _lower_height(359.0), view)
	_art.draw_yard(self, 667.0 * PIXELS_PER_METER, _lower_height(667.0), view, true)
	_art.draw_depot(self, 856.0 * PIXELS_PER_METER, _lower_height(856.0), view)
	_art.draw_scrapyard(self, 1286.0 * PIXELS_PER_METER, _lower_height(1286.0), view)
	_art.draw_jump_yard(self, view, SAND_START_M + 15.0)
	_art.draw_challenge_backdrop(self, view)
	_art.draw_street_details(self, view)

func _draw_track() -> void:
	var view := _view_span()
	_art.draw_quay(self, view)
	_art.draw_action_signals(self, view)
	_art.draw_bridge(self, view)
	_draw_crossing(view)
	_art.draw_girder_site(self, view)
	_art.draw_excavation_details(self, view)
	_art.draw_new_challenges(self, view)

	if is_instance_valid(_wagon):
		var ground := height_at(_wagon.position.x)
		_impact_art.shadow(self, Vector2(_wagon.position.x, ground + 3.0), ground - _wagon.position.y)
	if not _dock_spool.is_empty():
		var x: float = _dock_spool.x
		if x >= view.x and x <= view.y:
			_art.draw_spool(self, Vector2(x, _lower_height(x / PIXELS_PER_METER) - 24.0), _dock_spool.angle, 24.0)
	for pipe in _rolling_pipes:
		var x := float(pipe.x)
		if x >= view.x and x <= view.y:
			_art.draw_rolling_pipe(self, Vector2(x, _lower_height(x / PIXELS_PER_METER) - 13.0), float(pipe.angle))

func _draw_reactions() -> void:
	super._draw_reactions()
	_impact_art.render(self, _view_span())
	for burst in _barrel_bursts:
		_art.draw_barrel_burst(self, burst.center, burst.age)

func _draw_encounter_object(world_x: float, ground: float, event: Dictionary) -> void:
	var prop := String(event.get("prop", ""))
	if prop == "supply_crate":
		if not event.done:
			_art.draw_supplies(self, Vector2(world_x, _encounter_ground_at(world_x, event)))
		return
	if not _art.has_prop(prop):
		super._draw_encounter_object(world_x, ground, event)
		return
	var real_ground := _encounter_ground_at(world_x, event)
	if event.done:
		if prop in ["oil_drums", "work_fence"]:
			_art.draw_breach_wreck(self, prop, Vector2(world_x, real_ground))
		else:
			_draw_broken_debris(world_x, real_ground, String(event.kind))
	else:
		_art.draw_prop(self, prop, Vector2(world_x, real_ground))

func _draw_roadside_markers() -> void:
	var finish_x := (START_M + LENGTH_M) * PIXELS_PER_METER
	var view := _view_span()
	if finish_x >= view.x and finish_x <= view.y:
		_art.draw_finish(self, finish_x, height_at(finish_x))
	_draw_bridge_signals(view)
	if part_found:
		return
	var bounds := _part_bounds()
	_art.draw_prop(self, "motor_crate", Vector2(bounds.get_center().x, bounds.end.y))
	draw_string(ThemeDB.fallback_font, bounds.position + Vector2(-22, -12), "MOTORTEIL", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color8(255, 221, 152))

func _draw_bridge_signals(view: Vector2) -> void:
	var sign_x := 394.0 * PIXELS_PER_METER
	if sign_x >= view.x and sign_x <= view.y:
		var y := _lower_height(394.0)
		draw_line(Vector2(sign_x, y), Vector2(sign_x, y - 84.0), Color8(50, 59, 58), 5.0)
		draw_rect(Rect2(sign_x - 61.0, y - 105.0, 122.0, 32.0), Color8(37, 51, 47))
		draw_string(ThemeDB.fallback_font, Vector2(sign_x - 53.0, y - 84.0), "BRÜCKE +30", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color8(255, 217, 133))
	var x := BONUS_M * PIXELS_PER_METER
	if not bonus_taken and x >= view.x and x <= view.y:
		var y := _upper_height(BONUS_M)
		for offset in [-26.0, 0.0, 26.0]:
			draw_circle(Vector2(x + offset, y - 42.0), 8.0, Color8(126, 85, 30))
			draw_circle(Vector2(x + offset, y - 43.0), 6.0, Color8(251, 201, 96))














func _draw_crossing(view: Vector2) -> void:
	var pivot := tilt_crossing.position
	if pivot.x + Crossing.LENGTH + 90.0 < view.x or pivot.x - 60.0 > view.y:
		return
	_art.draw_tilting_crossing(self, tilt_crossing, view)










func _draw_pump_route() -> void:
	_art.draw_pumpworks_route(self, _view_span(), _pump_art_layer)
