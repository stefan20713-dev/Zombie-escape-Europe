extends "res://scripts/driving_test_course.gd"
class_name AmsterdamPreviewCourse

signal lock_water_entered
signal lock_approach

const LOCK_RAMP_TEXTURE: Texture2D = preload("res://assets/amsterdam_lock_drawbridge.png")
const LOCK_LANDING_TEXTURE: Texture2D = preload("res://assets/amsterdam_lock_landing.png")
const LOCK_GATE_TEXTURE: Texture2D = preload("res://assets/amsterdam_lock_gate.png")
const LOCK_START_M: float = START_M + 1235.0
const LOCK_LIP_M: float = START_M + 1280.0
# Horizontal takeoff, landing 100 px lower: t = sqrt(200 / (350 * 0.88)).
# At 110 km/h, front axle clearance gives (110/3.6)*t + 70/36 = 26.5668 m.
const LOCK_GAP_M: float = 26.56
const LOCK_LANDING_M: float = LOCK_LIP_M + LOCK_GAP_M
const LOCK_DECK_END_M: float = LOCK_LANDING_M + 14.0
const LOCK_REJOIN_M: float = LOCK_DECK_END_M + 16.0
const LOCK_RISE_PX: float = 60.0
const LOCK_LANDING_DROP_PX: float = 100.0
const LOCK_MIN_SPEED_KMH: float = 110.0
const LOCK_ENGINE_LEVEL: int = 2
const LOCK_NITRO_LEVEL: int = 1
var lock_flight_active: bool = false
var _lock_flight_time: float = 0.0
var _lock_flight_speed: float = 0.0
var _lock_release_clearance: float = 0.0
var _lock_edge_checked: bool = false
var _lock_missed: bool = false
var _lock_launched: bool = false
var _lock_water_entered: bool = false
var _lock_warned: bool = false
var _lock_splash_time: float = 0.0
var _lock_splash_x: float = 0.0

signal route_decided(route_name: String, upper_route: bool)
signal bonus_coin_collected(amount: int)

const PREVIEW_TITLE: String = "AMSTERDAM · GRACHTENSTRECKE"
const VISUALS = preload("res://scripts/visual_materials.gd")
const AMSTERDAM_COBBLE_TILE: Texture2D = VISUALS.COBBLES
const AMSTERDAM_BRICK_TILE: Texture2D = preload("res://assets/amsterdam_masonry_illustrated.png")
const BARGE_TEXTURE: Texture2D = preload("res://assets/amsterdam_barge_hull_unrigged.png")
const BARGE_RAMP_TEXTURE: Texture2D = preload("res://assets/amsterdam_barge_ramp_seated.png")
const BARGE_BOLLARD_TEXTURE: Texture2D = preload("res://assets/amsterdam_barge_bollard.png")
const AMSTERDAM_OBSTACLE_ATLAS: Texture2D = preload("res://assets/amsterdam_obstacle_atlas_0.5.56.png")
const AMSTERDAM_OBSTACLE_ATLAS_058: Texture2D = preload("res://assets/amsterdam_obstacle_atlas_0.5.58.png")
const BARRICADE_ATLAS_REGION: Rect2 = Rect2(0.0, 0.0, 768.0, 512.0)
const CRATE_ATLAS_REGION: Rect2 = Rect2(768.0, 0.0, 768.0, 512.0)
const BARREL_ATLAS_REGION: Rect2 = Rect2(0.0, 512.0, 768.0, 512.0)
const BRICK_BARRIER_ATLAS_REGION: Rect2 = Rect2(768.0, 512.0, 768.0, 512.0)
const FALLEN_BIKE_ATLAS_REGION: Rect2 = Rect2(0.0, 0.0, 768.0, 512.0)
const FALLEN_LAMP_ATLAS_REGION: Rect2 = Rect2(768.0, 0.0, 768.0, 512.0)
const MARKET_CART_ATLAS_REGION: Rect2 = Rect2(0.0, 512.0, 768.0, 512.0)
const QUAY_RUBBLE_ATLAS_REGION: Rect2 = Rect2(768.0, 512.0, 768.0, 512.0)
const OBSTACLE_CONTACT_ROWS: Dictionary = {
	"timber_barrier": 476.0, "wood_crates": 476.0, "barrel_stack": 447.0,
	"brick_barrier": 447.0, "fallen_bike": 438.0, "fallen_lamp": 419.0,
	"market_cart": 439.0, "quay_rubble": 423.0,
}
const AMSTERDAM_LENGTH_M: float = 1800.0
# Allow room beyond the finish for the spawn offset, both axles and the camera.
const ROAD_END_M: float = AMSTERDAM_LENGTH_M + 100.0
const RAMP_START_M: float = 392.0
const RAMP_LIP_M: float = 432.0
const RAMP_REJOIN_M: float = 540.0
const UPPER_BRIDGE_START_M: float = 465.0
const UPPER_BRIDGE_END_M: float = 500.0
const UPPER_BRIDGE_Y: float = BASELINE_Y - 220.0
const BRANCH_MIN_SPEED_KMH: float = 120.0
const BRANCH_MIN_SPEED_MPS: float = BRANCH_MIN_SPEED_KMH / 3.6
const OPENING_RAMP_START_M: float = 100.0
const OPENING_RAMP_LIP_M: float = 107.0
const HARBOR_START_M: float = 1175.0
const HARBOR_RAMP_START_M: float = 1737.0
const HARBOR_RAMP_LIP_M: float = 1750.0
const BARGE_START_M: float = START_M + 820.0
const BARGE_DECK_START_M: float = BARGE_START_M + 12.0
const BARGE_DECK_END_M: float = BARGE_DECK_START_M + 30.0
const BARGE_END_M: float = BARGE_DECK_END_M + 12.0
const AMSTERDAM_LAYOUT: Array[Dictionary] = [
	{"kind": "light_obstacle", "meter": 315.8, "variant": 0, "members": 1, "resistance": 0.26, "prop": "wood_crates"},
	{"kind": "light_obstacle", "meter": 954.0, "variant": 0, "members": 1, "resistance": 0.26, "prop": "wood_crates"},
	{"kind": "zombie_group", "meter": 315.0, "variant": 1, "members": 3, "resistance": 0.0},
	{"kind": "runner_group", "meter": 339.0, "variant": 2, "members": 2, "resistance": 0.0},
	{"kind": "zombie_group", "meter": 611.0, "variant": 3, "members": 2, "resistance": 0.0},
	{"kind": "zombie_group", "meter": 710.0, "variant": 1, "members": 3, "resistance": 0.0},
	{"kind": "runner_group", "meter": 959.0, "variant": 2, "members": 2, "resistance": 0.0},
	{"kind": "zombie_group", "meter": 1061.0, "variant": 1, "members": 3, "resistance": 0.0},
	{"kind": "zombie_group", "meter": 44.0, "variant": 3, "members": 1, "resistance": 0.0},
	{"kind": "runner_group", "meter": 72.0, "variant": 2, "members": 1, "resistance": 0.0},
	{"kind": "light_obstacle", "meter": 96.0, "variant": 0, "members": 1, "resistance": 0.36, "prop": "timber_barrier"},
	{"kind": "runner_group", "meter": 154.0, "variant": 2, "members": 2, "resistance": 0.0},
	{"kind": "zombie_group", "meter": 184.0, "variant": 1, "members": 2, "resistance": 0.0},
	{"kind": "zombie_group", "meter": 224.0, "variant": 3, "members": 1, "resistance": 0.0},
	{"kind": "runner_group", "meter": 457.0, "variant": 2, "members": 1, "resistance": 0.0, "lower_lane": true},
	{"kind": "runner_group", "meter": 475.0, "variant": 2, "members": 1, "resistance": 0.0, "lower_lane": true},
	{"kind": "light_obstacle", "meter": 632.0, "variant": 0, "members": 1, "resistance": 0.51, "prop": "brick_barrier"},
	{"kind": "zombie_group", "meter": 650.0, "variant": 1, "members": 4, "resistance": 0.0},
	{"kind": "runner_group", "meter": 674.0, "variant": 2, "members": 3, "resistance": 0.0},
	{"kind": "light_obstacle", "meter": 730.0, "variant": 0, "members": 1, "resistance": 0.44, "prop": "timber_barrier"},
	{"kind": "zombie_group", "meter": 766.0, "variant": 1, "members": 4, "resistance": 0.0},
	{"kind": "zombie_group", "meter": 859.0, "variant": 1, "members": 2, "resistance": 0.0},
	{"kind": "runner_group", "meter": 912.0, "variant": 2, "members": 2, "resistance": 0.0},
	{"kind": "zombie_group", "meter": 924.0, "variant": 3, "members": 2, "resistance": 0.0},
	{"kind": "zombie_group", "meter": 1015.0, "variant": 1, "members": 2, "resistance": 0.0},
	{"kind": "light_obstacle", "meter": 1149.0, "variant": 0, "members": 1, "resistance": 0.26, "prop": "timber_barrier"},
	{"kind": "zombie_group", "meter": 1135.0, "variant": 1, "members": 3, "resistance": 0.0},
	{"kind": "runner_group", "meter": 1215.0, "variant": 2, "members": 2, "resistance": 0.0},
	{"kind": "light_obstacle", "meter": 1185.0, "variant": 0, "members": 1, "resistance": 0.32, "prop": "harbor_timber_barrier"},
	{"kind": "zombie_group", "meter": 1375.0, "variant": 1, "members": 3, "resistance": 0.0},
	{"kind": "runner_group", "meter": 1425.0, "variant": 2, "members": 1, "resistance": 0.0},
	{"kind": "runner_group", "meter": 1500.0, "variant": 2, "members": 2, "resistance": 0.0},
	{"kind": "zombie_group", "meter": 1560.0, "variant": 1, "members": 2, "resistance": 0.0},
	{"kind": "zombie_group", "meter": 1595.0, "variant": 3, "members": 1, "resistance": 0.0},
	{"kind": "runner_group", "meter": 1645.0, "variant": 2, "members": 2, "resistance": 0.0},
	{"kind": "light_obstacle", "meter": 1685.0, "variant": 0, "members": 1, "resistance": 0.23, "prop": "harbor_timber_barrier"},
	{"kind": "zombie_group", "meter": 1715.0, "variant": 1, "members": 2, "resistance": 0.0}
]

var _branch_decided: bool = false
var _upper_edge_checked := false
var _upper_missed_edge := false
var _upper_previous_wheel := Vector2.ZERO
var _upper_previous_wheel_valid := false
var _upper_route_chosen: bool = false
var _upper_launch_triggered: bool = false
var _harbor_ramp_triggered: bool = false
var _upper_ramp_collision: CollisionShape2D
var _upper_bridge_body: StaticBody2D
var _upper_coins_collected: Dictionary = {}
var _upper_coin_meters: Array[float] = [487.0, 492.0, 497.0]
var explosives: Node2D
var collapse_site := preload("res://scripts/route_collapse.gd").new()
var action: Node2D

var _weapon_cooldown_s: float = 0.0
var _wreck_horde:Array[Dictionary]=[]
var _wreck_horde_time:float=0.0
var _finish_safe:bool=false
var _finish_followers:Array[Dictionary]=[]

func begin_finish_safety() -> void:
	_finish_safe=true
	_finish_followers.clear()
	for i in range(6):_finish_followers.append({"x":(START_M+AMSTERDAM_LENGTH_M)*PIXELS_PER_METER-330-i*60,"target":(START_M+AMSTERDAM_LENGTH_M)*PIXELS_PER_METER-210-i*34,"phase":i*.9,"variant":1 if i%3 else 2})
	for event in _encounters:
		for member in event.members_data:
			if is_instance_valid(member.area):member.area.set_deferred("monitoring",false)

func _on_encounter_body_entered(body:Node2D,event_index:int,member_index:int) -> void:
	if _finish_safe:return
	super._on_encounter_body_entered(body,event_index,member_index)

func start_wreck_horde() -> void:
	_wreck_horde.clear()
	_wreck_horde_time=0.0
	_finish_safe=false
	if not is_instance_valid(_wagon):return
	for i in range(6):
		var side:float=-1.0 if i<3 else 1.0
		var rank:int=i if i<3 else i-3
		_wreck_horde.append({"x":_wagon.position.x+side*(250+rank*160),"target":_wagon.position.x+side*(125+rank*160),"speed":170.0,"delay":float(rank)*.18,"phase":float(i)*1.37,"variant":[1,2,1,3,2,4,1,5][i%8],"facing":side,"side":side,"rank":rank,"attack_time":0.0})
	queue_redraw()

func update_wreck_horde(delta:float) -> void:
	_wreck_horde_time+=delta
	for enemy in _wreck_horde:
		if _wreck_horde_time<float(enemy.delay):continue
		var distance:float=absf(float(enemy.target)-float(enemy.x))
		enemy.x=move_toward(float(enemy.x),float(enemy.target),float(enemy.speed)*delta)
		enemy.phase+=delta*(8.0 if distance>2.0 else 1.2)
		if distance<3 and int(enemy.rank)==0:enemy.attack_time+=delta
	queue_redraw()

func _draw_wreck_horde() -> void:
	for enemy in _wreck_horde:
		if _wreck_horde_time<float(enemy.delay):continue
		var x:float=float(enemy.x)
		if float(enemy.attack_time)>0:
			_draw_wreck_attacker(enemy)
		else:_draw_zombie(x,height_at(x),int(enemy.variant),"fast",1.0,float(enemy.phase),float(enemy.facing))

func _draw_wreck_attacker(enemy:Dictionary) -> void:
	var art=preload("res://scripts/zombie_attachment_art.gd")
	var variant:int=int(enemy.variant)
	var side:float=float(enemy.side)
	var phase:float=float(enemy.attack_time)*5.0+float(enemy.phase)
	var rect:Rect2=art.pose_rect(variant,1)
	var grip_x:float=_wagon.position.x+side*(96+sin(phase)*3)
	var floor:float=height_at(float(enemy.x))
	# This atlas faces right; the walking atlases face left. Keep those two
	# conventions explicit so a zombie never backs toward the car.
	draw_set_transform(Vector2(grip_x,floor-rect.end.y),sin(phase)*.025,Vector2(-side,1))
	draw_texture_rect_region(art.ATLAS,rect,art.RECTS[art.pose_index(variant,1)])
	draw_set_transform(Vector2.ZERO)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	super._ready()
	action = preload("res://scripts/amsterdam_action.gd").new()
	action.name = "AmsterdamAction"
	add_child(action)
	explosives = preload("res://scripts/amsterdam_explosives.gd").new()
	explosives.name = "ExplosiveDrums"
	add_child(explosives)
	collapse_site.setup(self, {
		"meter": 1103.0, "title": "GRACHTENSPEICHER", "lead": 1010.0, "fuse": 0.92, "stagger": 0.40, "slide": 1.35,
		"building": "res://levels/amsterdam/art/collapse_warehouse.png",
		"source": Rect2(211, 3, 725, 1357), "rows": [0.0, 0.36, 0.55, 0.74, 1.0], "height": 352.0,
	})
	collapse_site.name = "CollapseSite"
	add_child(collapse_site)
	for section in range(5):
		for back_layer in [true, false]:
			if section == 3 and back_layer:
				continue
			var art = preload("res://scripts/amsterdam_static_bridge_art.gd").new()
			art.supports_only = back_layer
			art.section = section
			art.z_index = -1 if back_layer else 0
			art.name = ("StaticSupports" if back_layer else "StaticArt") + str(section)
			add_child(art)

func preview_length_m() -> float:
	return AMSTERDAM_LENGTH_M

func preview_city_name() -> String:
	return "Amsterdam"

func preview_title_text() -> String:
	return PREVIEW_TITLE

func zombie_approach_distance_m() -> float:
	# Keep the first runners waiting in the visible lane, then let them charge
	# when the wagon enters the camera's forward action area.
	return 22.0

func reset_test_run(wagon: EscapeWagon) -> void:
	collapse_site.reset()
	_finish_safe=false
	_finish_followers.clear()
	if is_instance_valid(explosives):
		explosives.reset()
	if is_instance_valid(action):
		action.reset()
	lock_flight_active = false
	_lock_flight_time = 0.0
	_lock_edge_checked = false
	_lock_missed = false
	_lock_launched = false
	_lock_water_entered = false
	_lock_warned = false
	_lock_splash_time = 0.0
	_branch_decided = false
	_upper_edge_checked = false
	_upper_missed_edge = false
	_upper_previous_wheel_valid = false
	if is_instance_valid(_upper_bridge_body):
		wagon.front_spring.remove_exception(_upper_bridge_body)
		wagon.rear_spring.remove_exception(_upper_bridge_body)
		wagon.remove_collision_exception_with(_upper_bridge_body)
	_upper_route_chosen = false
	_upper_launch_triggered = false
	_harbor_ramp_triggered = false
	if is_instance_valid(_upper_ramp_collision):
		_upper_ramp_collision.set_deferred("disabled", true)
	_upper_coins_collected.clear()
	_weapon_cooldown_s = 0.0
	_wreck_horde.clear()
	_wreck_horde_time=0.0
	super.reset_test_run(wagon)
	queue_redraw()

func _base_height_at(world_x: float) -> float:
	var meter: float = world_x / PIXELS_PER_METER
	if meter >= LOCK_START_M and meter <= LOCK_REJOIN_M:
		return lock_surface_y(meter)
	if meter >= BARGE_START_M and meter <= BARGE_END_M:
		var deck_y: float = barge_deck_y()
		if meter < BARGE_DECK_START_M:
			return lerpf(_quay_height_at(BARGE_START_M * PIXELS_PER_METER), deck_y, inverse_lerp(BARGE_START_M, BARGE_DECK_START_M, meter))
		if meter > BARGE_DECK_END_M:
			return lerpf(deck_y, _quay_height_at(BARGE_END_M * PIXELS_PER_METER), inverse_lerp(BARGE_DECK_END_M, BARGE_END_M, meter))
		return deck_y
	return _quay_height_at(world_x)

func lock_base_y() -> float:
	return _quay_height_at(LOCK_START_M * PIXELS_PER_METER)

func lock_surface_y(meter: float) -> float:
	var base: float = lock_base_y()
	if meter <= LOCK_LIP_M:
		return base - LOCK_RISE_PX * smoothstep(LOCK_START_M, LOCK_LIP_M, meter)
	var landing_y: float = base - LOCK_RISE_PX + LOCK_LANDING_DROP_PX
	if meter <= LOCK_DECK_END_M:
		return landing_y
	return lerpf(landing_y, _quay_height_at(LOCK_REJOIN_M * PIXELS_PER_METER), smoothstep(LOCK_DECK_END_M, LOCK_REJOIN_M, meter))

func lock_water_y() -> float:
	return lock_base_y() + 400.0

func quay_visible_gap_world_bounds(camera_x: float) -> Vector2:
	if camera_x > (LOCK_START_M - 100.0) * PIXELS_PER_METER:
		return Vector2(LOCK_LIP_M, LOCK_LANDING_M) * PIXELS_PER_METER
	return quay_gap_world_bounds()

func lock_foundation_offset(world_x: float) -> float:
	var meter: float = world_x / PIXELS_PER_METER
	if meter >= LOCK_LIP_M - 14.0 and meter <= LOCK_LIP_M:
		return 82.0
	if meter >= LOCK_LANDING_M and meter <= LOCK_DECK_END_M:
		return 105.0
	return -1.0

func lock_foundation_breaks() -> Array[float]:
	return [(LOCK_LIP_M - 14.0) * PIXELS_PER_METER, LOCK_DECK_END_M * PIXELS_PER_METER]

func _lock_art_span(x_a: float, x_b: float) -> bool:
	return x_b > (LOCK_LIP_M - 14.0) * PIXELS_PER_METER and x_a < LOCK_DECK_END_M * PIXELS_PER_METER

func barge_deck_y() -> float:
	return (_quay_height_at(BARGE_START_M * PIXELS_PER_METER) + _quay_height_at(BARGE_END_M * PIXELS_PER_METER)) * 0.5 + 90.0

func quay_gap_world_bounds() -> Vector2:
	return Vector2(BARGE_START_M, BARGE_END_M) * PIXELS_PER_METER

func _quay_height_at(world_x: float) -> float:
	var meter: float = world_x / PIXELS_PER_METER
	var rolling_hills: float = _rolling_hills_offset(meter)
	var hills: float = 0.0
	hills += _hump_offset(meter, 95.0, 119.0, 145.0, 32.0, 5.0)
	hills += _hump_offset(meter, 194.0, 211.0, 239.0, 100.0, 7.0)
	hills += _hump_offset(meter, 262.0, 276.0, 306.0, 180.0, 6.0)
	# Clear, nearly level run-up to the timber launch; no extra crest before it.
	# Short recovery after the two routes rejoin, then a drop into the
	# low point, a shorter climb out, and two unevenly spaced crests.
	hills += 95.0 * (smoothstep(550.0, 565.0, meter) - smoothstep(565.0, 588.0, meter))
	hills -= 32.0 * (smoothstep(565.0, 588.0, meter) - smoothstep(588.0, 602.0, meter))
	hills += _hump_offset(meter, 590.0, 594.5, 598.0, 28.0, 3.0)
	hills += _hump_offset(meter, 601.0, 606.5, 611.0, 37.0, 4.0)
	hills += _hump_offset(meter, 678.0, 692.0, 719.0, 175.0, 5.0)
	hills += _hump_offset(meter, 756.0, 778.0, 803.0, 29.0, 4.0)
	hills += 18.0 * (smoothstep(891.0, 925.0, meter) - smoothstep(925.0, 963.0, meter))
	hills += _hump_offset(meter, 949.0, 964.0, 1004.0, 130.0, 5.0)
	hills += _hump_offset(meter, 1292.0, 1322.0, 1360.0, 28.0, 4.0)
	hills += _hump_offset(meter, 1572.0, 1603.0, 1630.0, 31.0, 5.0)
	hills += _hump_offset(meter, HARBOR_RAMP_START_M, HARBOR_RAMP_LIP_M, 1772.0, 43.0, 8.0)
	var road:float=BASELINE_Y+rolling_hills+hills
	var finish:float=START_M+AMSTERDAM_LENGTH_M
	if meter>=finish-18.0:
		road=lerpf(road,BASELINE_Y+_rolling_hills_offset(finish),smoothstep(finish-18.0,finish-4.0,meter))
	return road

func panorama_anchor_height_at(world_x: float) -> float:
	return _quay_height_at(world_x)

func _encounter_ground_at(world_x: float, event: Dictionary) -> float:
	return _base_height_at(world_x) if bool(event.get("lower_lane", false)) else height_at(world_x)

func height_at(world_x: float) -> float:
	var meter: float = world_x / PIXELS_PER_METER
	var on_approach: bool = meter >= RAMP_START_M and meter < RAMP_LIP_M
	return _upper_route_height_at(world_x) if on_approach or _upper_route_chosen else _base_height_at(world_x)

func _rolling_hills_offset(meter: float) -> float:
	return sin(meter * 0.034) * 9.0 + sin(meter * 0.014 + 0.7) * 7.0 + sin(meter * 0.081) * 3.4

func _upper_route_height_at(world_x: float) -> float:
	var meter: float = world_x / PIXELS_PER_METER
	var lower_height: float = _base_height_at(world_x)
	if meter < RAMP_START_M or meter >= RAMP_REJOIN_M:
		return lower_height
	if meter < RAMP_LIP_M:
		return lerpf(lower_height, UPPER_BRIDGE_Y, smoothstep(RAMP_START_M, RAMP_LIP_M, meter))
	if meter <= UPPER_BRIDGE_END_M:
		return UPPER_BRIDGE_Y
	return lerpf(UPPER_BRIDGE_Y, lower_height, smoothstep(UPPER_BRIDGE_END_M, RAMP_REJOIN_M, meter))

func _build_road_collision() -> void:
	var road := StaticBody2D.new()
	road.name = "AmsterdamRoadCollision"
	road.collision_layer = 1
	road.collision_mask = 0
	var road_shape := ConcavePolygonShape2D.new()
	var road_segments := PackedVector2Array()
	var sample_count: int = int(ROAD_END_M / COLLISION_SAMPLE_M)
	var previous := Vector2.ZERO
	for sample_index in range(sample_count + 1):
		var meter: float = float(sample_index) * COLLISION_SAMPLE_M
		var current := Vector2(meter * PIXELS_PER_METER, _base_height_at(meter * PIXELS_PER_METER))
		if sample_index > 0:
			var a: Vector2 = previous
			var b: Vector2 = current
			var lip_x: float = LOCK_LIP_M * PIXELS_PER_METER
			var landing_x: float = LOCK_LANDING_M * PIXELS_PER_METER
			if a.x < lip_x and b.x > lip_x:
				b = Vector2(lip_x, lock_surface_y(LOCK_LIP_M))
			elif a.x < landing_x and b.x > landing_x:
				a = Vector2(landing_x, lock_surface_y(LOCK_LANDING_M))
			if not (a.x >= lip_x and b.x <= landing_x):
				road_segments.append(a)
				road_segments.append(b)
		previous = current
	road_segments.append(Vector2(LOCK_LANDING_M * PIXELS_PER_METER, lock_surface_y(LOCK_LANDING_M)))
	road_segments.append(Vector2(LOCK_LANDING_M * PIXELS_PER_METER, lock_water_y() + 450.0))
	road_shape.set_segments(road_segments)
	var road_collision := CollisionShape2D.new()
	road_collision.name = "LowerCanalRoad"
	road_collision.shape = road_shape
	road.add_child(road_collision)
	add_child(road)

	var ramp_body := StaticBody2D.new()
	ramp_body.name = "UpperLaunchAndExitRampCollision"
	ramp_body.collision_layer = 1
	ramp_body.collision_mask = 0
	# The approach is always solid. Only the far-side descent and deck are gated.
	var launch_surface := _add_ramp_surface(ramp_body, RAMP_START_M, RAMP_LIP_M)
	launch_surface.name = "AlwaysOpenLaunchRamp"
	_upper_ramp_collision = _add_ramp_surface(ramp_body, UPPER_BRIDGE_END_M, RAMP_REJOIN_M)
	_upper_ramp_collision.name = "UpperRouteOnlySurface"
	_upper_ramp_collision.disabled = true
	add_child(ramp_body)

	# The one-way deck is always present. The lower street stays open underneath.
	var upper_bridge := StaticBody2D.new()
	upper_bridge.name = "UpperCanalBridgeCollision"
	upper_bridge.collision_layer = 1
	upper_bridge.collision_mask = 0
	var deck_shape := RectangleShape2D.new()
	deck_shape.size = Vector2((UPPER_BRIDGE_END_M - UPPER_BRIDGE_START_M) * PIXELS_PER_METER, 5.0)
	var deck_collision := CollisionShape2D.new()
	deck_collision.name = "OneWayBridgeDeck"
	deck_collision.shape = deck_shape
	_upper_bridge_body = upper_bridge
	# The visible top is UPPER_BRIDGE_Y; account for the 5 px collision slab so
	# wheels land on the painted surface rather than slightly below it.
	deck_collision.position = Vector2((UPPER_BRIDGE_START_M + UPPER_BRIDGE_END_M) * 0.5 * PIXELS_PER_METER, UPPER_BRIDGE_Y + 2.5)
	deck_collision.one_way_collision = true
	deck_collision.one_way_collision_margin = 18.0
	upper_bridge.add_child(deck_collision)
	add_child(upper_bridge)

func _add_ramp_surface(body: StaticBody2D, start_m: float, end_m: float) -> CollisionShape2D:
	var shape := ConcavePolygonShape2D.new()
	var segments := PackedVector2Array()
	var samples: int = int(ceil((end_m - start_m) / COLLISION_SAMPLE_M))
	var x: float = start_m * PIXELS_PER_METER
	var previous := Vector2(x, _upper_route_height_at(x))
	for index in range(1, samples + 1):
		x = minf(end_m, start_m + float(index) * COLLISION_SAMPLE_M) * PIXELS_PER_METER
		var point := Vector2(x, _upper_route_height_at(x))
		segments.append(previous)
		segments.append(point)
		previous = point
	shape.set_segments(segments)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	return collision

func _build_encounters() -> void:
	_encounters.clear()
	for layout_index in range(AMSTERDAM_LAYOUT.size()):
		var event: Dictionary = AMSTERDAM_LAYOUT[layout_index].duplicate(true)
		event["agile_chase"] = true
		event["done"] = false
		event["areas"] = []
		event["members_data"] = []
		var kind: String = String(event["kind"])
		var member_count: int = int(event["members"])
		var variant: int = int(event["variant"])
		var group_spacing: float = 108.0 if variant == 2 else 62.0
		for member_index in range(member_count):
			var x: float = float(event["meter"]) * PIXELS_PER_METER
			if kind in ["zombie_group", "runner_group"]:
				x += float(member_index) * group_spacing - float(member_count - 1) * group_spacing * 0.5
			var ground_y: float = height_at(x)
			var area_size: Vector2
			if kind in ["zombie_group", "runner_group"]:
				var visual_height: float = float(ZOMBIE_DATA.profile(variant).get("visual_height", 78.0))
				area_size = Vector2(visual_height * 0.52, visual_height * 0.84)
			elif kind == "supply_cache":
				area_size = Vector2(50.0, 46.0)
			else:
				match String(event.get("prop", "")):
					"tram_wreck": area_size = Vector2(164.0, 75.0)
					"barrel_stack": area_size = Vector2(108.0, 72.0)
					"canal_cart": area_size = Vector2(86.0, 48.0)
					"scaffold": area_size = Vector2(120.0, 61.0)
					"timber_barrier": area_size = Vector2(132.0, 76.0)
					"harbor_timber_barrier": area_size = Vector2(132.0, 66.0)
					"harbor_metal_gate": area_size = Vector2(156.0, 92.0)
					"wood_crates": area_size = Vector2(130.0, 88.0)
					"brick_barrier": area_size = Vector2(150.0, 48.0)
					"fallen_bike": area_size = Vector2(146.0, 44.0)
					"fallen_lamp": area_size = Vector2(168.0, 42.0)
					"market_cart": area_size = Vector2(148.0, 68.0)
					"quay_rubble": area_size = Vector2(162.0, 48.0)
					_: area_size = Vector2(38.0, 29.0) if kind == "light_obstacle" else Vector2(78.0, 43.0)
			var area := Area2D.new()
			area.name = "AmsterdamEncounter_%02d_%02d" % [layout_index, member_index]
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

func _sync_static_encounter_heights() -> void:
	# The upper route changes the height of the bridge and exit approach. Move
	# their object collision areas to the same surface as their drawn sprites.
	for event in _encounters:
		if String(event.get("kind", "")) in ["zombie_group", "runner_group"]:
			continue
		var members_data: Array = event.get("members_data", [])
		for member in members_data:
			var area: Area2D = member.get("area") as Area2D
			if not is_instance_valid(area):
				continue
			var x: float = float(member.get("x", area.position.x))
			var area_height: float = float(member.get("area_height", 48.0))
			area.position = Vector2(x, height_at(x) - area_height * 0.5)

func _physics_process(delta: float) -> void:
	if _finish_safe:
		_elapsed_s+=delta
		for enemy in _finish_followers:
			enemy.x=move_toward(float(enemy.x),float(enemy.target),115*delta)
			enemy.phase+=delta*7
		queue_redraw()
		return
	# The road draw window follows the camera even between encounters.
	queue_redraw()
	if _lock_water_entered:
		_lock_splash_time += delta
	_update_close_range_weapon(delta)
	super._physics_process(delta)
	if _wagon == null:
		return
	if lock_flight_active:
		_update_lock_flight(delta)
		return
	if _wagon.freeze:
		return
	_update_lock_crossing(delta)
	if lock_flight_active:
		return
	if not _harbor_ramp_triggered and _wagon.position.x >= HARBOR_RAMP_LIP_M * PIXELS_PER_METER:
		_harbor_ramp_triggered = true
		if _wagon.linear_velocity.x >= 12.0 * PIXELS_PER_METER:
			_wagon.launch_from_ramp(6.0, 0.35)
	if not _upper_launch_triggered and _wagon.position.x >= RAMP_LIP_M * PIXELS_PER_METER:
		_upper_launch_triggered = true
		# Give every speed the same takeoff profile. The gap and gravity then
		# decide whether the leading axle reaches the one-way deck in time.
		var axle_offset_m: float = _wagon.front_spring.position.x / PIXELS_PER_METER
		var flight_time: float = ((UPPER_BRIDGE_START_M * PIXELS_PER_METER - _wagon.position.x) / PIXELS_PER_METER - axle_offset_m) / BRANCH_MIN_SPEED_MPS
		var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity", 350.0)) * _wagon.gravity_scale
		var target_y: float = UPPER_BRIDGE_Y - _wagon.wheel_ground_clearance()
		var lift_speed: float = (_wagon.position.y - target_y) / flight_time + 0.5 * gravity * flight_time
		_wagon.launch_from_ramp(9.0)
		_wagon.linear_velocity.y = -maxf(0.0, lift_speed)
	if _upper_launch_triggered and not _upper_edge_checked:
		var axle_y: float = 25.0 + float(_wagon.tire_level) * 1.15
		var front_wheel: Vector2 = _wagon.to_global(Vector2(_wagon.front_spring.position.x,axle_y))
		var radius: float = _wagon.wheel_ground_clearance()-axle_y
		var bottom_point: Vector2 = front_wheel + Vector2(0.0,radius)
		if not _upper_previous_wheel_valid:
			_upper_previous_wheel = bottom_point
			_upper_previous_wheel_valid = true
		if front_wheel.x >= UPPER_BRIDGE_START_M * PIXELS_PER_METER:
			_upper_edge_checked = true
			var sweep: float = clampf((UPPER_BRIDGE_START_M * PIXELS_PER_METER - _upper_previous_wheel.x) / maxf(0.001,bottom_point.x-_upper_previous_wheel.x),0.0,1.0)
			_upper_missed_edge = lerpf(_upper_previous_wheel.y,bottom_point.y,sweep) > UPPER_BRIDGE_Y + 0.5
			if _upper_missed_edge:
				# Suspension rays must not pull a visibly too-low wheel up through the ledge.
				_wagon.front_spring.add_exception(_upper_bridge_body)
				_wagon.rear_spring.add_exception(_upper_bridge_body)
				_wagon.add_collision_exception_with(_upper_bridge_body)
		_upper_previous_wheel = bottom_point
	if _upper_launch_triggered and not _branch_decided:
		var on_deck: bool = _upper_edge_checked and not _upper_missed_edge and (_wagon.front_spring.get_collider() == _upper_bridge_body or _wagon.rear_spring.get_collider() == _upper_bridge_body)
		var below_deck: bool = _wagon.position.x >= UPPER_BRIDGE_START_M * PIXELS_PER_METER and _wagon.position.y > UPPER_BRIDGE_Y + 18.0
		if on_deck or below_deck or _upper_missed_edge:
			_branch_decided = true
			_upper_route_chosen = on_deck
			if on_deck:
				_upper_ramp_collision.set_deferred("disabled", false)
				_sync_static_encounter_heights()
			route_decided.emit("OBERE GRACHTENBRÜCKE · SPRUNGWEG" if on_deck else "ZU WENIG SCHWUNG · UNTER DER BRÜCKE WEITER", on_deck)

	for coin_index in range(_upper_coin_meters.size()):
		if not _upper_route_chosen:
			break
		if _upper_coins_collected.has(coin_index):
			continue
		var coin_x: float = _upper_coin_meters[coin_index] * PIXELS_PER_METER
		var coin_y: float = UPPER_BRIDGE_Y - 47.0
		if _wagon.chassis_overlaps_world_rect(Rect2(Vector2(coin_x - 12.0, coin_y - 12.0), Vector2(24.0, 24.0))):
			_upper_coins_collected[coin_index] = true
			bonus_coin_collected.emit(25)
			queue_redraw()

func _update_lock_crossing(delta: float) -> void:
	var meter: float = _wagon.position.x / PIXELS_PER_METER
	if not _lock_warned and meter >= LOCK_START_M - 75.0 and meter < LOCK_LIP_M:
		_lock_warned = true
		lock_approach.emit()
	if not _lock_launched and meter >= LOCK_LIP_M and meter < LOCK_LANDING_M:
		_lock_launched = true
		_lock_flight_time = 0.0
		_lock_flight_speed = maxf(0.0, _wagon.linear_velocity.x)
		_lock_release_clearance = _wagon.wheel_ground_clearance()
		_lock_edge_checked = false
		_lock_missed = false
		lock_flight_active = true
		_wagon.freeze = true
		_wagon.position = Vector2(LOCK_LIP_M * PIXELS_PER_METER, lock_surface_y(LOCK_LIP_M) - _lock_release_clearance)
		_wagon.rotation = 0.0
		_wagon.angular_velocity = 0.0
		_wagon.airborne = true
		_wagon.linear_velocity = Vector2(_lock_flight_speed, 0.0)
	if meter >= LOCK_START_M and meter < LOCK_REJOIN_M and not _lock_water_entered and _wagon.position.y + 20.0 >= lock_water_y():
		_lock_water_entered = true
		_lock_splash_x = _wagon.position.x
		lock_water_entered.emit()

func _update_lock_flight(delta: float) -> void:
	_lock_flight_time += delta
	var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity", 350.0)) * _wagon.gravity_scale
	var deck_y: float = lock_surface_y(LOCK_LANDING_M)
	var release_y: float = lock_surface_y(LOCK_LIP_M) - _lock_release_clearance
	var x: float = LOCK_LIP_M * PIXELS_PER_METER + _lock_flight_speed * _lock_flight_time
	var y: float = release_y + 0.5 * gravity * _lock_flight_time * _lock_flight_time
	var axle: float = _wagon.front_spring.position.x
	var edge_time: float = ((LOCK_LANDING_M - LOCK_LIP_M) * PIXELS_PER_METER - axle) / maxf(1.0, _lock_flight_speed)
	if not _lock_edge_checked and _lock_flight_time >= edge_time:
		_lock_edge_checked = true
		# Swept wheel/edge contact at the exact crossing time avoids a one-frame
		# raycast lottery. There is no speed comparison: the wheel must clear wood.
		var wheel_bottom_at_edge: float = release_y + 0.5 * gravity * edge_time * edge_time + _lock_release_clearance
		_lock_missed = wheel_bottom_at_edge > deck_y + 0.02
	var touch_time: float = sqrt(2.0 * LOCK_LANDING_DROP_PX / gravity)
	if _lock_edge_checked and not _lock_missed and _lock_flight_time >= touch_time:
		lock_flight_active = false
		_wagon.position = Vector2(x, deck_y - _lock_release_clearance)
		_wagon.freeze = false
		_wagon.linear_velocity = Vector2(_lock_flight_speed, 0.0)
		_wagon.angular_velocity = 0.0
		_wagon.airborne = false
		_wagon.front_spring.force_raycast_update()
		_wagon.rear_spring.force_raycast_update()
		_wagon.sleeping = false
		return
	if _lock_missed:
		# A short trajectory hits the visible near face of the landing quay.
		# Horizontal contact stops it there; vertical motion remains gravity only.
		var contact_reach: float = _wagon.front_contact_offset_px() if y + 25.0 >= deck_y else axle + _wagon.wheel_visual_radius()
		x = minf(x, LOCK_LANDING_M * PIXELS_PER_METER - contact_reach)
	_wagon.position = Vector2(x, y)
	_wagon.linear_velocity = Vector2(_lock_flight_speed, gravity * _lock_flight_time)
	_wagon.wheel_turn += _lock_flight_speed * delta / maxf(1.0, _wagon.wheel_radius)
	_wagon.queue_redraw()
	if y + 20.0 >= lock_water_y():
		lock_flight_active = false
		_lock_water_entered = true
		_lock_splash_x = x
		lock_water_entered.emit()

func _update_close_range_weapon(delta: float) -> void:
	if not is_instance_valid(_wagon) or _wagon.freeze or not _wagon.weapon_active or _wagon.weapon_level <= 0:
		return
	_weapon_cooldown_s = maxf(0.0, _weapon_cooldown_s - delta)
	if _weapon_cooldown_s > 0.0:
		return
	if explosives.try_weapon(_wagon):
		_weapon_cooldown_s = 0.12
		return
	if _shoot_close_zombie():
		_weapon_cooldown_s = 0.12

func _draw() -> void:
	_draw_wreck_horde()
	for enemy in _finish_followers:
		_draw_zombie(float(enemy.x),height_at(float(enemy.x)),int(enemy.variant),"fast",1.0,float(enemy.phase),-1.0)
	# Backdrop owns the continuous canal panorama and quay wall in screen space.
	# Keep this course layer focused on the drivable surface and set pieces so it
	# cannot paint a second flat water slab over the background's brick support.
	_draw_harbor_scenery()
	_draw_track()
	_draw_quay_life_details()
	_draw_roadside_markers()
	_draw_finish_marker()
	_draw_encounters(_wreck_horde.is_empty())
	_draw_branch_coins()
	_draw_reactions()
	_draw_impact_particles()

func _draw_finish_marker() -> void:
	var x:float=(START_M+AMSTERDAM_LENGTH_M)*PIXELS_PER_METER
	var bounds:Vector2=_visible_world_x_bounds(330)
	if x<bounds.x or x>bounds.y:return
	var ground:float=_base_height_at(x)
	# A fixed finish mark on the roadway, not a floating text banner.
	for i in range(7):
		var px:float=x-17+i*5
		draw_rect(Rect2(px,ground-3,5,5),Color("eee5ca") if i%2==0 else Color("303d39"))
	for offset in [-92.0,-68.0]:
		draw_polyline(PackedVector2Array([Vector2(x+offset-7,ground-3),Vector2(x+offset,ground-1),Vector2(x+offset-7,ground+1)]),Color("d8bd81"),2,true)

func _draw_harbor_scenery() -> void:
	var bounds: Vector2 = _visible_world_x_bounds(200.0)
	if bounds.y < HARBOR_START_M * PIXELS_PER_METER:
		return
	var source: Rect2 = VISUALS.CRANE_SOURCE
	var size := Vector2(170.0 * source.size.x / source.size.y, 170.0)
	for meter in [1191.0, 1412.0, 1555.0, 1660.0, 1743.0]:
		var x: float = meter * PIXELS_PER_METER
		if x < bounds.x or x > bounds.y:
			continue
		var ground: float = _base_height_at(x)
		# Seat the complete pedestal in the rear quay edge; the road masks its feet.
		var origin := Vector2(x - size.x * 0.30, ground + 7.0 - size.y)
		if meter in [1412.0, 1660.0]:
			# Omit the baked-in dangling hook where the live swinging load takes over.
			draw_texture_rect_region(VISUALS.CRANE, Rect2(origin, size * Vector2(0.70, 1.0)), Rect2(source.position, source.size * Vector2(0.70, 1.0)), Color8(204, 213, 202))
			draw_texture_rect_region(VISUALS.CRANE, Rect2(origin + Vector2(size.x * 0.70, 0.0), size * Vector2(0.30, 0.28)), Rect2(source.position + Vector2(source.size.x * 0.70, 0.0), source.size * Vector2(0.30, 0.28)), Color8(204, 213, 202))
		else:
			draw_texture_rect_region(VISUALS.CRANE, Rect2(origin, size), source, Color8(204, 213, 202))

func _draw_harbor_metal_gate(x: float, ground: float, broken: bool) -> void:
	var left := Vector2(x - 70.0, ground - 80.0)
	var right := Vector2(x + 68.0, ground - (10.0 if broken else 63.0))
	if broken:
		left += Vector2(22.0, 65.0)
	var bent := Vector2(x + 6.0, ground - (24.0 if broken else 72.0))
	var frame := PackedVector2Array([left, bent, right])
	draw_polyline(frame, Color8(36, 45, 43), 14.0, true)
	draw_polyline(frame, Color8(131, 148, 135), 7.0, true)
	for index in range(7):
		var progress: float = float(index) / 6.0
		var top: Vector2 = left.lerp(bent, progress * 2.0) if progress < 0.5 else bent.lerp(right, progress * 2.0 - 1.0)
		var foot := Vector2(top.x + (13.0 if broken else 0.0), ground - 3.0)
		draw_line(top, foot, Color8(58, 72, 66), 7.0, true)
		draw_line(top + Vector2(1.0, 0.0), foot + Vector2(1.0, 0.0), Color8(145, 156, 138), 2.0, true)
		draw_circle(top, 2.8, Color8(191, 139, 78))
	if not broken:
		draw_line(left + Vector2(5.0, 12.0), Vector2(right.x - 9.0, ground - 6.0), Color8(190, 137, 65), 8.0, true)

func _draw_amsterdam_environment() -> void:
	var left: float = 0.0
	var right: float = ROAD_END_M * PIXELS_PER_METER
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		var half_view: float = get_viewport_rect().size.x / maxf(0.2, camera.zoom.x) * 0.75
		left = maxf(0.0, camera.global_position.x - half_view)
		right = minf(ROAD_END_M * PIXELS_PER_METER, camera.global_position.x + half_view)
	draw_rect(Rect2(left, 540.0, right - left, 310.0), Color8(36, 87, 91, 160))
	for water_index in range(5):
		var water_y: float = 582.0 + float(water_index) * 33.0
		var start_x: float = left + fposmod(float(water_index) * 117.0, 210.0)
		while start_x < right:
			draw_line(Vector2(start_x, water_y), Vector2(start_x + 78.0, water_y + 1.0), Color8(164, 194, 176, 82), 1.2, true)
			start_x += 235.0
	# A damaged canal boat and a collapsed lamp sit below the playable surface.
	# Decorative canal boat removed; the drivable barge is preserved.
	draw_line(Vector2(681.0 * PIXELS_PER_METER, 609.0), Vector2(687.0 * PIXELS_PER_METER, 658.0), Color8(74, 78, 68, 180), 7.0, true)
	draw_line(Vector2(681.0 * PIXELS_PER_METER, 609.0), Vector2(695.0 * PIXELS_PER_METER, 615.0), Color8(74, 78, 68, 180), 3.0, true)

func _draw_amsterdam_houses() -> void:
	var camera := get_viewport().get_camera_2d()
	var half_view: float = get_viewport_rect().size.x / maxf(0.2, camera.zoom.x) * 0.8 if camera != null else 900.0
	var center_x: float = camera.global_position.x if camera != null else 600.0
	var first_house: int = maxi(0, int(floor((center_x - half_view) / 520.0)) - 1)
	var last_house: int = mini(63, int(ceil((center_x + half_view) / 520.0)) + 1)
	for house_index in range(first_house, last_house + 1):
		var x: float = float(house_index) * 520.0 - 130.0
		var width: float = 260.0 + float((house_index * 17) % 5) * 16.0
		var height: float = 160.0 + float((house_index * 31) % 4) * 24.0
		var top: float = 470.0 - height
		var brick: Color = Color8(72 + (house_index % 3) * 9, 63 + (house_index % 4) * 6, 52 + (house_index % 5) * 5, 220)
		draw_rect(Rect2(x, top + 30.0, width, height - 30.0), brick)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 7.0, top + 32.0), Vector2(x + width * 0.5, top - 31.0),
			Vector2(x + width + 7.0, top + 32.0)
		]), brick.lightened(0.12))
		draw_line(Vector2(x + 8.0, top + 32.0), Vector2(x + width * 0.5, top - 31.0), Color8(183, 145, 101, 190), 3.0, true)
		draw_line(Vector2(x + width * 0.5, top - 31.0), Vector2(x + width - 8.0, top + 32.0), Color8(183, 145, 101, 190), 3.0, true)
		for floor_index in range(3):
			for window_index in range(2):
				var window_x: float = x + 31.0 + float(window_index) * 84.0
				var window_y: float = top + 55.0 + float(floor_index) * 49.0
				draw_rect(Rect2(window_x, window_y, 39.0, 29.0), Color8(23, 37, 37, 230))
				draw_rect(Rect2(window_x + 4.0, window_y + 4.0, 31.0, 21.0), Color8(187, 135, 74, 118) if (house_index + floor_index + window_index) % 7 == 0 else Color8(41, 63, 65, 235))
				draw_line(Vector2(window_x + 19.0, window_y + 4.0), Vector2(window_x + 19.0, window_y + 26.0), Color8(105, 104, 86), 2.0, true)
		draw_line(Vector2(x - 6.0, 470.0), Vector2(x + width + 6.0, 470.0), Color8(49, 48, 42, 220), 5.0, true)
		if house_index % 3 == 1:
			var cable_x: float = x + width * 0.5
			draw_line(Vector2(cable_x, 216.0), Vector2(cable_x + 260.0, 218.0), Color8(40, 52, 52, 185), 2.0, true)
			draw_line(Vector2(cable_x + 129.0, 218.0), Vector2(cable_x + 141.0, 244.0), Color8(40, 52, 52, 185), 2.0, true)
	# Tram rails, cobbles, bikes and streetlamps make the road read as a city street.
	var street_left: float = maxf(0.0, center_x - half_view)
	var street_right: float = minf(ROAD_END_M * PIXELS_PER_METER, center_x + half_view)
	var bike_x: float = 117.0 * PIXELS_PER_METER
	while bike_x < street_left - 80.0:
		bike_x += 12.0 * PIXELS_PER_METER
	while bike_x < street_right + 100.0:
		var ground: float = height_at(bike_x)
		if int(round(bike_x / (12.0 * PIXELS_PER_METER))) % 3 == 1:
			draw_circle(Vector2(bike_x, ground - 4.0), 7.0, Color8(34, 39, 34, 230), false, 1.6, true)
			draw_circle(Vector2(bike_x + 26.0, ground - 4.0), 7.0, Color8(34, 39, 34, 230), false, 1.6, true)
			draw_line(Vector2(bike_x, ground - 4.0), Vector2(bike_x + 13.0, ground - 22.0), Color8(125, 103, 69, 235), 2.0, true)
			draw_line(Vector2(bike_x + 13.0, ground - 22.0), Vector2(bike_x + 26.0, ground - 4.0), Color8(125, 103, 69, 235), 2.0, true)
		bike_x += 12.0 * PIXELS_PER_METER
	var rail_offset: float = 56.0
	var rail_meter: float = floor(street_left / (8.0 * PIXELS_PER_METER)) * 8.0
	while rail_meter * PIXELS_PER_METER < street_right:
		var rail_x: float = rail_meter * PIXELS_PER_METER
		var rail_y: float = height_at(rail_x) + rail_offset
		draw_line(Vector2(rail_x, rail_y), Vector2(rail_x + 92.0, height_at(rail_x + 92.0) + rail_offset), Color8(66, 76, 68, 195), 2.0, true)
		rail_meter += 8.0

func _draw_track() -> void:
	var top_edge := PackedVector2Array()
	var visible_bounds: Vector2 = _visible_world_x_bounds(180.0)
	var visible_left: float = maxf(0.0, visible_bounds.x)
	var visible_right: float = minf(ROAD_END_M * PIXELS_PER_METER, visible_bounds.y)
	var sample_step_px: float = DRAW_SAMPLE_M * PIXELS_PER_METER
	var sample_count: int = int(ROAD_END_M / DRAW_SAMPLE_M)
	var first_sample: int = maxi(0, int(floor(visible_left / sample_step_px)) - 1)
	var last_sample: int = mini(sample_count, int(ceil(visible_right / sample_step_px)) + 1)
	var sample_xs: Array[float] = []
	for sample_index in range(first_sample, last_sample + 1):
		sample_xs.append(float(sample_index) * sample_step_px)
	for edge in [BARGE_START_M * PIXELS_PER_METER, BARGE_END_M * PIXELS_PER_METER, (LOCK_LIP_M - 14.0) * PIXELS_PER_METER, LOCK_DECK_END_M * PIXELS_PER_METER]:
		if edge >= visible_left and edge <= visible_right:
			sample_xs.append(edge)
	sample_xs.sort()
	for x in sample_xs:
		top_edge.append(Vector2(x, _base_height_at(x)))
	# Support legs are drawn before the street: they make the raised route feel
	# attached to the canal crossing, while the opaque road hides their lower ends
	# so nothing protrudes into the underpass lane.
	_draw_amsterdam_road_segment(top_edge)
	_draw_amsterdam_road_texture()
	_draw_barge()
	_draw_lock_bridge()
	# The first timber kicker follows the existing hill profile exactly; the
	# continuous road collision remains the driveable top surface beneath it.
	_draw_road_lamps()


func _draw_road_lamps() -> void:
	# Worn road lamps are world-anchored and move with the actual street.
	var visible_markers: Vector2 = _visible_world_x_bounds(80.0)
	var lamp_meter: float = maxf(38.0, floor(maxf(0.0, visible_markers.x) / (76.0 * PIXELS_PER_METER)) * 76.0 + 38.0)
	while lamp_meter * PIXELS_PER_METER < minf(ROAD_END_M * PIXELS_PER_METER, visible_markers.y):
		if (lamp_meter > BARGE_START_M and lamp_meter < BARGE_END_M) or (lamp_meter > LOCK_START_M and lamp_meter < LOCK_DECK_END_M):
			lamp_meter += 76.0
			continue
		var lamp_x: float = lamp_meter * PIXELS_PER_METER
		var lamp_y: float = _base_height_at(lamp_x)
		draw_line(Vector2(lamp_x, lamp_y), Vector2(lamp_x - 4.0, lamp_y - 72.0), Color8(57, 65, 57, 230), 4.0, true)
		draw_line(Vector2(lamp_x - 4.0, lamp_y - 72.0), Vector2(lamp_x + 18.0, lamp_y - 78.0), Color8(57, 65, 57, 230), 3.0, true)
		draw_circle(Vector2(lamp_x + 18.0, lamp_y - 78.0), 4.0, Color8(231, 172, 91, 190))
		lamp_meter += 76.0

func _draw_roadside_markers() -> void:
	var bounds: Vector2 = _visible_world_x_bounds(50.0)
	var meter: float = maxf(25.0, floor((bounds.x / PIXELS_PER_METER - 25.0) / 38.0) * 38.0 + 25.0)
	while meter * PIXELS_PER_METER < minf(bounds.y, ROAD_END_M * PIXELS_PER_METER):
		if (meter <= BARGE_START_M or meter >= BARGE_END_M) and (meter <= LOCK_START_M or meter >= LOCK_DECK_END_M):
			var x: float = meter * PIXELS_PER_METER
			var ground: float = height_at(x)
			draw_line(Vector2(x, ground - 4.0), Vector2(x, ground - 33.0), Color8(91, 102, 83), 2.0, true)
			draw_circle(Vector2(x, ground - 35.0), 3.0, Color8(226, 180, 97))
		meter += 38.0

func _draw_barge() -> void:
	var bounds: Vector2 = _visible_world_x_bounds(220.0)
	var gap: Vector2 = quay_gap_world_bounds()
	if gap.y < bounds.x or gap.x > bounds.y:
		return
	var deck_left: float = BARGE_DECK_START_M * PIXELS_PER_METER
	var deck_right: float = BARGE_DECK_END_M * PIXELS_PER_METER
	var deck_y: float = barge_deck_y()
	var hull_source := Rect2(40.0, 204.0, 2092.0, 332.0)
	var hull_scale: float = (deck_right - deck_left) / hull_source.size.x
	var hull_rect := Rect2(Vector2(deck_left, deck_y - 136.0 * hull_scale), hull_source.size * hull_scale)
	var ramp_overlap: float = 410.0
	_draw_barge_hull(Vector2(deck_left - ramp_overlap, deck_right + ramp_overlap), hull_rect, hull_source)
	_draw_barge_ramp(Vector2(gap.x, _quay_height_at(gap.x)), Vector2(deck_left, deck_y))
	_draw_barge_ramp(Vector2(deck_right, deck_y), Vector2(gap.y, _quay_height_at(gap.y)))
	for side in [-1.0, 1.0]:
		var dock_x: float = gap.x - 42.0 if side < 0.0 else gap.y + 42.0
		var hull_x: float = deck_left - ramp_overlap + 48.0 if side < 0.0 else deck_right + ramp_overlap - 48.0
		var dock_base := Vector2(dock_x, _quay_height_at(dock_x) + 34.0)
		var hull_base := Vector2(hull_x, deck_y + 22.0)
		_draw_mooring_rope(dock_base + Vector2(-side * 23.0, -14.0), hull_base + Vector2(side * 23.0, -14.0))
		# Small bolted ledges support the quay bollards below the driving lane.
		draw_colored_polygon(PackedVector2Array([
			dock_base + Vector2(-40.0, -1.0), dock_base + Vector2(40.0, -1.0),
			dock_base + Vector2(36.0, 11.0), dock_base + Vector2(-36.0, 11.0)
		]), Color8(121, 113, 91))
		draw_line(dock_base + Vector2(-40.0, -1.0), dock_base + Vector2(40.0, -1.0), Color8(202, 183, 141), 2.0, true)
		_draw_mooring_bollard(dock_base, -side)
		_draw_mooring_bollard(hull_base, side)
	var water_y: float = hull_rect.end.y + 2.0
	for ripple in range(8):
		var x: float = lerpf(deck_left, deck_right, float(ripple) / 7.0)
		draw_line(Vector2(x - 25.0, water_y + float(ripple % 3) * 5.0), Vector2(x + 35.0, water_y + float(ripple % 3) * 5.0), Color8(146, 175, 155, 100), 1.5, true)

func _draw_barge_ramp(start: Vector2, end: Vector2) -> void:
	var high: Vector2 = start if start.y < end.y else end
	var low: Vector2 = end if start.y < end.y else start
	# Artwork anchors follow the straight driving edge. Its metal feet and toe
	# share a horizontal baseline, so they visibly sit on top of the hull deck.
	var scale_x: float = (low.x - high.x) / 2035.0
	var scale_y: float = (low.y - high.y) / 408.0
	var transform := Transform2D(Vector2(scale_x, 0.0), Vector2(0.0, scale_y), high - Vector2(65.0 * scale_x, 180.0 * scale_y))
	for source_x in [170.0, 650.0, 2030.0]:
		var foot: Vector2 = transform * Vector2(source_x, 603.0)
		var shadow := PackedVector2Array()
		for point in range(20):
			var angle: float = TAU * float(point) / 20.0
			shadow.append(foot + Vector2(cos(angle) * 23.0, sin(angle) * 3.0))
		draw_colored_polygon(shadow, Color8(32, 25, 17, 95))
	draw_set_transform_matrix(transform)
	draw_texture_rect(BARGE_RAMP_TEXTURE, Rect2(Vector2.ZERO, BARGE_RAMP_TEXTURE.get_size()), false)
	draw_set_transform(Vector2.ZERO)

func _draw_mooring_bollard(base: Vector2, facing: float) -> void:
	draw_set_transform(base, 0.0, Vector2(facing, 1.0))
	draw_texture_rect_region(BARGE_BOLLARD_TEXTURE, Rect2(-31.0, -34.0, 62.0, 34.0), Rect2(65.0, 145.0, 1395.0, 770.0))
	draw_set_transform(Vector2.ZERO)

func _draw_mooring_rope(start: Vector2, end: Vector2) -> void:
	var rope := PackedVector2Array()
	for index in range(49):
		var progress: float = float(index) / 48.0
		rope.append(start.lerp(end, progress) + Vector2(0.0, sin(progress * PI) * 26.0))
	draw_polyline(rope, Color8(41, 31, 21), 6.5, true)
	draw_polyline(rope, Color8(166, 123, 71), 4.7, true)
	var highlight := PackedVector2Array()
	for point in rope:
		highlight.append(point - Vector2(0.0, 1.0))
	draw_polyline(highlight, Color8(221, 189, 126), 1.3, true)
	for index in range(2, rope.size() - 2, 2):
		var tangent: Vector2 = (rope[index + 1] - rope[index - 1]).normalized()
		var across: Vector2 = tangent.orthogonal()
		draw_line(rope[index] - tangent * 1.3 - across * 1.8, rope[index] + tangent * 1.3 + across * 1.8, Color8(99, 70, 39), 0.85, true)

func _draw_barge_hull(bounds: Vector2, natural_rect: Rect2, source: Rect2) -> void:
	# Preserve tire fenders, end posts and rail details at their original scale.
	# The two plain hull bays extend underneath the approach ramps.
	var columns := PackedFloat32Array([40.0, 340.0, 570.0, 970.0, 1200.0, 1600.0, 1830.0, 2132.0])
	var scale: float = natural_rect.size.x / source.size.x
	var extension: float = (bounds.y - bounds.x - natural_rect.size.x) * 0.5
	var x: float = bounds.x
	for index in range(columns.size() - 1):
		var width: float = (columns[index + 1] - columns[index]) * scale
		if index == 2 or index == 4:
			width += extension
		draw_texture_rect_region(BARGE_TEXTURE, Rect2(x, natural_rect.position.y, width, natural_rect.size.y), Rect2(columns[index], source.position.y, columns[index + 1] - columns[index], source.size.y))
		x += width

func _draw_amsterdam_road_segment(top_edge: PackedVector2Array) -> void:
	if top_edge.size() < 2:
		return
	# draw_colored_polygon triangulates convex polygons. The former full-width
	# wavy strip was concave, so Compatibility could leave the canal/wall visible
	# through the road. Small convex quads keep every road section opaque.
	for index in range(top_edge.size() - 1):
		var a: Vector2 = top_edge[index]
		var b: Vector2 = top_edge[index + 1]
		if _lock_art_span(a.x, b.x) or (b.x > BARGE_START_M * PIXELS_PER_METER and a.x < BARGE_END_M * PIXELS_PER_METER):
			continue
		var body_quad := PackedVector2Array([a, b, b + Vector2(0.0, 30.0), a + Vector2(0.0, 30.0)])
		draw_colored_polygon(body_quad, Color8(57, 64, 59))
		var fascia_quad := PackedVector2Array([
			a + Vector2(0.0, 20.0), b + Vector2(0.0, 20.0),
			b + Vector2(0.0, 28.0), a + Vector2(0.0, 28.0)
		])
		draw_colored_polygon(fascia_quad, Color8(78, 72, 60))
	# Stone outlines end at the quay; the barge carries its own painted edges.
	for index in range(top_edge.size() - 1):
		var a: Vector2 = top_edge[index]
		var b: Vector2 = top_edge[index + 1]
		if _lock_art_span(a.x, b.x) or (b.x > BARGE_START_M * PIXELS_PER_METER and a.x < BARGE_END_M * PIXELS_PER_METER):
			continue
		draw_line(a, b, Color8(42, 42, 37), 4.0, true)
		draw_line(a + Vector2(0.0, 29.0), b + Vector2(0.0, 29.0), Color8(34, 37, 34), 3.0, true)

func _draw_amsterdam_road_texture() -> void:
	# A single repeating stone texture follows the road profile. The former
	# per-stone polygons and bevel lines were emitted again on every impact redraw.
	var visible_bounds: Vector2 = _visible_world_x_bounds(100.0)
	var left_x: float = maxf(0.0, visible_bounds.x)
	var right_x: float = minf(ROAD_END_M * PIXELS_PER_METER, visible_bounds.y)
	if right_x <= left_x:
		return
	var tile_size: Vector2 = VISUALS.material_size(AMSTERDAM_COBBLE_TILE, 216.0)
	var sample_step_px: float = DRAW_SAMPLE_M * PIXELS_PER_METER
	var first_sample: int = maxi(0, int(floor(left_x / sample_step_px)) - 1)
	var last_sample: int = mini(int(ROAD_END_M / DRAW_SAMPLE_M), int(ceil(right_x / sample_step_px)) + 1)
	for sample_index in range(first_sample, last_sample):
		var x_a: float = float(sample_index) * sample_step_px
		var x_b: float = float(sample_index + 1) * sample_step_px
		if _lock_art_span(x_a, x_b):
			continue
		if x_a < BARGE_START_M * PIXELS_PER_METER:
			x_b = minf(x_b, BARGE_START_M * PIXELS_PER_METER)
		if x_b > BARGE_END_M * PIXELS_PER_METER:
			x_a = maxf(x_a, BARGE_END_M * PIXELS_PER_METER)
		if x_a >= BARGE_START_M * PIXELS_PER_METER and x_b <= BARGE_END_M * PIXELS_PER_METER:
			continue
		var y_a: float = _base_height_at(x_a) + 0.5
		var y_b: float = _base_height_at(x_b) + 0.5
		var road_quad := PackedVector2Array([
			Vector2(x_a, y_a), Vector2(x_b, y_b),
			Vector2(x_b, y_b + 24.0), Vector2(x_a, y_a + 24.0)
		])
		var road_uvs := PackedVector2Array([
			Vector2(x_a / tile_size.x, 0.0),
			Vector2(x_b / tile_size.x, 0.0),
			Vector2(x_b / tile_size.x, 24.0 / tile_size.y),
			Vector2(x_a / tile_size.x, 24.0 / tile_size.y)
		])
		draw_colored_polygon(road_quad, Color.WHITE, road_uvs, AMSTERDAM_COBBLE_TILE)
	# A pale stone coping stays above the cobbles and remains attached to the
	# collision profile. Its joints are batched as one multi-line draw operation.
	var curb_joints := PackedVector2Array()
	for sample_index in range(first_sample, last_sample):
		var x_a: float = float(sample_index) * sample_step_px
		var x_b: float = float(sample_index + 1) * sample_step_px
		if _lock_art_span(x_a, x_b):
			continue
		if x_a < BARGE_START_M * PIXELS_PER_METER:
			x_b = minf(x_b, BARGE_START_M * PIXELS_PER_METER)
		if x_b > BARGE_END_M * PIXELS_PER_METER:
			x_a = maxf(x_a, BARGE_END_M * PIXELS_PER_METER)
		if x_a >= BARGE_START_M * PIXELS_PER_METER and x_b <= BARGE_END_M * PIXELS_PER_METER:
			continue
		var curb_quad := PackedVector2Array([
			Vector2(x_a, _base_height_at(x_a)), Vector2(x_b, _base_height_at(x_b)),
			Vector2(x_b, _base_height_at(x_b) + 7.0), Vector2(x_a, _base_height_at(x_a) + 7.0)
		])
		draw_colored_polygon(curb_quad, Color8(166, 155, 130, 26))
		draw_line(curb_quad[0] + Vector2(0.0, 1.0), curb_quad[1] + Vector2(0.0, 1.0), Color8(199, 182, 145, 160), 0.9, true)
		var chip_x: float = lerpf(x_a, x_b, 0.28 + float(sample_index % 5) * 0.10)
		var chip_y: float = _base_height_at(chip_x) + 1.0
		draw_line(Vector2(chip_x - 7.0, chip_y + 1.0), Vector2(chip_x + 4.0, chip_y + 2.4), Color8(224, 207, 168, 170), 1.2, true)
		if sample_index % 3 == 0:
			draw_polyline(PackedVector2Array([Vector2(chip_x, chip_y), Vector2(chip_x + 1.0, chip_y + 3.0), Vector2(chip_x + 5.0, chip_y + 5.0)]), Color8(95, 88, 72, 195), 1.0, true)
	var joint_x: float = floor(left_x / 32.0) * 32.0
	while joint_x <= right_x + 32.0:
		if _lock_art_span(joint_x, joint_x) or (joint_x > BARGE_START_M * PIXELS_PER_METER and joint_x < BARGE_END_M * PIXELS_PER_METER):
			joint_x += 32.0
			continue
		curb_joints.append(Vector2(joint_x, _base_height_at(joint_x) + 1.0))
		curb_joints.append(Vector2(joint_x, _base_height_at(joint_x) + 7.0))
		joint_x += 32.0
	if not curb_joints.is_empty():
		draw_multiline(curb_joints, Color8(68, 61, 51, 225), 1.2, true)

func _draw_quay_foundation() -> void:
	# Amsterdam's road sits on a brick canal retaining wall, matching the art in
	# the backdrop. Only the visible world window is textured, and the actual
	# drivable surface/collision remains the road height chain above it.
	# Derive the draw window from the actual canvas transform. A zoom-only estimate
	# can stop short at one edge when the camera is eased toward the wagon, exposing
	# the dark water backing below the road. Transforming viewport corners covers
	# exactly the visible course at any zoom or camera offset.
	var visible_bounds: Vector2 = _visible_world_x_bounds(120.0)
	var visible_left: float = maxf(0.0, visible_bounds.x)
	var visible_right: float = minf(ROAD_END_M * PIXELS_PER_METER, visible_bounds.y)
	if visible_right <= visible_left:
		return
	const WALL_TOP: float = 45.0
	const WALL_BOTTOM: float = 310.0
	var first_column: int = int(floor(visible_left / 35.0)) - 2
	var last_column: int = int(ceil(visible_right / 35.0)) + 2
	var wall_base := PackedVector2Array()
	for column in range(first_column, last_column + 1):
		var x: float = float(column) * 35.0
		wall_base.append(Vector2(x, height_at(x) + WALL_TOP))
	for column in range(last_column, first_column - 1, -1):
		var x: float = float(column) * 35.0
		wall_base.append(Vector2(x, height_at(x) + WALL_BOTTOM))
	draw_colored_polygon(wall_base, Color8(58, 54, 48))
	# One repeating, shaded brick texture replaces thousands of individual brick
	# polygons/edges. The UVs follow the same sloped wall profile as the road.
	var brick_size: Vector2 = Vector2(294.0, 294.0)
	var masonry := PackedVector2Array()
	var masonry_uvs := PackedVector2Array()
	for column in range(first_column, last_column + 1):
		var x: float = float(column) * 35.0
		var y: float = height_at(x) + WALL_TOP + 6.0
		masonry.append(Vector2(x, y))
		masonry_uvs.append(Vector2(x / brick_size.x, y / brick_size.y))
	for column in range(last_column, first_column - 1, -1):
		var x: float = float(column) * 35.0
		var y: float = height_at(x) + WALL_BOTTOM
		masonry.append(Vector2(x, y))
		masonry_uvs.append(Vector2(x / brick_size.x, y / brick_size.y))
	draw_colored_polygon(masonry, Color.WHITE, masonry_uvs, AMSTERDAM_BRICK_TILE)
	# Stone coping directly below the asphalt gives the road a legible edge.
	var cap := PackedVector2Array()
	var cap_joints := PackedVector2Array()
	for column in range(first_column, last_column + 1):
		var x: float = float(column) * 35.0
		cap.append(Vector2(x, height_at(x) + WALL_TOP))
	for column in range(last_column, first_column - 1, -1):
		var x: float = float(column) * 35.0
		cap.append(Vector2(x, height_at(x) + WALL_TOP + 12.0))
	draw_colored_polygon(cap, Color8(133, 126, 104))
	var cap_edge := PackedVector2Array()
	for column in range(first_column, last_column + 1):
		var x: float = float(column) * 35.0
		var y: float = height_at(x) + WALL_TOP
		cap_edge.append(Vector2(x, y))
		cap_joints.append(Vector2(x, y + 1.0))
		cap_joints.append(Vector2(x, y + 11.0))
	draw_polyline(cap_edge, Color8(196, 178, 141, 210), 1.2, true)
	draw_multiline(cap_joints, Color8(62, 59, 51), 1.0, true)
	# Narrow drains and hanging ivy punctuate the wall and keep the masonry from
	# reading as a repeated flat strip; these are decorative wall details only.
	var detail_index: int = int(floor(visible_left / 280.0)) - 1
	var detail_x: float = float(detail_index) * 280.0 + 135.0
	while detail_x < visible_right:
		var drain_y: float = height_at(detail_x) + 217.0
		draw_rect(Rect2(detail_x - 12.0, drain_y, 24.0, 47.0), Color8(39, 43, 39))
		draw_rect(Rect2(detail_x - 8.0, drain_y + 3.0, 16.0, 41.0), Color8(27, 51, 51))
		for bar_index in range(4):
			var bar_x: float = detail_x - 6.0 + float(bar_index) * 4.0
			draw_line(Vector2(bar_x, drain_y + 5.0), Vector2(bar_x, drain_y + 42.0), Color8(145, 135, 108), 1.2, true)
		var vine_x: float = detail_x + 43.0
		var vine_y: float = height_at(vine_x) + WALL_TOP + 3.0
		draw_line(Vector2(vine_x, vine_y), Vector2(vine_x - 5.0, vine_y + 69.0), Color8(53, 83, 54, 220), 2.0, true)
		for leaf_index in range(5):
			var leaf_y: float = vine_y + 12.0 + float(leaf_index) * 12.0
			draw_circle(Vector2(vine_x - 3.0, leaf_y), 3.0, Color8(91, 118, 61, 225))
		detail_x += 280.0
	draw_line(Vector2(visible_left, height_at(visible_left) + WALL_BOTTOM - 2.0), Vector2(visible_right, height_at(visible_right) + WALL_BOTTOM - 2.0), Color8(37, 41, 38), 3.0, true)

func _visible_world_x_bounds(padding: float = 0.0) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var local_from_screen: Transform2D = get_global_transform_with_canvas().affine_inverse()
	var corners: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(viewport_size.x, 0.0),
		viewport_size,
		Vector2(0.0, viewport_size.y)
	]
	var minimum_x: float = INF
	var maximum_x: float = -INF
	for corner in corners:
		var local_point: Vector2 = local_from_screen * corner
		minimum_x = minf(minimum_x, local_point.x)
		maximum_x = maxf(maximum_x, local_point.x)
	return Vector2(minimum_x - padding, maximum_x + padding)

func _draw_canal_bridge_masonry() -> void:
	const BRIDGE_START_M: float = 350.0
	const BRIDGE_END_M: float = 472.0
	const FACE_TOP_OFFSET: float = 38.0
	const FACE_BOTTOM_OFFSET: float = 218.0
	var camera := get_viewport().get_camera_2d()
	var left_x: float = BRIDGE_START_M * PIXELS_PER_METER
	var right_x: float = BRIDGE_END_M * PIXELS_PER_METER
	if camera != null:
		var half_width: float = get_viewport_rect().size.x / maxf(0.25, camera.zoom.x) * 0.72
		left_x = maxf(left_x, camera.global_position.x - half_width)
		right_x = minf(right_x, camera.global_position.x + half_width)
	if right_x <= left_x:
		return
	var wall := PackedVector2Array()
	var wall_top_edge := PackedVector2Array()
	var sample_count: int = maxi(2, int(ceil((right_x - left_x) / 54.0)))
	for sample_index in range(sample_count + 1):
		var x: float = lerpf(left_x, right_x, float(sample_index) / float(sample_count))
		var top_point := Vector2(x, _base_height_at(x) + FACE_TOP_OFFSET)
		wall.append(top_point)
		wall_top_edge.append(top_point)
	for sample_index in range(sample_count, -1, -1):
		var x: float = lerpf(left_x, right_x, float(sample_index) / float(sample_count))
		wall.append(Vector2(x, _base_height_at(x) + FACE_BOTTOM_OFFSET))
	draw_colored_polygon(wall, Color8(112, 62, 51, 255))
	draw_polyline(wall_top_edge, Color8(34, 39, 35), 3.0, true)
	# A continuous cap stone makes the road sit on the structure rather than
	# appearing as a separate picture strip.
	var cap := PackedVector2Array([
		Vector2(left_x, _base_height_at(left_x) + FACE_TOP_OFFSET),
		Vector2(right_x, _base_height_at(right_x) + FACE_TOP_OFFSET),
		Vector2(right_x, _base_height_at(right_x) + FACE_TOP_OFFSET + 14.0),
		Vector2(left_x, _base_height_at(left_x) + FACE_TOP_OFFSET + 14.0)
	])
	draw_colored_polygon(cap, Color8(143, 130, 106))
	draw_polyline(PackedVector2Array([cap[0], cap[1]]), Color8(201, 183, 145), 2.2, true)
	# A repeating, weathered masonry texture replaces per-brick draw calls while
	# preserving the same visible bridge face and collision profile.
	var bridge_brick_size: Vector2 = Vector2(294.0, 294.0)
	var bridge_masonry := PackedVector2Array()
	var bridge_masonry_uvs := PackedVector2Array()
	for sample_index in range(sample_count + 1):
		var x: float = lerpf(left_x, right_x, float(sample_index) / float(sample_count))
		var y: float = _base_height_at(x) + FACE_TOP_OFFSET + 16.0
		bridge_masonry.append(Vector2(x, y))
		bridge_masonry_uvs.append(Vector2(x / bridge_brick_size.x, y / bridge_brick_size.y))
	for sample_index in range(sample_count, -1, -1):
		var x: float = lerpf(left_x, right_x, float(sample_index) / float(sample_count))
		var y: float = _base_height_at(x) + FACE_BOTTOM_OFFSET
		bridge_masonry.append(Vector2(x, y))
		bridge_masonry_uvs.append(Vector2(x / bridge_brick_size.x, y / bridge_brick_size.y))
	draw_colored_polygon(bridge_masonry, Color.WHITE, bridge_masonry_uvs, AMSTERDAM_BRICK_TILE)
	# Deep, open canal arches are layered on top of the masonry; their tops stay
	# well below the road edge so they cannot be mistaken for obstacles.
	for arch_index in range(3):
		var center_x: float = lerpf(BRIDGE_START_M, BRIDGE_END_M, float(arch_index + 1) / 4.0) * PIXELS_PER_METER
		if center_x < left_x - 90.0 or center_x > right_x + 90.0:
			continue
		var arch_center_y: float = _base_height_at(center_x) + 151.0
		var arch_radius_x: float = 45.0
		var arch_radius_y: float = 48.0
		var arch_bottom: float = _base_height_at(center_x) + FACE_BOTTOM_OFFSET + 6.0
		var opening := PackedVector2Array([Vector2(center_x - arch_radius_x, arch_center_y)])
		for arc_step in range(17):
			var angle: float = PI + PI * float(arc_step) / 16.0
			opening.append(Vector2(center_x + cos(angle) * arch_radius_x, arch_center_y + sin(angle) * arch_radius_y))
		opening.append(Vector2(center_x + arch_radius_x, arch_bottom))
		opening.append(Vector2(center_x - arch_radius_x, arch_bottom))
		draw_colored_polygon(opening, Color8(31, 82, 89, 255))
		var arch_rim := PackedVector2Array()
		for arc_step in range(17):
			var angle: float = PI + PI * float(arc_step) / 16.0
			arch_rim.append(Vector2(center_x + cos(angle) * (arch_radius_x + 5.0), arch_center_y + sin(angle) * (arch_radius_y + 5.0)))
		draw_polyline(arch_rim, Color8(179, 157, 119), 6.0, true)
		draw_line(Vector2(center_x - arch_radius_x - 3.0, arch_center_y), Vector2(center_x - arch_radius_x - 3.0, arch_bottom), Color8(162, 139, 106), 6.0, true)
		draw_line(Vector2(center_x + arch_radius_x + 3.0, arch_center_y), Vector2(center_x + arch_radius_x + 3.0, arch_bottom), Color8(162, 139, 106), 6.0, true)
		draw_line(Vector2(center_x - 34.0, arch_bottom - 8.0), Vector2(center_x + 32.0, arch_bottom - 8.0), Color8(114, 161, 154, 160), 2.0, true)
	# Ivy and chipped mortar keep the bridge tied to the overgrown city artwork.
	var vine_origin: float = BRIDGE_START_M * PIXELS_PER_METER + 12.0
	var first_vine: int = maxi(0, ceili((left_x - vine_origin - 8.0) / 61.0))
	var last_vine: int = floori((right_x - vine_origin) / 61.0)
	for vine_index in range(first_vine, last_vine + 1):
		var vine_x: float = vine_origin + float(vine_index) * 61.0
		var vine_y: float = _base_height_at(vine_x) + 54.0
		draw_line(Vector2(vine_x, vine_y), Vector2(vine_x - 5.0, vine_y + 36.0), Color8(55, 84, 57, 230), 2.3, true)
		draw_circle(Vector2(vine_x - 3.0, vine_y + 12.0), 3.2, Color8(87, 116, 64))
		draw_circle(Vector2(vine_x - 7.0, vine_y + 27.0), 2.5, Color8(105, 126, 70))



func _draw_branch_coins() -> void:
	for coin_index in range(_upper_coin_meters.size()):
		if _upper_coins_collected.has(coin_index):
			continue
		var coin_x: float = _upper_coin_meters[coin_index] * PIXELS_PER_METER
		var coin_y: float = UPPER_BRIDGE_Y - 47.0
		draw_circle(Vector2(coin_x, coin_y), 12.0, Color8(115, 83, 40))
		draw_circle(Vector2(coin_x, coin_y), 8.5, Color8(237, 187, 87))
		draw_circle(Vector2(coin_x - 2.0, coin_y - 2.0), 2.1, Color8(255, 233, 171))

func _draw_encounter_object(world_x: float, ground: float, event: Dictionary) -> void:
	var prop: String = String(event.get("prop", ""))
	var broken: bool = bool(event.get("done", false))
	if prop in ["timber_barrier", "barrel_stack", "wood_crates", "brick_barrier", "fallen_bike", "fallen_lamp", "market_cart", "quay_rubble"]:
		_draw_atlas_obstacle(world_x, ground, prop, broken)
		return
	match prop:
		"harbor_timber_barrier":
			_draw_timber_barrier(world_x, ground, broken)
		"harbor_metal_gate":
			_draw_harbor_metal_gate(world_x, ground, broken)
		"supply_crate":
			_draw_supply_crate(world_x, ground, broken)
		"barrel_stack":
			_draw_barrel_stack(world_x, ground, broken)
		"tram_wreck":
			_draw_tram_wreck(world_x, ground, broken)
		"canal_cart":
			_draw_canal_cart(world_x, ground, broken)
		"scaffold":
			_draw_scaffold(world_x, ground, broken)
		"timber_barrier":
			_draw_timber_barrier(world_x, ground, broken)
		_:
			super._draw_encounter_object(world_x, ground, event)

func _draw_atlas_obstacle(world_x: float, ground: float, prop: String, broken: bool) -> void:
	var source: Rect2
	var destination: Rect2
	match prop:
		"fallen_bike":
			source = FALLEN_BIKE_ATLAS_REGION
			destination = Rect2(world_x - 104.0, ground - 116.0, 208.0, 116.0)
		"fallen_lamp":
			source = FALLEN_LAMP_ATLAS_REGION
			destination = Rect2(world_x - 116.0, ground - 130.0, 232.0, 130.0)
		"market_cart":
			source = MARKET_CART_ATLAS_REGION
			destination = Rect2(world_x - 112.0, ground - 142.0, 224.0, 142.0)
		"quay_rubble":
			source = QUAY_RUBBLE_ATLAS_REGION
			destination = Rect2(world_x - 118.0, ground - 120.0, 236.0, 120.0)
		"timber_barrier":
			source = BARRICADE_ATLAS_REGION
			destination = Rect2(world_x - 84.0, ground - 105.0, 168.0, 112.0)
		"wood_crates":
			source = CRATE_ATLAS_REGION
			destination = Rect2(world_x - 84.0, ground - 106.0, 168.0, 116.0)
		"barrel_stack":
			source = BARREL_ATLAS_REGION
			destination = Rect2(world_x - 85.0, ground - 112.0, 170.0, 128.0)
		_:
			source = BRICK_BARRIER_ATLAS_REGION
			destination = Rect2(world_x - 90.0, ground - 98.0, 180.0, 112.0)
	if not broken:
		var atlas: Texture2D = AMSTERDAM_OBSTACLE_ATLAS_058 if prop in ["fallen_bike", "fallen_lamp", "market_cart", "quay_rubble"] else AMSTERDAM_OBSTACLE_ATLAS
		# Contact rows are authored within each 512 px tile. The soft shadow
		# extends past the feet, so alpha bounds cannot locate the road contact.
		var foot_row: float = float(OBSTACLE_CONTACT_ROWS.get(prop, 448.0))
		destination.position.y = ground - foot_row / source.size.y * destination.size.y
		var contact := Vector2(world_x, ground)
		destination.position -= contact
		draw_set_transform(contact, slope_at(world_x))
		draw_texture_rect_region(atlas, destination, source)
		draw_set_transform(Vector2.ZERO)
		return
	match prop:
		"timber_barrier", "wood_crates", "market_cart":
			for fragment_index in range(5):
				var fragment_x: float = world_x - 54.0 + float(fragment_index) * 26.0
				var lift: float = 7.0 + float((fragment_index * 13) % 14)
				draw_line(Vector2(fragment_x, ground - 2.0), Vector2(fragment_x + 15.0, ground - lift), Color8(91, 63, 39), 7.0, true)
				draw_line(Vector2(fragment_x + 1.0, ground - 3.0), Vector2(fragment_x + 15.0, ground - lift), Color8(166, 115, 67, 230), 3.0, true)
		"fallen_bike":
			draw_circle(Vector2(world_x - 42.0, ground - 6.0), 16.0, Color8(37, 42, 39), false, 4.0, true)
			draw_circle(Vector2(world_x + 35.0, ground - 6.0), 14.0, Color8(37, 42, 39), false, 4.0, true)
			draw_line(Vector2(world_x - 42.0, ground - 6.0), Vector2(world_x - 3.0, ground - 36.0), Color8(123, 85, 55), 5.0, true)
			draw_line(Vector2(world_x - 3.0, ground - 36.0), Vector2(world_x + 35.0, ground - 6.0), Color8(123, 85, 55), 5.0, true)
		"fallen_lamp":
			for shard_index in range(4):
				var shard_x: float = world_x - 44.0 + float(shard_index) * 30.0
				draw_line(Vector2(shard_x, ground - 3.0), Vector2(shard_x + 23.0, ground - 9.0 - float(shard_index % 2) * 5.0), Color8(67, 67, 57), 6.0, true)
				draw_line(Vector2(shard_x + 2.0, ground - 5.0), Vector2(shard_x + 20.0, ground - 10.0), Color8(177, 151, 105, 225), 2.0, true)
		"quay_rubble", "brick_barrier":
			for rubble_index in range(7):
				var rubble_x: float = world_x - 61.0 + float(rubble_index) * 20.0
				var rubble_y: float = ground - 4.0 - float((rubble_index * 7) % 15)
				draw_colored_polygon(PackedVector2Array([
					Vector2(rubble_x, rubble_y), Vector2(rubble_x + 13.0, rubble_y - 4.0),
					Vector2(rubble_x + 19.0, ground - 2.0), Vector2(rubble_x + 4.0, ground)
				]), Color8(135, 74, 54, 230))
		"barrel_stack":
			for barrel_index in range(2):
				var barrel_x: float = world_x - 27.0 + float(barrel_index) * 48.0
				draw_set_transform(Vector2(barrel_x, ground - 8.0), 0.0, Vector2(1.8, 0.52))
				draw_circle(Vector2.ZERO, 12.0, Color8(89, 62, 42, 235))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_line(Vector2(barrel_x - 15.0, ground - 11.0), Vector2(barrel_x + 15.0, ground - 7.0), Color8(160, 99, 56, 230), 2.0, true)
		"brick_barrier":
			for rubble_index in range(6):
				var rubble_x: float = world_x - 58.0 + float(rubble_index) * 23.0
				var rubble_y: float = ground - float((rubble_index * 7) % 13)
				draw_colored_polygon(PackedVector2Array([
					Vector2(rubble_x, rubble_y), Vector2(rubble_x + 15.0, rubble_y - 3.0),
					Vector2(rubble_x + 20.0, ground - 2.0), Vector2(rubble_x + 5.0, ground)
				]), Color8(135, 74, 54, 230))
				draw_line(Vector2(rubble_x + 2.0, rubble_y + 2.0), Vector2(rubble_x + 15.0, ground - 3.0), Color8(188, 146, 104, 190), 1.4, true)

func _draw_timber_barrier(world_x:float,ground:float,broken:bool) -> void:
	# Use the same illustrated material as the other wooden barriers, while
	# retaining this harbor barrier's authored 66 px collision height.
	draw_set_transform(Vector2(world_x,ground),0,Vector2(1,66.0/76.0))
	_draw_atlas_obstacle(0,0,"timber_barrier",broken)
	draw_set_transform(Vector2.ZERO)

func spawn_timber_fragments(world_x:float,ground_y:float,speed_mps:float) -> void:
	super.spawn_timber_fragments(world_x,ground_y,speed_mps)
	for i in range(maxi(0,_impact_particles.size()-5),_impact_particles.size()):
		_impact_particles[i]["texture"]=VISUALS.TIMBER
		_impact_particles[i]["source"]=Rect2(60+i%4*95,100+i%3*70,90,22)

func _draw_supply_crate(world_x: float, ground: float, opened: bool) -> void:
	if opened:
		draw_rect(Rect2(world_x - 22.0, ground - 23.0, 44.0, 20.0), Color8(55, 60, 49))
		draw_rect(Rect2(world_x - 18.0, ground - 19.0, 36.0, 12.0), Color8(28, 36, 32))
		draw_colored_polygon(PackedVector2Array([
			Vector2(world_x - 24.0, ground - 25.0), Vector2(world_x - 9.0, ground - 42.0),
			Vector2(world_x + 15.0, ground - 39.0), Vector2(world_x + 22.0, ground - 24.0)
		]), Color8(131, 106, 63))
		return
	draw_rect(Rect2(world_x - 24.0, ground - 30.0, 48.0, 28.0), Color8(74, 83, 60))
	draw_rect(Rect2(world_x - 22.0, ground - 28.0, 44.0, 7.0), Color8(151, 124, 73))
	draw_line(Vector2(world_x - 23.0, ground - 15.0), Vector2(world_x + 23.0, ground - 15.0), Color8(48, 54, 43), 3.0, true)
	draw_rect(Rect2(world_x - 3.0, ground - 25.0, 6.0, 15.0), Color8(194, 83, 64))
	draw_rect(Rect2(world_x - 8.0, ground - 20.0, 16.0, 5.0), Color8(194, 83, 64))
	draw_line(Vector2(world_x - 18.0, ground - 29.0), Vector2(world_x - 18.0, ground - 5.0), Color8(184, 151, 89), 2.0, true)
	draw_line(Vector2(world_x + 18.0, ground - 29.0), Vector2(world_x + 18.0, ground - 5.0), Color8(184, 151, 89), 2.0, true)

func _draw_barrel_stack(world_x: float, ground: float, broken: bool) -> void:
	if broken:
		for offset in [-37.0, -6.0, 29.0]:
			draw_colored_polygon(PackedVector2Array([
				Vector2(world_x + offset - 15.0, ground - 4.0), Vector2(world_x + offset - 11.0, ground - 12.0),
				Vector2(world_x + offset + 10.0, ground - 8.0), Vector2(world_x + offset + 17.0, ground - 3.0)
			]), Color8(131, 77, 50, 220))
		return
	for index in range(3):
		var x: float = world_x + float(index - 1) * 27.0
		var y: float = ground - (23.0 if index == 1 else 19.0)
		draw_rect(Rect2(x - 10.0, y, 20.0, ground - y - 2.0), Color8(123, 66, 43))
		draw_circle(Vector2(x, y + 1.0), 9.0, Color8(189, 121, 68))
		draw_circle(Vector2(x, ground - 4.5), 9.0, Color8(75, 54, 42))
		draw_line(Vector2(x - 9.0, y + 7.0), Vector2(x + 9.0, y + 7.0), Color8(54, 53, 44), 2.0, true)

func _draw_tram_wreck(world_x: float, ground: float, broken: bool) -> void:
	if broken:
		draw_colored_polygon(PackedVector2Array([
			Vector2(world_x - 79.0, ground - 4.0), Vector2(world_x - 56.0, ground - 20.0),
			Vector2(world_x - 24.0, ground - 9.0), Vector2(world_x + 4.0, ground - 22.0),
			Vector2(world_x + 48.0, ground - 8.0), Vector2(world_x + 78.0, ground - 4.0)
		]), Color8(74, 83, 71, 230))
		draw_line(Vector2(world_x - 64.0, ground - 14.0), Vector2(world_x + 50.0, ground - 10.0), Color8(186, 130, 70), 4.0, true)
		return
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 82.0, ground - 4.0), Vector2(world_x - 74.0, ground - 48.0),
		Vector2(world_x - 51.0, ground - 67.0), Vector2(world_x + 57.0, ground - 67.0),
		Vector2(world_x + 78.0, ground - 48.0), Vector2(world_x + 84.0, ground - 6.0)
	]), Color8(87, 112, 92))
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 58.0, ground - 62.0), Vector2(world_x - 31.0, ground - 62.0),
		Vector2(world_x - 30.0, ground - 39.0), Vector2(world_x - 62.0, ground - 38.0)
	]), Color8(35, 57, 57))
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 23.0, ground - 62.0), Vector2(world_x + 5.0, ground - 62.0),
		Vector2(world_x + 8.0, ground - 39.0), Vector2(world_x - 24.0, ground - 39.0)
	]), Color8(35, 57, 57))
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x + 14.0, ground - 62.0), Vector2(world_x + 45.0, ground - 62.0),
		Vector2(world_x + 64.0, ground - 43.0), Vector2(world_x + 13.0, ground - 39.0)
	]), Color8(35, 57, 57))
	draw_line(Vector2(world_x - 69.0, ground - 34.0), Vector2(world_x + 70.0, ground - 34.0), Color8(224, 171, 95), 4.0, true)
	for wheel_x in [-51.0, 49.0]:
		draw_circle(Vector2(world_x + wheel_x, ground - 2.0), 11.0, Color8(31, 35, 33))
		draw_circle(Vector2(world_x + wheel_x, ground - 2.0), 4.0, Color8(178, 142, 83))
	draw_line(Vector2(world_x - 28.0, ground - 66.0), Vector2(world_x - 12.0, ground - 93.0), Color8(49, 61, 52), 3.0, true)
	draw_line(Vector2(world_x - 12.0, ground - 93.0), Vector2(world_x + 20.0, ground - 65.0), Color8(49, 61, 52), 3.0, true)

func _draw_canal_cart(world_x: float, ground: float, broken: bool) -> void:
	if broken:
		draw_line(Vector2(world_x - 41.0, ground - 4.0), Vector2(world_x + 46.0, ground - 5.0), Color8(121, 83, 50), 5.0, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(world_x - 29.0, ground - 4.0), Vector2(world_x - 20.0, ground - 23.0),
			Vector2(world_x + 5.0, ground - 12.0), Vector2(world_x + 25.0, ground - 21.0),
			Vector2(world_x + 39.0, ground - 4.0)
		]), Color8(105, 76, 48, 230))
		return
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 39.0, ground - 25.0), Vector2(world_x - 27.0, ground - 44.0),
		Vector2(world_x + 17.0, ground - 44.0), Vector2(world_x + 37.0, ground - 25.0),
		Vector2(world_x + 33.0, ground - 8.0), Vector2(world_x - 34.0, ground - 8.0)
	]), Color8(126, 83, 49))
	for crate_x in [-19.0, 5.0, 23.0]:
		draw_rect(Rect2(world_x + crate_x - 8.0, ground - 37.0, 17.0, 13.0), Color8(161, 117, 68))
		draw_line(Vector2(world_x + crate_x - 8.0, ground - 37.0), Vector2(world_x + crate_x + 8.0, ground - 24.0), Color8(71, 62, 45), 1.5, true)
	for wheel_x in [-25.0, 25.0]:
		draw_circle(Vector2(world_x + wheel_x, ground - 4.0), 7.0, Color8(37, 39, 34))
		draw_circle(Vector2(world_x + wheel_x, ground - 4.0), 2.2, Color8(184, 146, 85))

func _draw_scaffold(world_x: float, ground: float, broken: bool) -> void:
	if broken:
		draw_colored_polygon(PackedVector2Array([
			Vector2(world_x - 53.0, ground - 2.0), Vector2(world_x - 33.0, ground - 12.0),
			Vector2(world_x - 3.0, ground - 5.0), Vector2(world_x + 21.0, ground - 14.0),
			Vector2(world_x + 55.0, ground - 3.0)
		]), Color8(139, 98, 56, 225))
		return
	draw_line(Vector2(world_x - 50.0, ground - 4.0), Vector2(world_x - 40.0, ground - 55.0), Color8(79, 79, 63), 4.0, true)
	draw_line(Vector2(world_x + 47.0, ground - 4.0), Vector2(world_x + 37.0, ground - 55.0), Color8(79, 79, 63), 4.0, true)
	draw_line(Vector2(world_x - 43.0, ground - 49.0), Vector2(world_x + 41.0, ground - 53.0), Color8(193, 139, 75), 7.0, true)
	draw_line(Vector2(world_x - 46.0, ground - 25.0), Vector2(world_x + 45.0, ground - 22.0), Color8(126, 88, 53), 5.0, true)
	draw_line(Vector2(world_x - 50.0, ground - 51.0), Vector2(world_x + 42.0, ground - 5.0), Color8(81, 80, 62), 3.0, true)
	for plank_index in range(5):
		var plank_x: float = world_x - 38.0 + float(plank_index) * 18.0
		draw_line(Vector2(plank_x, ground - 52.0), Vector2(plank_x + 8.0, ground - 45.0), Color8(50, 57, 49), 2.0, true)

func _draw_canal_boat(world_x: float, water_y: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(world_x - 145.0, water_y), Vector2(world_x + 163.0, water_y),
		Vector2(world_x + 121.0, water_y + 33.0), Vector2(world_x - 108.0, water_y + 33.0)
	]), Color8(35, 48, 46, 220))
	draw_rect(Rect2(world_x - 72.0, water_y - 31.0, 132.0, 32.0), Color8(78, 83, 72, 210))
	draw_rect(Rect2(world_x - 42.0, water_y - 51.0, 76.0, 20.0), Color8(52, 67, 64, 225))
	draw_rect(Rect2(world_x - 22.0, water_y - 45.0, 28.0, 13.0), Color8(180, 132, 74, 130))
	draw_line(Vector2(world_x - 132.0, water_y + 10.0), Vector2(world_x + 147.0, water_y + 10.0), Color8(152, 115, 70, 190), 3.0, true)


func _draw_lock_bridge() -> void:
	var bounds: Vector2 = _visible_world_x_bounds(200.0)
	var lip: float = LOCK_LIP_M * PIXELS_PER_METER
	var wood_start: float = (LOCK_LIP_M - 14.0) * PIXELS_PER_METER
	var landing: float = LOCK_LANDING_M * PIXELS_PER_METER
	var right: float = LOCK_DECK_END_M * PIXELS_PER_METER
	if right < bounds.x or wood_start > bounds.y:
		return
	var base: float = lock_base_y()
	var deck: float = lock_surface_y(LOCK_LANDING_M)
	var water: float = lock_water_y()
	# Door width comes from the physical canal opening. Its Y scale is the
	# same as its X scale; only submerged pixels are cropped away.
	var used: Rect2 = _lock_gate_region()
	var gate_scale: float = (landing - lip + 24.0) / used.size.x
	var gate_top: float = deck + 45.0
	var visible_height: float = minf(used.size.y * gate_scale, water - gate_top)
	draw_texture_rect_region(LOCK_GATE_TEXTURE, Rect2(lip - 12.0, gate_top, used.size.x * gate_scale, visible_height), Rect2(used.position, Vector2(used.size.x, visible_height / gate_scale)))
	for line in range(7):
		var y: float = water + float(line) * 15.0
		for ripple in range(8):
			var x: float = lerpf(lip, landing, float(ripple) / 8.0) + sin(_elapsed_s * 1.8 + float(line)) * 7.0
			draw_line(Vector2(x, y), Vector2(x + 42.0, y), Color8(140, 171, 150, 60), 1.3, true)
	# Draw complete native-proportion pieces. The long approach is masonry;
	# only the final 14 m carries the wooden bridge leaf.
	_draw_lock_foundation_caps(wood_start, lip, landing, right, water)
	_draw_lock_rigid_piece(LOCK_RAMP_TEXTURE, Vector2(wood_start, lock_surface_y(LOCK_LIP_M - 14.0)), Vector2(lip, lock_surface_y(LOCK_LIP_M)), Vector2(125.0, 435.0), Vector2(2165.0, 240.0))
	_draw_lock_rigid_piece(LOCK_LANDING_TEXTURE, Vector2(landing, deck), Vector2(right, deck), Vector2(145.0, 330.0), Vector2(2110.0, 330.0))
	if _lock_water_entered and _lock_splash_time < 1.1:
		var t: float = _lock_splash_time
		for drop in range(18):
			var direction: float = float(drop - 9) / 9.0
			var pos := Vector2(_lock_splash_x + direction * t * 145.0, water - sin(t / 1.1 * PI) * (40.0 + float(drop % 4) * 14.0))
			draw_circle(pos, 2.0 + float(drop % 3), Color(0.66, 0.83, 0.79, 1.0 - t / 1.1))

func _lock_gate_region() -> Rect2:
	# Ignore the transparent outer canvas, including faint generator fringe.
	# These are the measured timber/frame bounds in the 1969 x 799 source.
	return Rect2(95.0, 12.0, 1780.0, 765.0)

func lock_piece_transform(start: Vector2, end: Vector2, source_a: Vector2, source_b: Vector2) -> Transform2D:
	var target: Vector2 = end - start
	var source: Vector2 = source_b - source_a
	var scale: float = target.length() / source.length()
	var angle: float = target.angle() - source.angle()
	var transform := Transform2D(angle, Vector2.ONE * scale, 0.0, Vector2.ZERO)
	transform.origin = start - transform * source_a
	return transform

func _draw_lock_rigid_piece(texture: Texture2D, start: Vector2, end: Vector2, source_a: Vector2, source_b: Vector2) -> void:
	draw_set_transform_matrix(lock_piece_transform(start, end, source_a, source_b))
	draw_texture(texture, Vector2.ZERO)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_lock_foundation_caps(wood_start: float, lip: float, landing: float, right: float, water: float) -> void:
	# Wood feet sit on the coping; masonry no longer fills the timber bays.
	for bank in [Vector2(wood_start, lip), Vector2(landing, right)]:
		var offset: float = 71.0 if bank.x == wood_start else 94.0
		var x: float = bank.x
		while x < bank.y - 0.01:
			var end_x: float = minf(x + 52.0, bank.y)
			var y_a: float = height_at(x) + offset
			var y_b: float = height_at(end_x) + offset
			_draw_lock_stone(Rect2(x - 1.0, minf(y_a, y_b), end_x - x + 2.0, 13.0), int(x / 52.0))
			x = end_x
	_draw_lock_corner(lip, lock_surface_y(LOCK_LIP_M) + 71.0, water + 12.0, -1.0)
	_draw_lock_corner(landing, lock_surface_y(LOCK_LANDING_M) + 94.0, water + 12.0, 1.0)

func _draw_lock_corner(edge: float, top: float, bottom: float, bank_direction: float) -> void:
	var width: float = 66.0
	var left: float = edge - width if bank_direction < 0.0 else edge
	var row: int = 0
	var y: float = top + 12.0
	while y < bottom:
		var h: float = minf(35.0, bottom - y)
		var stagger: float = 5.0 if row % 2 == 0 else 0.0
		_draw_lock_stone(Rect2(left - stagger * (1.0 if bank_direction < 0.0 else 0.0), y, width + stagger, h), row + (3 if bank_direction > 0.0 else 0))
		y += h
		row += 1
	# A shallow side face and worn quoin joints give the wall an actual end.
	var face_x: float = edge - 7.0 if bank_direction < 0.0 else edge
	draw_rect(Rect2(face_x, top + 12.0, 7.0, bottom - top - 12.0), Color8(43, 42, 35, 105))
	draw_line(Vector2(edge, top + 12.0), Vector2(edge, bottom), Color8(39, 37, 31), 2.0, true)
	_draw_lock_stone(Rect2(left - 7.0, top, width + 14.0, 14.0), 7)
	for leaf in range(14):
		var leaf_y: float = bottom - 46.0 + float(leaf % 7) * 6.0
		var leaf_x: float = left + 8.0 + float((leaf * 17) % 49)
		draw_circle(Vector2(leaf_x, leaf_y), 2.0 + float(leaf % 3), Color8(79, 91, 42, 150))
	# Small iron hinge fittings tie the gate to its stone jamb.
	var gate_top: float = lock_surface_y(LOCK_LANDING_M) + 45.0
	for hinge in range(2):
		var hinge_y: float = gate_top + 120.0 + float(hinge) * 85.0
		if hinge_y > top + 22.0 and hinge_y < bottom - 20.0:
			var plate_x: float = edge - 18.0 if bank_direction < 0.0 else edge + 4.0
			draw_rect(Rect2(plate_x, hinge_y, 14.0, 24.0), Color8(50, 46, 37))
			draw_circle(Vector2(plate_x + 7.0, hinge_y + 5.0), 1.6, Color8(157, 122, 72))
			draw_circle(Vector2(plate_x + 7.0, hinge_y + 19.0), 1.6, Color8(157, 122, 72))

func _draw_lock_stone(rect: Rect2, seed: int) -> void:
	var quad := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var uv := PackedVector2Array()
	for point in quad:
		uv.append((point + Vector2(float(seed % 7) * 19.0, float(seed % 5) * 27.0)) / 294.0)
	draw_colored_polygon(quad, Color8(220, 211, 185), uv, AMSTERDAM_BRICK_TILE)
	draw_rect(rect, Color8(47, 44, 36), false, 1.5)
	draw_line(rect.position + Vector2(2.0, 2.0), Vector2(rect.end.x - 2.0, rect.position.y + 2.0), Color8(216, 198, 159, 190), 2.0, true)
	draw_line(Vector2(rect.position.x + 2.0, rect.end.y - 2.0), rect.end - Vector2(2.0, 2.0), Color8(65, 60, 47, 170), 2.0, true)

func _draw_quay_life_details() -> void:
	var bounds: Vector2 = _visible_world_x_bounds(100.0)
	var first: int = floori(bounds.x / (19.0 * PIXELS_PER_METER))
	var last: int = ceili(bounds.y / (19.0 * PIXELS_PER_METER))
	for index in range(first, last + 1):
		var meter: float = float(index) * 19.0 + 12.0
		if meter < 15.0 or meter > AMSTERDAM_LENGTH_M:
			continue
		if (meter > BARGE_START_M and meter < BARGE_END_M) or (meter > LOCK_START_M and meter < LOCK_REJOIN_M):
			continue
		var x: float = meter * PIXELS_PER_METER
		var ground: float = _base_height_at(x)
		var kind: int = posmod(index * 7, 5)
		if kind == 0:
			_draw_quay_detail(0, Vector2(x, ground + 61.0), Vector2(0.5, 0.5))
		elif kind in [1, 3]:
			_draw_quay_detail(1, Vector2(x, ground + 33.0), Vector2(0.5, 0.0), 0.85 if kind == 3 else 1.0)
		elif kind == 2:
			_draw_quay_detail(2, Vector2(x, ground + 35.0), Vector2(0.5, 0.0))
		else:
			var sign := Rect2(x - 19.0, ground + 43.0, 38.0, 18.0)
			draw_rect(sign.grow(1.5), Color8(40, 44, 40))
			draw_rect(sign, Color8(56, 75, 72))
			draw_string(ThemeDB.fallback_font, sign.position + Vector2(4.0, 12.0), "%04d" % int(meter), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color8(198, 190, 157))
		# Moss and runoff stop at the stone edge, below the driving surface.
		for streak in range(3):
			var sx: float = x + 18.0 + float(streak) * 4.0
			draw_line(Vector2(sx, ground + 29.0), Vector2(sx - 2.0, ground + 42.0 + float(streak) * 5.0), Color8(64, 80, 44, 70), 1.4, true)

func _draw_quay_detail(index: int, position: Vector2, anchor: Vector2, size_factor: float = 1.0) -> void:
	var source: Rect2 = VISUALS.detail_source(index)
	var width: float = VISUALS.DETAIL_WIDTHS[index] * size_factor
	var size := Vector2(width, width * source.size.y / source.size.x)
	draw_texture_rect_region(VISUALS.DETAILS, Rect2(position - size * anchor, size), source)



func debris_floor_at(world_x: float) -> float:
	if world_x >= LOCK_LIP_M * PIXELS_PER_METER and world_x < LOCK_LANDING_M * PIXELS_PER_METER:
		return lock_water_y()
	return height_at(world_x)

