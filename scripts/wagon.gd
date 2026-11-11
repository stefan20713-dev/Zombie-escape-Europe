extends RigidBody2D
class_name EscapeWagon

signal landed(impact_speed: float)
const ATTACHMENT_ART = preload("res://scripts/zombie_attachment_art.gd")
var _ground_surface: Node
var _zombie_pose_meshes: Array[ArrayMesh] = []
signal zombies_shaken(count: int)
var last_damage_local := Vector2(70, 12)

var _shake_brake_s := 0.0
var _shake_brake_start_speed := 0.0
var _shake_ready_s := 0.0
var _shake_cooldown_s := 0.0

const PIXELS_PER_METER: float = CAMPAIGN_DATA.PIXELS_PER_METER
const WHEEL_RADIUS: float = 18.0
const KOMBI_BODY_DRAW_WIDTH: float = 226.0
const KOMBI_REAR_TEAR_U := 0.115
const KOMBI_REAR_TEAR_TOP_V := 0.54
const KOMBI_ROOF_CRAWL_WIDTH := 86.0
const KOMBI_ROOF_REAR_X := -35.0
const KOMBI_ROOF_FRONT_X := -26.0
const KOMBI_BODY_WHEEL_ARCH_CENTER_V: float = 0.68
const KOMBI_ROOF_GRIP_Y: float = -23.0
const KOMBI_ROOF_SURFACE_Y: float = -23.0
const KOMBI_EXHAUST_MOUTH: Vector2 = Vector2(-114.0, 30.0)
const KOMBI_WEAPON_MUZZLE: Vector2 = Vector2(23.0, -27.0)
const REDRAW_INTERVAL_S: float = 1.0 / 30.0
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const ZOMBIE_DATA = preload("res://scripts/zombie_data.gd")
const KOMBI_BODY_TEXTURE: Texture2D = preload("res://assets/kombi_body_0.5.10.png")
const KOMBI_ARMOR_TIER1_TEXTURE: Texture2D = preload("res://assets/kombi_armor_tier1_0.5.50.png")
const KOMBI_ARMOR_TIER2_TEXTURE: Texture2D = preload("res://assets/kombi_armor_tier2_0.5.43.png")
const KOMBI_ARMOR_TIER3_TEXTURE: Texture2D = preload("res://assets/kombi_armor_tier3_0.5.43.png")
const KOMBI_WHEEL_STOCK_TEXTURE: Texture2D = preload("res://assets/kombi_wheel_stock_0.7.2.png")
const KOMBI_WHEEL_TEXTURE: Texture2D = preload("res://assets/kombi_wheel_0.6.0.png")
const KOMBI_WHEEL_TIER1_TEXTURE: Texture2D = preload("res://assets/kombi_wheel_tier1_0.7.0.png")
const KOMBI_WHEEL_TIER3_TEXTURE: Texture2D = preload("res://assets/kombi_wheel_tier3_0.7.0.png")
const KOMBI_NITRO_SINGLE_TEXTURE: Texture2D = preload("res://assets/kombi_nitro_single_0.5.50.png")
const KOMBI_NITRO_DUAL_TEXTURE: Texture2D = preload("res://assets/kombi_nitro_dual_0.5.50.png")
const KOMBI_HOOD_CANNON_TEXTURE: Texture2D = preload("res://assets/kombi_hood_cannon_0.9.0.png")
const DELIVERY_BODY_TEXTURE: Texture2D = preload("res://assets/delivery_van_body_0.5.11.png")
const OFFROAD_PICKUP_BODY_TEXTURE: Texture2D = preload("res://assets/offroad_pickup_body_0.5.12.png")

@onready var front_spring: RayCast2D = get_node("FrontSpring")
@onready var rear_spring: RayCast2D = get_node("RearSpring")
@onready var chassis_shape: CollisionShape2D = get_node("ChassisShape")

var vehicle_id: String = "kombi"
var speed_mps: float = 0.0
var fuel: float = 0.0
var fuel_capacity: float = 65.0
var nitro: float = 0.0
var nitro_capacity: float = 0.0
var durability: float = 100.0
var boost_active: bool = false
var _boost_coasting: bool = false
var airborne: bool = false
var overturned: bool = false
var _rear_torn_at_rollover := false
var roof_crash_time_s: float = -1.0:
	set(value):
		if value >= 0.0 and roof_crash_time_s < 0.0:
			_rear_torn_at_rollover = kombi_rear_torn()
		roof_crash_time_s = value
var zombie_fuel_penalty: float = 0.0
var engine_level: int = 0
var tire_level: int = 0
var tank_level: int = 0
var armor_level: int = 0
# Route-owned encounter tuning, neutral for all other scenes and vehicles.
var route_damage_factor: float = 1.0
var suspension_level: int = 0
var efficiency_level: int = 0
var brake_level: int = 0
var nitro_level: int = 0
var weapon_level: int = 0
var weapon_active: bool = false
var showcase_shadow: bool = false
var stock_test_mode: bool = false
var wheel_turn: float = 0.0
var _damage_visual_time: float = 0.0
var _body_damage_meshes: Dictionary = {}
var _engine_visual_time: float = 0.0
var _dust_visual_time: float = 0.0
var _throttle_visual: float = 0.0
var _dust_visual_strength: float = 0.0
var _impact_visual_remaining: float = 0.0
var _impact_visual_strength: float = 0.0
var _impact_visual_time: float = 0.0
var _weapon_shot_remaining: float = 0.0
var _weapon_shot_target_local: Vector2 = Vector2.ZERO
var wheel_radius: float = WHEEL_RADIUS
var rear_wheel_x: float = -48.0
var front_wheel_x: float = 51.0
var _redraw_elapsed: float = 0.0
var _engine_force: float = 0.0
var _boost_force: float = 0.0
var _max_speed_pixels_s: float = 0.0
var _obstacle_damage: float = 0.0
var _suspension_strength: float = 9500.0
var _suspension_damping: float = 1550.0
var _fuel_use_multiplier: float = 1.0
var _stock_fuel_use_multiplier: float = 1.45
var _stock_impact_damage_multiplier: float = 1.65
var _brake_force: float = 6200.0
var _grounded_torque: float = 360000.0
var _airborne_torque: float = 2800000.0
var _ramp_launch_grace_s: float = 0.0
var _upside_down_time_s: float = 0.0
var _zombie_stop_time_s: float = 0.0
var zombie_latches: Array[Dictionary] = []
var _released_zombies: Array[Dictionary] = []

func _ready() -> void:
	# Keep all three armor sprites at the same crisp downscaled quality. The
	# older tier 2/3 imports used mipmaps while tier 1 did not, which made the
	# purchased upgrades visibly softer at the same on-screen size.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var damage_details = preload("res://scripts/vehicle_damage_details.gd").new()
	damage_details.name = "DamageDetails"
	add_child(damage_details)
	var shared_chassis: RectangleShape2D = chassis_shape.shape as RectangleShape2D
	if shared_chassis != null:
		chassis_shape.shape = shared_chassis.duplicate() as RectangleShape2D

func configure(levels: Dictionary, chosen_vehicle: String = "kombi") -> void:
	vehicle_id = chosen_vehicle if CAMPAIGN_DATA.VEHICLES.has(chosen_vehicle) else "kombi"
	var vehicle: Dictionary = CAMPAIGN_DATA.VEHICLES[vehicle_id]
	engine_level = int(levels.get("engine", 0))
	tire_level = int(levels.get("tires", 0))
	tank_level = int(levels.get("tank", 0))
	armor_level = int(levels.get("armor", 0))
	suspension_level = int(levels.get("suspension", 0))
	efficiency_level = int(levels.get("efficiency", 0))
	brake_level = int(levels.get("brakes", 0))
	nitro_level = int(levels.get("nitro", 0))
	weapon_level = int(levels.get("weapon", 0)) if vehicle_id == "kombi" else 0
	# Vehicle and upgrade tuning is stable until the garage reconfigures the car.
	# Resolve the String-keyed campaign data here instead of doing dictionary
	# lookups and level arithmetic in every physics tick and suspension ray.
	_engine_force = float(vehicle["base_engine_force"]) + float(engine_level) * float(vehicle["engine_force_per_level"])
	_boost_force = float(vehicle["boost_force"]) * (1.0 + float(nitro_level) * 0.08)
	_max_speed_pixels_s = (float(vehicle["base_speed_mps"]) + float(engine_level) * float(vehicle["speed_per_level_mps"])) * PIXELS_PER_METER
	_obstacle_damage = float(vehicle["obstacle_damage"])
	_suspension_strength = float(vehicle.get("suspension_strength", 9500.0)) + float(tire_level) * 900.0 + float(suspension_level) * 1200.0
	_suspension_damping = float(vehicle.get("suspension_damping", 1550.0)) + float(tire_level) * 100.0 + float(suspension_level) * 220.0
	_fuel_use_multiplier = maxf(0.70, 1.0 - float(efficiency_level) * 0.08)
	_brake_force = (6200.0 + float(brake_level) * 930.0) * (PIXELS_PER_METER / CAMPAIGN_DATA.LEGACY_PIXEL_SCALE)
	_grounded_torque = float(vehicle.get("grounded_torque", 360000.0))
	_airborne_torque = float(vehicle.get("airborne_torque", 2800000.0))
	mass = float(vehicle["mass"])
	wheel_radius = float(vehicle.get("wheel_radius", WHEEL_RADIUS))
	rear_wheel_x = float(vehicle.get("rear_wheel_x", -48.0))
	front_wheel_x = float(vehicle.get("front_wheel_x", 51.0))
	if vehicle_id == "kombi":
		# The longer, aspect-correct Kombi body has a wider wheelbase at every armor tier.
		# Armor and general tuning cannot move the wheels; tire upgrades affect
		# their size and tread only. Move the front wheel slightly forward within
		# the stock fender opening to center it visually.
		rear_wheel_x = -65.0
		front_wheel_x = 70.0
	rear_spring.position.x = rear_wheel_x
	front_spring.position.x = front_wheel_x
	var chassis: RectangleShape2D = chassis_shape.shape as RectangleShape2D
	if chassis != null:
		var chassis_size: Vector2 = chassis.size
		chassis_size.x = 184.0 if vehicle_id in ["offroad_pickup", "kombi"] else 162.0
		chassis.size = chassis_size
	fuel_capacity = float(vehicle["base_fuel"]) + float(tank_level) * float(vehicle["fuel_per_tank_level"])
	fuel = fuel_capacity
	durability = 100.0
	nitro_capacity = 100.0 + float(nitro_level) * 20.0 if nitro_level > 0 else 0.0
	nitro = nitro_capacity
	boost_active = false
	_boost_coasting = false
	overturned = false
	roof_crash_time_s = -1.0
	_upside_down_time_s = 0.0
	_zombie_stop_time_s = 0.0
	zombie_latches.clear()
	_shake_brake_s = 0.0
	_shake_ready_s = 0.0
	_shake_cooldown_s = 0.0
	_released_zombies.clear()
	zombie_fuel_penalty = 0.0
	_damage_visual_time = 0.0
	_reset_vehicle_feedback()
	_ramp_launch_grace_s = 0.0
	queue_redraw()

func set_stock_test_mode(enabled: bool) -> void:
	stock_test_mode = enabled

func set_weapon_active(enabled: bool) -> void:
	weapon_active = enabled and vehicle_id == "kombi"
	queue_redraw()

func show_weapon_shot(target_world_position: Vector2) -> void:
	if not weapon_active or weapon_level <= 0:
		return
	_weapon_shot_target_local = to_local(target_world_position)
	_weapon_shot_remaining = 0.11
	queue_redraw()

func reset_at(world_x: float, terrain: Node) -> void:
	_ground_surface = terrain
	freeze = true
	global_position = Vector2(world_x, terrain.height_at(world_x) - wheel_ground_clearance())
	global_rotation = terrain.slope_at(world_x) * 0.45
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	airborne = false
	overturned = false
	roof_crash_time_s = -1.0
	_upside_down_time_s = 0.0
	_zombie_stop_time_s = 0.0
	zombie_latches.clear()
	_shake_brake_s = 0.0
	_shake_ready_s = 0.0
	_shake_cooldown_s = 0.0
	_released_zombies.clear()
	zombie_fuel_penalty = 0.0
	fuel = fuel_capacity
	durability = 100.0
	nitro = nitro_capacity
	boost_active = false
	_boost_coasting = false
	_damage_visual_time = 0.0
	_reset_vehicle_feedback()
	_ramp_launch_grace_s = 0.0
	speed_mps = 0.0
	wheel_turn = 0.0
	sleeping = false
	queue_redraw()

func front_contact_offset_px() -> float:
	match vehicle_id:
		"kombi":
			return 115.0
		"offroad_pickup":
			return 95.0
		_:
			return 89.0

func front_contact_offset_m() -> float:
	return front_contact_offset_px() / PIXELS_PER_METER

func simulate(delta: float, accelerate: bool, brake: bool, boost: bool, balance: float, road_angle: float = 0.0, road_height: float = -1.0, route_fuel_factor: float = 1.0) -> void:
	var zombie_stopped: bool = _zombie_stop_time_s > 0.0
	if zombie_stopped:
		_zombie_stop_time_s = maxf(0.0, _zombie_stop_time_s - delta)
	var boost_requested: bool = boost and nitro_level > 0 and nitro > 0.0 and fuel > 0.0 and durability > 0.0 and not zombie_stopped
	# Preserve real momentum when a boost ends instead of snapping to the motor cap.
	_boost_coasting = (boost_active or _boost_coasting) and not boost_requested and linear_velocity.x > _max_speed_pixels_s
	var forward: Vector2 = Vector2.RIGHT.rotated(global_rotation)
	var uphill_grip: float = 1.0 + float(tire_level) * 0.07 * clampf(-forward.y, 0.0, 0.8)
	if accelerate and fuel > 0.0 and durability > 0.0 and not zombie_stopped and not _boost_coasting:
		var drive_force: Vector2 = forward * _engine_force * uphill_grip * engine_condition_factor()
		if rear_spring.is_colliding():
			# Keep rear-drive weight transfer subtle. Applying full engine force at
			# the wheel contact turns the long pixel-space lever arm into a hard
			# nose flip, especially when the rear wheel has just left a hill.
			var rear_contact_offset: Vector2 = rear_spring.get_collision_point() - global_position
			apply_force(drive_force, rear_contact_offset * 0.08)
		else:
			# Airborne throttle adds forward speed; pitch stays under the balance
			# controls so the engine alone cannot spin the wagon into a full roll.
			apply_central_force(drive_force)
	if brake and absf(linear_velocity.x) > 1.0:
		apply_central_force(Vector2(-signf(linear_velocity.x) * _brake_force, 0.0))
	var engine_disabled: bool = fuel <= 0.0 or durability <= 0.0
	if engine_disabled:
		# Empty or wrecked cars coast down over several seconds; they no longer
		# receive engine thrust, but the run is not cut off while still moving.
		linear_velocity.x = move_toward(linear_velocity.x, 0.0, 4.5 * PIXELS_PER_METER * delta)
	else:
		apply_central_force(Vector2(-linear_velocity.x * 12.0, 0.0))
	boost_active = boost_requested
	if boost_active:
		apply_central_force(forward * _boost_force)
		nitro = maxf(0.0, nitro - (20.0 if vehicle_id == "kombi" else 34.0) * delta)
	elif not boost and nitro_level > 0:
		nitro = minf(nitro_capacity, nitro + (4.0 + float(nitro_level) * 0.5) * delta)
	_update_shake_maneuver(delta, accelerate, brake, boost_active)
	update_zombie_latches(delta)
	if zombie_stopped:
		linear_velocity.x = 0.0
	var was_airborne: bool = airborne
	_ramp_launch_grace_s = maxf(0.0, _ramp_launch_grace_s - delta)
	airborne = _ramp_launch_grace_s > 0.0 or (not front_spring.is_colliding() and not rear_spring.is_colliding())
	if was_airborne and not airborne:
		var landing_ray: RayCast2D = rear_spring if rear_spring.is_colliding() else front_spring
		var impact_speed: float = maxf(0.0, -linear_velocity.dot(landing_ray.get_collision_normal().normalized()))
		landed.emit(impact_speed)
	if _ramp_launch_grace_s <= 0.0:
		_apply_suspension(front_spring)
		_apply_suspension(rear_spring)
	var one_wheel_contact: bool = front_spring.is_colliding() != rear_spring.is_colliding()
	var airborne_or_unstable: bool = airborne or one_wheel_contact
	var tilt_error: float = wrapf(global_rotation - road_angle, -PI, PI)
	var roof_landed: bool = false
	if road_height >= 0.0 and absf(tilt_error) >= 2.38:
		var chassis_rect: RectangleShape2D = chassis_shape.shape as RectangleShape2D
		if chassis_rect != null:
			var half_width: float = chassis_rect.size.x * 0.5
			var half_height: float = chassis_rect.size.y * 0.5
			var body_bottom_y: float = global_position.y + chassis_shape.position.rotated(global_rotation).y
			body_bottom_y += absf(cos(global_rotation)) * half_height + absf(sin(global_rotation)) * half_width
			var road_gap: float = road_height - body_bottom_y
			roof_landed = road_gap >= -35.0 and road_gap <= 22.0
	if airborne_or_unstable:
		if balance != 0.0:
			var air_control_torque: float = balance * _airborne_torque
			var correcting_direction: float = -signf(tilt_error)
			if absf(tilt_error) > 0.25 and signf(balance) == correcting_direction:
				air_control_torque *= 1.35
			apply_torque(air_control_torque)
		elif not roof_landed:
			# A launch can pitch the Kombi close to vertical. Continue a controlled
			# recovery torque through the full airborne range instead of disabling it
			# at 85 degrees; a stable roof landing still counts as a failed run.
			var righting_torque: float = -tilt_error * 1750000.0 - angular_velocity * 420000.0
			apply_torque(clampf(righting_torque, -2200000.0, 2200000.0))
	elif balance != 0.0:
		apply_torque(balance * _grounded_torque)
	else:
		# Suspension impacts can leave one wheel touching while the car balances
		# on a steep angle. Add a light self-settling force without steering for
		# the player; keep it disabled when the roof has actually landed.
		if not roof_landed and absf(tilt_error) > 0.22:
			var settle_torque: float = -tilt_error * 620000.0 - angular_velocity * 210000.0
			apply_torque(clampf(settle_torque, -1050000.0, 1050000.0))
	fuel = maxf(0.0, fuel - delta * fuel_consumption_rate(accelerate, boost_active) * route_fuel_factor)
	var speed_limit_px_s: float = _max_speed_pixels_s
	if boost_active or _boost_coasting:
		# Boost opens a real extra speed band; it is not only a flame and screen effect.
		speed_limit_px_s *= 1.32 if vehicle_id == "kombi" else 1.18
	if vehicle_id == "kombi":
		# The fully tuned Kombi remains quick, while the boost band has a firm
		# 160 km/h ceiling so speed stays controllable on the short hill course.
		speed_limit_px_s = minf(speed_limit_px_s, (160.0 / 3.6) * PIXELS_PER_METER)
	if absf(linear_velocity.x) > speed_limit_px_s:
		linear_velocity.x = signf(linear_velocity.x) * speed_limit_px_s
	speed_mps = linear_velocity.x / PIXELS_PER_METER
	# The wheel artwork is authored at the same 36 px/m world scale as the physics.
	wheel_turn += linear_velocity.x * delta / maxf(1.0, wheel_radius)
	if durability > 0.0 and durability < 25.0:
		_damage_visual_time += delta
	_update_vehicle_feedback(delta, accelerate)
	_redraw_elapsed += delta
	if _redraw_elapsed >= REDRAW_INTERVAL_S:
		_redraw_elapsed = 0.0
		queue_redraw()

func _process(delta: float) -> void:
	if durability <= 0.0 or roof_crash_time_s >= 0.0:
		_damage_visual_time += delta
		queue_redraw()

func _apply_suspension(ray: RayCast2D) -> void:
	if not ray.is_colliding():
		return
	var hit_point: Vector2 = ray.get_collision_point()
	var normal: Vector2 = ray.get_collision_normal().normalized()
	var distance: float = ray.global_position.distance_to(hit_point)
	var compression: float = suspension_rest_length() - distance
	if compression <= 0.0:
		return
	var speed_along_normal: float = linear_velocity.dot(normal)
	var support: float = maxf(0.0, compression * _suspension_strength - speed_along_normal * _suspension_damping)
	apply_force(normal * support, hit_point - global_position)

func _update_vehicle_feedback(delta: float, accelerate: bool) -> void:
	_engine_visual_time += delta
	var throttle_target: float = 1.0 if accelerate and fuel > 0.0 else 0.0
	var throttle_rate: float = 4.5 if throttle_target > _throttle_visual else 2.4
	_throttle_visual = move_toward(_throttle_visual, throttle_target, delta * throttle_rate)
	var dust_target: float = 1.0 if not airborne and accelerate and absf(linear_velocity.x) > 180.0 and fuel > 0.0 else 0.0
	var dust_rate: float = 3.5 if dust_target > _dust_visual_strength else 1.5
	_dust_visual_strength = move_toward(_dust_visual_strength, dust_target, delta * dust_rate)
	_dust_visual_time += delta * clampf(absf(linear_velocity.x) / 140.0, 0.2, 1.2)
	if _impact_visual_remaining > 0.0:
		_impact_visual_remaining = maxf(0.0, _impact_visual_remaining - delta)
		_impact_visual_time += delta
		if _impact_visual_remaining <= 0.0:
			_impact_visual_strength = 0.0
	if _weapon_shot_remaining > 0.0:
		_weapon_shot_remaining = maxf(0.0, _weapon_shot_remaining - delta)

func _reset_vehicle_feedback() -> void:
	_engine_visual_time = 0.0
	_dust_visual_time = 0.0
	_throttle_visual = 0.0
	_dust_visual_strength = 0.0
	_impact_visual_remaining = 0.0
	_impact_visual_strength = 0.0
	_impact_visual_time = 0.0

func _trigger_impact_feedback(intensity: float) -> void:
	var clamped_intensity: float = clampf(intensity, 0.0, 1.0)
	_impact_visual_remaining = maxf(_impact_visual_remaining, 0.14 + clamped_intensity * 0.11)
	_impact_visual_strength = maxf(_impact_visual_strength, clamped_intensity)
	queue_redraw()

func fuel_consumption_rate(accelerate: bool, boosting: bool) -> float:
	var base_rate: float = 0.72 + (0.40 if accelerate else 0.0) + absf(linear_velocity.x / PIXELS_PER_METER) * 0.021 + (0.65 if boosting else 0.0)
	return (base_rate + zombie_fuel_penalty) * _fuel_use_multiplier * (_stock_fuel_use_multiplier if stock_test_mode else 1.0)

func hit_zombie(damage: float = 0.0, speed_retention: float = 0.76, stop_duration_s: float = 0.0, confirmed_spatial_overlap: bool = false) -> void:
	if airborne and not confirmed_spatial_overlap:
		return
	linear_velocity.x *= clampf(speed_retention, 0.0, 1.0)
	if stop_duration_s > 0.0:
		_zombie_stop_time_s = maxf(_zombie_stop_time_s, stop_duration_s)
		linear_velocity.x = 0.0
	var impact_damage: float = damage * armor_damage_multiplier()
	if stock_test_mode:
		impact_damage *= _stock_impact_damage_multiplier
	durability = maxf(0.0, durability - impact_damage)
	_trigger_impact_feedback(0.42)
	queue_redraw()

func add_zombie_latch(duration_s: float, drag_mps2: float, anchor_index: int, variant: int, damage_per_second: float = 0.0, grip_style: int = 0) -> bool:
	if duration_s <= 0.0 or drag_mps2 <= 0.0 or zombie_latches.size() >= (2 if vehicle_id == "kombi" else 3):
		return false
	if vehicle_id != "kombi":
		grip_style = 0
	var roof_busy := vehicle_id == "kombi" and _roof_crawl_occupied()
	if roof_busy:
		grip_style = 1
	var other_vehicle_anchors := [-70.0, -10.0, 45.0]
	var anchor_x: float = KOMBI_ROOF_REAR_X if vehicle_id == "kombi" else other_vehicle_anchors[posmod(anchor_index, other_vehicle_anchors.size())]
	zombie_latches.append({
		"time_left": duration_s,
		"duration": duration_s,
		"drag_mps2": drag_mps2,
		"damage_per_second": maxf(0.0, damage_per_second),
		"fuel_per_second": 0.20 + maxf(damage_per_second, drag_mps2 * 0.5) * 0.16,
		"anchor": Vector2(anchor_x, KOMBI_ROOF_SURFACE_Y if vehicle_id == "kombi" else -42.0),
		"variant": clampi(variant, 1, 5),
		"wind": 0.0,
		"age": 0.0,
		"crawl_distance": 0.0,
		"facing": 1.0,
		"phase": float(anchor_index) * 1.7,
		"strength": clampf(drag_mps2 / 2.5, 0.25, 1.0)
	})
	var latch: Dictionary = zombie_latches[-1]
	latch["mount"] = "side" if grip_style > 0 else "roof"
	latch["slipping"] = 0.0
	latch["roll_strain"] = 0.0
	if grip_style > 0:
		latch["anchor"] = Vector2(-57.0 if grip_style == 1 else 10.0, KOMBI_ROOF_GRIP_Y + 1.0)
	_trigger_impact_feedback(0.56)
	queue_redraw()
	return true

func update_zombie_latches(delta: float) -> void:
	zombie_fuel_penalty = 0.0
	_update_released_zombies(delta)
	if delta <= 0.0 or zombie_latches.is_empty():
		return
	var speed_kmh: float = absf(linear_velocity.x / PIXELS_PER_METER) * 3.6
	var total_drag_mps2: float = 0.0
	var total_damage_per_second: float = 0.0
	var total_fuel_per_second: float = 0.0
	# Wind pulls the zombies back progressively; they still deal drag and damage
	# while they struggle, then their grip timer finally runs out.
	var speed_pressure: float = clampf((speed_kmh - 30.0) / 130.0, 0.0, 1.0)
	# Fast wind makes the zombie stream backward, but should not instantly eject
	# it. Strong and weak grips remain distinguishable at high speed as well.
	var grip_timer_rate: float = lerpf(0.34, 0.72, pow(speed_pressure, 1.45))
	for latch_index in range(zombie_latches.size() - 1, -1, -1):
		var latch: Dictionary = zombie_latches[latch_index]
		var target_wind: float = signf(linear_velocity.x) * smoothstep(10.0, 135.0, speed_kmh)
		var wind: float = lerpf(float(latch.get("wind", 0.0)), target_wind, 1.0 - exp(-8.0 * delta))
		latch["wind"] = wind
		var age: float = float(latch.get("age", 0.0)) + delta
		latch["age"] = age
		var direction: float = float(latch.get("facing", 1.0))
		var anchor: Vector2 = latch["anchor"]
		var climb_speed: float = lerpf(13.0, 7.0, absf(wind))
		var advance: float = 0.0
		if String(latch.get("mount", "roof")) == "side":
			var pull_start: float = 1.1 + float(latch.get("strength", 0.5)) * 0.8
			if age > pull_start and not _roof_crawl_occupied():
				latch["mount"] = "climbing"
				latch["climb_origin"] = anchor
				latch["climb_started"] = age
		elif String(latch.get("mount", "roof")) == "climbing":
			var pull: float = clampf((age - float(latch["climb_started"])) / 0.7, 0.0, 1.0)
			latch["pull"] = pull
			var grip_x: float = clampf(Vector2(latch["climb_origin"]).x, -62.0, 18.0)
			anchor = Vector2(latch["climb_origin"]).lerp(Vector2(grip_x, KOMBI_ROOF_GRIP_Y), smoothstep(0.0, 1.0, pull))
			if pull >= 1.0:
				latch["mount"] = "roof"
				anchor.x = _roof_crawl_entry_x(anchor.x)
		if age > 0.35 and String(latch.get("mount", "roof")) == "roof":
			var target_x: float = (KOMBI_ROOF_FRONT_X if vehicle_id == "kombi" else 34.0) if direction > 0.0 else (KOMBI_ROOF_REAR_X if vehicle_id == "kombi" else -75.0)
			for other_index in range(zombie_latches.size()):
				if other_index == latch_index:
					continue
				var other: Dictionary = zombie_latches[other_index]
				if other.get("mount") != "roof":
					continue
				var other_x: float = Vector2(other["anchor"]).x
				if direction * (other_x - anchor.x) > 1.0:
					target_x = minf(target_x, other_x - 56.0) if direction > 0.0 else maxf(target_x, other_x + 56.0)
			target_x = maxf(target_x, anchor.x) if direction > 0.0 else minf(target_x, anchor.x)
			var next_x: float = move_toward(anchor.x, target_x, climb_speed * delta)
			advance = absf(next_x - anchor.x)
			anchor.x = next_x
		latch["anchor"] = anchor
		latch["crawl_distance"] = float(latch.get("crawl_distance", 0.0)) + advance
		latch["phase"] = float(latch.get("phase", 0.0)) + delta * (lerpf(2.5,7.5,absf(wind)) if String(latch.get("mount","roof")) == "roof" else lerpf(3.0,6.0,absf(wind)))
		var strength: float = clampf(float(latch.get("strength", 0.5)), 0.0, 1.0)
		var type_grip: float = lerpf(1.0, 0.72, strength)
		var remaining: float = maxf(0.0, float(latch.get("time_left", 0.0)) - delta * grip_timer_rate * type_grip)
		latch["time_left"] = remaining
		var angle: float = absf(wrapf(rotation,-PI,PI))
		var strain: float = float(latch.get("roll_strain",0.0))
		strain = strain + delta if angle > 1.0 or absf(angular_velocity) > 2.5 else maxf(0.0,strain-delta*2.0)
		latch["roll_strain"] = strain
		if remaining <= 0.0:
			latch["slipping"] = float(latch.get("slipping",0.0)) + delta
			if String(latch.get("mount", "roof")) != "roof":
				latch["anchor"] = Vector2(latch["anchor"]) + Vector2(-10.0 * delta, 4.0 * delta)
		var ripped_off: bool = age > 0.12 and (cos(rotation) < -0.15 or strain > lerpf(0.28,0.60,strength) or overturned)
		if ripped_off or float(latch.get("slipping",0.0)) >= 0.42:
			_release_latched_zombie(latch)
			zombie_latches.remove_at(latch_index)
			queue_redraw()
		else:
			total_drag_mps2 += float(latch.get("drag_mps2", 0.0))
			total_damage_per_second += float(latch.get("damage_per_second", 0.0)) * 1.75
			total_fuel_per_second += float(latch.get("fuel_per_second", 0.0))
	zombie_fuel_penalty = total_fuel_per_second
	if total_drag_mps2 > 0.0:
		linear_velocity.x = move_toward(linear_velocity.x, 0.0, total_drag_mps2 * PIXELS_PER_METER * delta)
		queue_redraw()
	if total_damage_per_second > 0.0:
		var damage_scale: float = armor_damage_multiplier() * (_stock_impact_damage_multiplier if stock_test_mode else 1.0)
		durability = maxf(0.0, durability - total_damage_per_second * damage_scale * delta)
		queue_redraw()

func hit_obstacle(confirmed_spatial_overlap: bool = false) -> void:
	hit_weighted_obstacle(1.0, confirmed_spatial_overlap)

func hit_weighted_obstacle(resistance: float, confirmed_spatial_overlap: bool = true) -> Dictionary:
	if airborne and not confirmed_spatial_overlap:
		return {}
	var safe_resistance: float = clampf(resistance, 0.05, 1.5)
	var speed_before_mps: float = absf(linear_velocity.x) / PIXELS_PER_METER
	var speed_fraction: float = clampf(speed_before_mps / 28.0, 0.0, 1.0)
	var tire_relief: float = minf(0.075, float(tire_level) * 0.025)
	var retention: float = clampf(1.0 - safe_resistance * lerpf(0.10, 0.30, speed_fraction) + tire_relief, 0.42, 0.99)
	linear_velocity.x *= retention
	# A collision kicks the nose up slightly; higher speed and heavier objects
	# produce a stronger, still recoverable jolt for the balance controls.
	angular_velocity = clampf(angular_velocity - (0.05 + safe_resistance * speed_fraction * 0.24), -2.1, 2.1)
	var speed_damage_scale: float = 0.08 + speed_fraction * 0.92
	var impact_damage: float = maxf(0.3, _obstacle_damage * 0.36 * safe_resistance * speed_damage_scale * armor_damage_multiplier())
	if stock_test_mode:
		impact_damage *= _stock_impact_damage_multiplier
	durability = maxf(0.0, durability - impact_damage)
	var speed_loss_kmh: float = maxf(0.0, (speed_before_mps - absf(linear_velocity.x) / PIXELS_PER_METER) * 3.6)
	_trigger_impact_feedback(clampf(0.22 + safe_resistance * 0.62 + speed_fraction * 0.16, 0.25, 1.0))
	queue_redraw()
	return {"speed_before_mps": speed_before_mps, "speed_loss_kmh": speed_loss_kmh, "damage": impact_damage, "retention": retention}

func hit_road_hazard(speed_retention: float, damage: float, confirmed_spatial_overlap: bool = false) -> void:
	if airborne and not confirmed_spatial_overlap:
		return
	var tire_retention: float = float(tire_level) * 0.025
	linear_velocity.x *= clampf(speed_retention + tire_retention, 0.5, 0.99)
	var speed_fraction: float = clampf(absf(linear_velocity.x) / maxf(1.0, _max_speed_pixels_s), 0.0, 1.0)
	angular_velocity = clampf(angular_velocity - 0.08 - speed_fraction * 0.20, -2.1, 2.1)
	var impact_damage: float = damage * armor_damage_multiplier()
	if stock_test_mode:
		impact_damage = maxf(2.0, impact_damage * _stock_impact_damage_multiplier)
	durability = maxf(0.0, durability - impact_damage)
	_trigger_impact_feedback(0.72)
	queue_redraw()

func armor_damage_multiplier() -> float:
	match clampi(armor_level, 0, 3):
		0:
			return 1.50 * route_damage_factor
		1:
			return 1.15 * route_damage_factor
		2:
			return 0.80 * route_damage_factor
		_:
			return 0.50 * route_damage_factor

func chassis_overlaps_world_rect(world_rect: Rect2) -> bool:
	var shape: RectangleShape2D = chassis_shape.shape as RectangleShape2D
	if shape == null or world_rect.size.x <= 0.0 or world_rect.size.y <= 0.0:
		return false
	var half_size: Vector2 = shape.size * chassis_shape.global_scale.abs() * 0.5
	var center: Vector2 = chassis_shape.global_position
	var axis_x: Vector2 = Vector2.RIGHT.rotated(chassis_shape.global_rotation)
	var axis_y: Vector2 = Vector2.DOWN.rotated(chassis_shape.global_rotation)
	var chassis_corners: Array[Vector2] = [
		center - axis_x * half_size.x - axis_y * half_size.y,
		center + axis_x * half_size.x - axis_y * half_size.y,
		center + axis_x * half_size.x + axis_y * half_size.y,
		center - axis_x * half_size.x + axis_y * half_size.y
	]
	var obstacle_corners: Array[Vector2] = [
		world_rect.position,
		Vector2(world_rect.end.x, world_rect.position.y),
		world_rect.end,
		Vector2(world_rect.position.x, world_rect.end.y)
	]
	var axes: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, axis_x, axis_y]
	for raw_axis in axes:
		var axis: Vector2 = raw_axis.normalized()
		var chassis_min: float = 1.0e20
		var chassis_max: float = -1.0e20
		var obstacle_min: float = 1.0e20
		var obstacle_max: float = -1.0e20
		for corner in chassis_corners:
			var projection: float = corner.dot(axis)
			chassis_min = minf(chassis_min, projection)
			chassis_max = maxf(chassis_max, projection)
		for corner in obstacle_corners:
			var projection: float = corner.dot(axis)
			obstacle_min = minf(obstacle_min, projection)
			obstacle_max = maxf(obstacle_max, projection)
		if chassis_max < obstacle_min or obstacle_max < chassis_min:
			return false
	return true

func launch_from_ramp(distance_to_hazard_m: float = 12.0, clearance_m: float = 0.65) -> void:
	if airborne:
		return
	var horizontal_speed: float = maxf(8.0 * PIXELS_PER_METER, absf(linear_velocity.x))
	var time_to_hazard: float = clampf(distance_to_hazard_m * PIXELS_PER_METER / horizontal_speed, 0.38, 1.35)
	var world_gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)) * gravity_scale
	# Keep authored Amsterdam kickers short and controlled.
	var safe_clearance_m: float = clampf(clearance_m, 0.35, 1.6)
	var clearance_px: float = safe_clearance_m * PIXELS_PER_METER
	var needed_takeoff_speed: float = (world_gravity * time_to_hazard * 0.5) + (clearance_px / time_to_hazard)
	var max_takeoff_speed: float = 235.0 if safe_clearance_m <= 0.7 else 380.0
	var takeoff_speed: float = clampf(needed_takeoff_speed, 90.0, max_takeoff_speed)
	linear_velocity.y = minf(linear_velocity.y, -takeoff_speed)
	_ramp_launch_grace_s = 0.12
	airborne = true
	sleeping = false

func launch_to_elevated_route(distance_to_route_m: float, route_height_px: float) -> void:
	var horizontal_speed: float = maxf(8.0 * PIXELS_PER_METER, absf(linear_velocity.x))
	var travel_time: float = clampf(maxf(1.0, distance_to_route_m) * PIXELS_PER_METER / horizontal_speed, 0.30, 1.35)
	var world_gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)) * gravity_scale
	var needed_upward_speed: float = (maxf(0.0, route_height_px) + world_gravity * travel_time * travel_time * 0.5) / travel_time
	# The entry is a real gap. Use the travel time and deck height to tune a
	# repeatable arc so fast runs land on the raised port deck instead of passing
	# through its edge; lower-speed runs stay on the road below.
	var route_launch_speed: float = clampf(needed_upward_speed, 360.0, 610.0)
	if not airborne or linear_velocity.y > -route_launch_speed * 0.72:
		linear_velocity.y = minf(linear_velocity.y, -route_launch_speed)
	_ramp_launch_grace_s = 0.10
	airborne = true
	sleeping = false

func update_overturn_state(delta: float, road_height: float, road_angle: float) -> void:
	# Count only a stable, near-ground roof landing. A brief inverted pose in
	# midair remains recoverable and does not consume the run.
	var relative_rotation: float = wrapf(global_rotation - road_angle, -PI, PI)
	var chassis_rect: RectangleShape2D = chassis_shape.shape as RectangleShape2D
	var roof_contact_near_ground: bool = false
	if chassis_rect != null:
		var half_width: float = chassis_rect.size.x * 0.5
		var half_height: float = chassis_rect.size.y * 0.5
		var body_bottom_y: float = global_position.y + chassis_shape.position.rotated(global_rotation).y
		body_bottom_y += absf(cos(global_rotation)) * half_height + absf(sin(global_rotation)) * half_width
		var road_gap: float = road_height - body_bottom_y
		roof_contact_near_ground = absf(relative_rotation) >= 2.38 and road_gap >= -35.0 and road_gap <= 22.0
	var roof_down_and_settled: bool = roof_contact_near_ground and absf(angular_velocity) < 2.8
	if roof_down_and_settled:
		_upside_down_time_s += delta
	else:
		_upside_down_time_s = maxf(0.0, _upside_down_time_s - delta * 2.0)
	overturned = _upside_down_time_s >= 0.55

func _draw() -> void:
	_update_surface_light()
	_draw_engine_exhaust()
	var wheel_center_y: float = 25.0 if vehicle_id == "kombi" else 22.0
	if vehicle_id == "kombi":
		# Larger tire stages sit slightly lower so the tread clears the fender lip;
		# the stock axle position stays exactly where it was.
		wheel_center_y += float(tire_level) * 1.15
	if showcase_shadow:
		_draw_showcase_shadow(wheel_center_y + wheel_visual_radius())
	else:
		_draw_road_contact_shadow()
	if vehicle_id == "kombi":
		if not kombi_rear_torn():
			_draw_kombi_exhaust()
		_draw_kombi_suspension(wheel_center_y)
	_draw_wheel(Vector2(rear_wheel_x, wheel_center_y))
	_draw_wheel(Vector2(front_wheel_x, wheel_center_y))
	if vehicle_id == "lieferwagen":
		_draw_delivery_van_body()
	elif vehicle_id == "offroad_pickup":
		_draw_offroad_pickup_body()
	else:
		_draw_kombi_body()
	_draw_tire_grit()
	_draw_upgrade_parts()
	_draw_boost_flame()
	_draw_zombie_latches()
	_draw_damage_feedback()
	_draw_impact_feedback()
	_draw_weapon_feedback()
	_draw_roof_crash()

func _draw_showcase_shadow(ground_y: float) -> void:
	for ring in range(3):
		var spread: float = float(ring) * 5.0
		var outline := PackedVector2Array()
		for point in range(32):
			var angle: float = TAU * float(point) / 32.0
			outline.append(Vector2(cos(angle) * (112.0 - spread), ground_y - 2.0 + sin(angle) * (7.0 - float(ring) * 1.8)))
		draw_colored_polygon(outline, Color(0.06, 0.035, 0.025, 0.25))
	for wheel_x in [rear_wheel_x,front_wheel_x]:
		var contact:=PackedVector2Array()
		for i in range(24):
			var angle:float=TAU*float(i)/24.0
			contact.append(Vector2(wheel_x+cos(angle)*14,ground_y-1+sin(angle)*2.0))
		draw_colored_polygon(contact,Color(.025,.02,.015,.55))

func _update_surface_light() -> void:
	if material==null:
		var light:=ShaderMaterial.new()
		light.shader=preload("res://scripts/vehicle_light.gdshader")
		material=light
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("workshop",1.0 if showcase_shadow else 0.0)

func _draw_road_contact_shadow() -> void:
	if not is_instance_valid(_ground_surface) or (not front_spring.is_colliding() and not rear_spring.is_colliding()):return
	# Ground positions are transformed back into vehicle space so the shadow
	# stays on the slope while the chassis pitches. No shadow over open water.
	for spring in [rear_spring,front_spring]:
		if not spring.is_colliding():continue
		var foot:Vector2=spring.get_collision_point()
		var ground:=PackedVector2Array()
		for i in range(24):
			var angle:float=TAU*float(i)/24.0
			var x:float=foot.x+cos(angle)*17.0
			var y:float=float(_ground_surface.height_at(x))+sin(angle)*2.0-0.5
			ground.append(to_local(Vector2(x,y)))
		draw_colored_polygon(ground,Color(.035,.045,.04,.36))

func _draw_weapon_feedback() -> void:
	if not weapon_active or weapon_level <= 0 or _weapon_shot_remaining <= 0.0:
		return
	var muzzle: Vector2 = KOMBI_WEAPON_MUZZLE
	var target := _weapon_shot_target_local
	if target.x > muzzle.x + 620.0:
		target = Vector2(muzzle.x + 620.0, lerpf(muzzle.y, target.y, 0.25))
	var fade: float = clampf(_weapon_shot_remaining / 0.11, 0.0, 1.0)
	draw_line(muzzle, target, Color(30.0 / 255.0, 35.0 / 255.0, 32.0 / 255.0, fade * 0.85), 4.6, true)
	draw_line(muzzle, target, Color(1.0, 0.81, 0.38, fade), 2.0, true)
	draw_circle(muzzle, 3.7 + fade * 2.1, Color(1.0, 0.89, 0.57, fade * 0.9))

func _roof_crawl_occupied() -> bool:
	for latch in zombie_latches:
		if latch.get("mount") in ["roof", "climbing"]:
			return true
	return false

func _roof_crawl_scale(variant: int) -> float:
	if vehicle_id != "kombi":
		return 1.0
	return minf(1.0, KOMBI_ROOF_CRAWL_WIDTH / float(ZOMBIE_DATA.profile(variant).visual_height))

func _roof_crawl_entry_x(grip_x: float) -> float:
	return clampf(grip_x - KOMBI_ROOF_CRAWL_WIDTH * 0.5, KOMBI_ROOF_REAR_X, KOMBI_ROOF_FRONT_X)

func _draw_zombie_latches() -> void:
	_zombie_pose_meshes.clear()
	for latch in zombie_latches:
		var anchor: Vector2 = latch["anchor"]
		var phase: float = float(latch["phase"])
		var wind: float = float(latch["wind"])
		var mount: String = String(latch.get("mount","roof"))
		var side: bool = mount != "roof"
		# Hands stay on their measured grip. Whole-sprite rocking makes the
		# climber appear to pivot through the car rather than hold onto it.
		draw_set_transform(anchor)
		var variant: int = latch["variant"]
		var pull: float = float(latch.get("pull", 0.0)) if mount == "climbing" else -1.0
		var crawl_offset := _roof_crawl_entry_x(anchor.x) - anchor.x if pull >= 0.0 else 0.0
		ATTACHMENT_ART.draw_pose(self, variant, floori(phase), side, wind, phase, 1.0, pull, _roof_crawl_scale(variant), crawl_offset)
	for released in _released_zombies:
		var world_transform := Transform2D(float(released["angle"]),Vector2(released["position"]))
		draw_set_transform_matrix(global_transform.affine_inverse()*world_transform)
		var opacity: float = 1.0-smoothstep(1.8,2.8,float(released.get("ground_age",0.0)))
		ATTACHMENT_ART.draw_pose(self,int(released["variant"]),int(released["frame"]),bool(released.get("side",false)),0.0,float(released["age"])*5.0,opacity,float(released.get("pull",-1.0)),float(released["crawl_scale"]),float(released["crawl_offset"]))
	draw_set_transform(Vector2.ZERO)

func _draw_crawling_zombie(variant: int, frame: int, opacity: float) -> void:
	ATTACHMENT_ART.draw_pose(self,variant,frame,false,0.0,0.0,opacity)

func _release_latched_zombie(latch: Dictionary) -> void:
	var anchor: Vector2 = latch["anchor"]
	var tangent: Vector2 = Vector2(-anchor.y,anchor.x).rotated(rotation)*angular_velocity
	var climbing: bool = latch.get("mount") == "climbing"
	var crawl_offset := _roof_crawl_entry_x(anchor.x) - anchor.x if climbing else 0.0
	_released_zombies.append({"crawl_scale":_roof_crawl_scale(int(latch["variant"])),"crawl_offset":crawl_offset,"variant":int(latch["variant"]),"facing":1.0,"position":to_global(anchor),"velocity":linear_velocity*0.65+tangent+Vector2(-35,-18),"floor_y":global_position.y+wheel_ground_clearance(),"age":0.0,"ground_age":0.0,"angle":global_rotation,"frame":floori(float(latch["phase"])),"side":String(latch.get("mount","roof"))!="roof","pull":float(latch.get("pull",-1.0)) if String(latch.get("mount","roof"))=="climbing" else -1.0,"spin":clampf(angular_velocity-0.7,-3.5,3.5)})

func _update_released_zombies(delta: float) -> void:
	if delta <= 0.0:
		return
	for index in range(_released_zombies.size()-1,-1,-1):
		var released: Dictionary = _released_zombies[index]
		released["age"] = float(released["age"])+delta
		if float(released["age"]) >= 6.0 or float(released.get("ground_age",0.0)) >= 2.8:
			_released_zombies.remove_at(index)
			continue
		var velocity: Vector2 = released["velocity"]
		velocity.y += 350.0*delta
		var point: Vector2 = Vector2(released["position"])+velocity*delta
		var angle: float = float(released["angle"])+float(released["spin"])*delta
		var ground: float = float(released["floor_y"])
		if is_instance_valid(_ground_surface):
			if _ground_surface.has_method("debris_floor_at"):
				ground = float(_ground_surface.debris_floor_at(point.x))
			elif _ground_surface.has_method("height_at"):
				ground = float(_ground_surface.height_at(point.x))
		var rect: Rect2 = ATTACHMENT_ART.local_rect(int(released["variant"]),int(released["frame"]),bool(released.get("side",false)),float(released.get("pull",-1.0)),float(released["crawl_scale"]),float(released["crawl_offset"]))
		var bottom := -INF
		for corner in [rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]:
			bottom = maxf(bottom,Vector2(corner).rotated(angle).y)
		if point.y+bottom >= ground:
			point.y = ground-bottom
			velocity.x = move_toward(velocity.x,0.0,450.0*delta)
			velocity.y = 0.0
			released["spin"] = move_toward(float(released["spin"]),0.0,5.0*delta)
			released["ground_age"] = float(released.get("ground_age",0.0))+delta
		released["position"]=point
		released["velocity"]=velocity
		released["angle"]=angle
	queue_redraw()

func zombie_latch_texture(variant_id: int) -> Texture2D:
	var texture := AtlasTexture.new()
	texture.atlas = ATTACHMENT_ART.ATLAS
	texture.region = ATTACHMENT_ART.RECTS[ATTACHMENT_ART.pose_index(variant_id,0)]
	return texture

func _draw_engine_exhaust() -> void:
	if fuel <= 0.0:
		return
	var idle_rumble: float = 0.12 if absf(speed_mps) > 4.0 else 0.0
	var exhaust_strength: float = maxf(_throttle_visual, idle_rumble)
	if exhaust_strength <= 0.02:
		return
	var emission_rate: float = 0.9 + exhaust_strength * 2.6
	var smoke_origin: Vector2 = KOMBI_EXHAUST_MOUTH if vehicle_id == "kombi" else Vector2(-98.0, 14.0)
	if kombi_rear_torn():
		smoke_origin = Vector2(-91, 23)
	for puff_index in range(4):
		var phase: float = fposmod(_engine_visual_time * emission_rate + float(puff_index) * 0.27, 1.0)
		var drift: float = phase * (22.0 + exhaust_strength * 16.0)
		var puff_center := Vector2(smoke_origin.x - drift, smoke_origin.y - phase * 8.0 + sin(_engine_visual_time * 4.0 + float(puff_index)) * 1.8)
		var alpha: int = int(round((1.0 - phase) * (42.0 + exhaust_strength * 72.0)))
		var puff_radius: float = 2.8 + phase * 4.8
		draw_circle(puff_center, puff_radius, Color8(112, 112, 101, alpha))
		draw_circle(puff_center + Vector2(-0.8, -0.7), puff_radius * 0.48, Color8(187, 174, 143, int(alpha * 0.42)))

func _draw_tire_grit() -> void:
	if _dust_visual_strength <= 0.015:
		return
	for fleck_index in range(5):
		var phase: float = fposmod(_dust_visual_time * 1.8 + float(fleck_index) * 0.20, 1.0)
		var drift: float = phase * (19.0 + float(fleck_index % 3) * 4.0)
		var fleck_center := Vector2(rear_wheel_x - 8.0 - drift, 40.0 - phase * (7.0 + float(fleck_index % 2) * 3.0))
		var alpha: int = int(round(_dust_visual_strength * (70.0 + float(fleck_index % 2) * 22.0) * (1.0 - phase)))
		var radius: float = 2.0 + phase * 2.8
		draw_circle(fleck_center, radius, Color8(186, 163, 121, alpha))

func _draw_impact_feedback() -> void:
	if _impact_visual_remaining <= 0.0 or _impact_visual_strength <= 0.01:
		return
	var duration: float = 0.14 + _impact_visual_strength * 0.11
	var progress: float = 1.0 - clampf(_impact_visual_remaining / duration, 0.0, 1.0)
	var alpha: int = int(round(235.0 * _impact_visual_strength * (1.0 - progress)))
	var center := Vector2(87.0, -11.0)
	var inner_radius: float = 5.0 + progress * 10.0
	var outer_radius: float = 17.0 + progress * 24.0
	for spark_index in range(12):
		var angle: float = float(spark_index) * TAU / 12.0 + _impact_visual_time * 2.4
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(center + direction * inner_radius, center + direction * outer_radius, Color8(255, 205, 112, alpha), 2.8, true)
	draw_circle(center, 3.6 * (1.0 - progress * 0.35), Color8(255, 238, 186, alpha))

func _draw_kombi_body() -> void:
	var body_texture: Texture2D = kombi_armor_body_texture()
	if body_texture == null:
		# Body armor is controlled only by the armor category. Engine, tank,
		# tire, and suspension levels must never swap in an armored body sprite.
		body_texture = KOMBI_BODY_TEXTURE
	# Preserve each source image's natural side-view ratio. The old 202 × 150
	# target compressed a 2:1 estate into a short, tall silhouette.
	var source_size: Vector2 = body_texture.get_size()
	var body_height: float = KOMBI_BODY_DRAW_WIDTH * source_size.y / maxf(1.0, source_size.x)
	var body_top: float = 25.0 - body_height * KOMBI_BODY_WHEEL_ARCH_CENTER_V
	var body_rect := Rect2(-KOMBI_BODY_DRAW_WIDTH * 0.5, body_top, KOMBI_BODY_DRAW_WIDTH, body_height)
	# Armor stages share the approved stage-1 paint grade so the orange body
	# stays visually consistent while the armor silhouette changes independently.
	var body_tint: Color = Color(0.94, 0.89, 0.79, 1.0) if armor_level > 0 else Color.WHITE
	var stage: int = visual_damage_stage()
	if stage < 2:
		draw_texture_rect(body_texture, body_rect, false, body_tint)
		return
	var shade: float = [0.99, 0.96, 0.91, 0.84][stage - 2]
	body_tint *= Color(shade, shade, shade, 1.0)
	if stage >= 4:
		_draw_exposed_engine()
	if kombi_rear_torn():
		_draw_kombi_torn_frame()
	draw_mesh(_kombi_damage_mesh(body_rect, stage), body_texture, Transform2D.IDENTITY, body_tint)
	if kombi_rear_torn():
		_draw_kombi_torn_edge(body_rect, stage)

func kombi_rear_torn() -> bool:
	return vehicle_id == "kombi" and (_rear_torn_at_rollover if roof_crash_time_s >= 0.0 else durability <= 12.0)

func _draw_kombi_torn_frame() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-91, 16), Vector2(-71, 15), Vector2(-63, 28), Vector2(-91, 27), Vector2(-94, 23)]), Color8(49, 48, 43))
	draw_polyline(PackedVector2Array([Vector2(-92, 17), Vector2(-86, 19), Vector2(-85, 24), Vector2(-74, 24)]), Color8(150, 126, 95), 2.0, true)
	draw_line(Vector2(-92, 22), Vector2(-77, 24), Color8(182, 174, 151), 2.0, true)

func _draw_kombi_torn_edge(rect: Rect2, stage: int) -> void:
	var seam := PackedVector2Array()
	var severity := float(stage - 1) / 4.0
	for y in [KOMBI_REAR_TEAR_TOP_V, 0.63, 0.72, 0.77]:
		var point := Vector2(KOMBI_REAR_TEAR_U, y)
		var crease := _kombi_panel_offset(point.x, point.y, true) * severity
		seam.append(rect.position + rect.size * point + crease + Vector2(0.8, 0.0))
	draw_polyline(seam, Color8(48, 43, 38), 3.0, true)
	for index in range(1, seam.size() - 1, 2):
		draw_line(seam[index], seam[index + 1] + Vector2(2.2, -0.8), Color8(199, 166, 128), 1.3, true)

func visual_damage_stage() -> int:
	if durability <= 0.0:
		return 5
	if durability < 25.0:
		return 4
	if durability < 50.0:
		return 3
	if durability < 70.0:
		return 2
	return 1 if durability < 90.0 else 0

func _kombi_damage_mesh(rect: Rect2, stage: int) -> ArrayMesh:
	var torn := kombi_rear_torn()
	var key := Vector2(rect.size.y, float(stage + (10 if torn else 0)))
	if _body_damage_meshes.has(key):
		return _body_damage_meshes[key]
	# Bend the original sheet metal and plow around the axles without swapping
	# the armor art or moving the wheels, roof mounts or collision shape.
	var columns := PackedFloat32Array([0.0, 0.08, KOMBI_REAR_TEAR_U, 0.22, 0.70, 0.82, 0.91, 1.0])
	var rows := PackedFloat32Array([0.0, 0.14, 0.27, 0.43, 0.51, KOMBI_REAR_TEAR_TOP_V, 0.63, 0.72, 0.77, 0.89, 1.0]) if torn else PackedFloat32Array([0.0, 0.43, 0.51, 0.63, 0.77, 1.0])
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var severity: float = float(stage - 1) / 4.0
	for y in rows:
		for x in columns:
			var point := Vector2(x, y)
			vertices.append(rect.position + rect.size * point + _kombi_panel_offset(x, y, torn) * severity)
			uvs.append(point)
	for row in range(rows.size() - 1):
		for column in range(columns.size() - 1):
			if torn and column < 2 and rows[row] >= KOMBI_REAR_TEAR_TOP_V:
				continue
			if stage >= 4 and columns[column] >= 0.82 and rows[row] >= 0.43 and rows[row] < 0.63:
				continue
			var top_left: int = row * columns.size() + column
			var bottom_left: int = top_left + columns.size()
			indices.append_array(PackedInt32Array([top_left, top_left + 1, bottom_left, top_left + 1, bottom_left + 1, bottom_left]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	_body_damage_meshes[key] = mesh
	return mesh

func _kombi_panel_offset(x: float, y: float, torn: bool) -> Vector2:
	var front := smoothstep(0.76, 1.0, x)
	var rear := 1.0 - smoothstep(0.0, 0.22, x)
	var hood_fold := maxf(0.0, 1.0 - absf(x - 0.88) / 0.10)
	var panel := smoothstep(0.36, 0.55, y)
	var offset := Vector2((-front * 16.0 + rear * 6.0) * panel, (-hood_fold * 10.0 + front * 8.0 + rear * 3.0) * panel)
	if torn:
		offset += Vector2(9.0, -5.0) * rear * smoothstep(0.15, 0.68, y)
		if is_equal_approx(x, KOMBI_REAR_TEAR_U):
			offset.x += sin(y * 43.0) * 4.0 * smoothstep(0.27, KOMBI_REAR_TEAR_TOP_V, y)
	return offset


func _draw_delivery_van_body() -> void:
	# Native 2:1 artwork; measured arch centers align with the existing axles.
	draw_texture_rect(DELIVERY_BODY_TEXTURE, Rect2(-94.0, -55.0, 189.0, 94.5), false)

func _draw_offroad_pickup_body() -> void:
	# Preserve the source artwork's 2:1 ratio; both cutout arches align with the wider axles.
	draw_texture_rect(OFFROAD_PICKUP_BODY_TEXTURE, Rect2(-90.0, -52.0, 184.0, 92.0), false)

func _draw_boost_flame() -> void:
	if not boost_active:
		return
	var phase: float = float(Time.get_ticks_msec()) * 0.035
	var flicker: float = 0.82 + 0.18 * sin(phase * 1.7)
	# The flame starts at the actual tailpipe outlet under the rear bumper.
	var exhaust_mouth: Vector2 = KOMBI_EXHAUST_MOUTH if vehicle_id == "kombi" else Vector2(-106.0, 15.0)
	if kombi_rear_torn():
		exhaust_mouth = Vector2(-91, 23)
	var tip := Vector2(exhaust_mouth.x - 45.0 - 12.0 * sin(phase), exhaust_mouth.y + 3.2 * sin(phase * 1.3))
	draw_colored_polygon(PackedVector2Array([exhaust_mouth + Vector2(0.0, -5.0), tip, exhaust_mouth + Vector2(0.0, 5.0)]), Color8(226, 76, 34, int(235.0 * flicker)))
	var inner_tip := tip + Vector2(17.0, -0.4)
	draw_colored_polygon(PackedVector2Array([exhaust_mouth + Vector2(0.0, -3.0), inner_tip, exhaust_mouth + Vector2(0.0, 3.0)]), Color8(255, 176, 75, 245))
	draw_colored_polygon(PackedVector2Array([exhaust_mouth + Vector2(0.0, -1.5), inner_tip + Vector2(10.0, 0.0), exhaust_mouth + Vector2(0.0, 1.5)]), Color8(255, 235, 167, 250))
	draw_circle(exhaust_mouth, 3.1, Color8(255, 226, 137, 230))

func _draw_wheel(center: Vector2) -> void:
	var tire_radius: float = wheel_visual_radius()
	# All vehicles share the illustrated tyre style, retaining their own radii.
	# The stock tire keeps a smaller factory profile and its own road-tire art.
	# Armor never changes this branch; only the tire upgrade selects the larger
	# off-road textures below.
	var stock_tire: bool = tire_level <= 0
	var wheel_size: float = tire_radius * (2.15 if stock_tire else 2.0)
	var wheel_texture: Texture2D = kombi_tire_texture(tire_level)
	var wrecked_front: bool = durability <= 0.0 and center.x > 0.0
	if wrecked_front:
		# Flatten the tire in vehicle space while keeping the original rim.
		draw_set_transform(center + Vector2(0.0, tire_radius * 0.20), 0.0, Vector2(1.08, 0.80))
	else:
		draw_set_transform(center, wheel_turn, Vector2.ONE)
	draw_texture_rect(wheel_texture, Rect2(Vector2(-wheel_size * 0.5, -wheel_size * 0.5), Vector2(wheel_size, wheel_size)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if brake_level > 0:
		var disc_radius: float = tire_radius * 0.43
		draw_circle(center, disc_radius, Color8(93, 103, 94, 220))
		draw_arc(center, disc_radius - 1.0, 0.0, TAU, 28, Color8(205, 183, 136), 1.4 + float(brake_level) * 0.35, true)
		for vent_index in range(6):
			var vent_angle: float = float(vent_index) * TAU / 6.0 + wheel_turn * 0.22
			draw_circle(center + Vector2(cos(vent_angle), sin(vent_angle)) * disc_radius * 0.62, 1.0, Color8(59, 68, 63))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(disc_radius * 0.52, -disc_radius * 0.68),
			center + Vector2(disc_radius * 1.0, -disc_radius * 0.62),
			center + Vector2(disc_radius * 0.92, -disc_radius * 0.08),
			center + Vector2(disc_radius * 0.49, -disc_radius * 0.14)
		]), Color8(210, 128, 79) if brake_level < 3 else Color8(232, 176, 88))

func wheel_visual_radius() -> float:
	var kombi_tire_steps: Array[float] = [0.0, 1.2, 2.7, 4.2]
	var tire_upgrade: float = kombi_tire_steps[clampi(tire_level, 0, 3)] if vehicle_id == "kombi" else float(tire_level) * 0.9
	return wheel_radius + tire_upgrade

func kombi_tire_texture(level: int) -> Texture2D:
	match clampi(level, 0, 3):
		0:
			return KOMBI_WHEEL_STOCK_TEXTURE
		1:
			return KOMBI_WHEEL_TIER1_TEXTURE
		2:
			return KOMBI_WHEEL_TEXTURE
		_:
			return KOMBI_WHEEL_TIER3_TEXTURE

func _draw_kombi_suspension(wheel_center_y: float) -> void:
	var spring_color: Color = Color8(173, 135, 79) if suspension_level == 0 else Color8(204, 151, 77) if suspension_level < 3 else Color8(232, 186, 99)
	var axle_pairs: Array = [[rear_wheel_x, rear_spring], [front_wheel_x, front_spring]]
	for axle_data in axle_pairs:
		var axle_x: float = float(axle_data[0])
		var ray: RayCast2D = axle_data[1] as RayCast2D
		var compression: float = 0.0
		if ray != null and ray.is_colliding():
			var ray_distance: float = ray.global_position.distance_to(ray.get_collision_point())
			compression = clampf((suspension_rest_length() - ray_distance) / 25.0, 0.0, 1.0)
		var shock_x: float = axle_x + (9.0 if axle_x < 0.0 else -9.0)
		var top := Vector2(shock_x - 2.0, wheel_center_y - 8.0)
		var bottom := Vector2(shock_x + 1.0, wheel_center_y + 3.0 - compression * 3.0)
		draw_line(top, bottom, Color8(30, 35, 32), 6.0, true)
		draw_line(top + Vector2(-1.0, 1.0), bottom + Vector2(-1.0, -1.0), Color8(169, 178, 158), 1.4, true)
		var coil_count: int = 3 + suspension_level
		for coil_index in range(coil_count):
			var coil_t: float = (float(coil_index) + 0.45) / float(coil_count)
			var coil_y: float = lerpf(top.y + 3.0, bottom.y - 2.0, coil_t)
			var coil_center_x: float = lerpf(top.x, bottom.x, coil_t)
			draw_line(Vector2(coil_center_x - 4.5, coil_y - 1.6), Vector2(coil_center_x + 4.5, coil_y + 1.6), Color8(41, 42, 37), 3.7, true)
			draw_line(Vector2(coil_center_x - 4.0, coil_y - 1.3), Vector2(coil_center_x + 4.0, coil_y + 1.3), spring_color, 2.2, true)

func _draw_upgrade_parts() -> void:
	if vehicle_id == "kombi":
		_draw_kombi_upgrade_parts()
		return
	if armor_level > 0:
		var armor_color := Color8(82, 92, 82)
		draw_line(Vector2(-74.0, 2.0), Vector2(61.0, 2.0), Color8(35, 40, 35), 5.0 + float(armor_level), true)
		draw_line(Vector2(-74.0, 1.0), Vector2(61.0, 1.0), armor_color, 3.0 + float(armor_level), true)
		draw_line(Vector2(-73.0, -1.0), Vector2(60.0, -1.0), Color8(158, 157, 132), 0.9, true)
		for bolt_x in [-61.0, -27.0, 27.0, 57.0]:
			draw_circle(Vector2(bolt_x, 1.0), 2.0, Color8(194, 173, 123))
	if armor_level >= 2:
		# A higher bumper hoop protects the front of the wagon.
		draw_line(Vector2(81.0, -19.0), Vector2(96.0, -16.0), Color8(63, 74, 68), 4.0)
		draw_line(Vector2(96.0, -16.0), Vector2(98.0, 1.0), Color8(92, 103, 90), 4.0)
		draw_line(Vector2(88.0, -4.0), Vector2(98.0, -4.0), Color8(195, 171, 123), 2.0)
	if armor_level >= 3:
		# Reinforced lower door plates make the final armor tier easy to spot.
		var plate := Rect2(-30.0, -11.0, 62.0, 8.0)
		draw_rect(plate.grow(1.0), Color8(35, 39, 35))
		draw_rect(plate, Color8(84, 93, 80))
		draw_line(Vector2(-29.0, -10.0), Vector2(31.0, -10.0), Color8(166, 158, 127), 1.0, true)
		for rivet_x in [-27.0, -6.0, 14.0, 29.0]:
			draw_circle(Vector2(rivet_x, -6.0), 1.1, Color8(183, 161, 114))
		for scratch in range(3):
			var x: float = -20.0 + float(scratch) * 14.0
			draw_line(Vector2(x, -7.0), Vector2(x + 4.0, -5.0), Color8(144, 145, 122, 150), 0.6, true)

func _draw_kombi_upgrade_parts() -> void:
	if nitro_level > 0:
		# The compact bottle assembly is mounted to the rear hatch, below the
		# roof luggage. Levels 1–2 show one bottle; level 3 adds the second bottle.
		var nitro_texture: Texture2D = KOMBI_NITRO_DUAL_TEXTURE if nitro_level >= 3 else KOMBI_NITRO_SINGLE_TEXTURE
		var nitro_source: Rect2 = Rect2(257.0, 74.0, 1070.0, 841.0) if nitro_level >= 3 else Rect2(423.0, 85.0, 1379.0, 557.0)
		var nitro_width: float = 38.0
		var nitro_height: float = nitro_width * nitro_source.size.y / nitro_source.size.x
		var nitro_size := Vector2(nitro_width, nitro_height)
		# Crop transparent image margins so the painted tanks stay crisp and legible.
		var nitro_rect := Rect2(Vector2(-88.0, -2.0) - nitro_size * 0.5, nitro_size)
		var nitro_tint := Color(0.55, 0.56, 0.55) if visual_damage_stage() >= 4 else Color.WHITE
		draw_texture_rect_region(nitro_texture, nitro_rect, nitro_source, nitro_tint)
		if visual_damage_stage() >= 4 and not kombi_rear_torn():
			draw_polyline(PackedVector2Array([Vector2(-97.0, -3.0), Vector2(-93.0, -4.0), Vector2(-92.0, -2.5), Vector2(-87.0, -4.0)]), Color8(174, 174, 154, 190), 0.9, true)

	if weapon_level > 0 and weapon_active:
		# Mount the compact cannon on the forward roof skin. The small downward
		# overlap lets its mounting plate visibly sit on the roof instead of float.
		var cannon_width: float = 46.0
		var cannon_height: float = cannon_width * float(KOMBI_HOOD_CANNON_TEXTURE.get_height()) / maxf(1.0, float(KOMBI_HOOD_CANNON_TEXTURE.get_width()))
		var mount := Vector2(-4.0, KOMBI_ROOF_SURFACE_Y + 1.5)
		var tilt: float = 0.19 if durability <= 0.0 else 0.0
		draw_set_transform(mount, tilt)
		draw_texture_rect(
			KOMBI_HOOD_CANNON_TEXTURE,
			# The PNG's transparent margins put the mounting plate near its bottom.
			# Set the foot just into the roof, toward the front and clear of the glass.
			Rect2(Vector2(-15.0, -cannon_height * 0.81), Vector2(cannon_width, cannon_height)),
			false,
			Color(0.53, 0.52, 0.49) if visual_damage_stage() >= 4 else Color.WHITE
		)
		draw_set_transform(Vector2.ZERO)

	if efficiency_level > 0 and not kombi_rear_torn():
		# A large, ribbed catalytic filter and polished tail pipe identify the efficiency kit.
		draw_line(Vector2(-96.0, 11.0), Vector2(-80.0, 11.0), Color8(178, 184, 159), 4.0, true)
		draw_rect(Rect2(-83.0, 5.0, 18.0, 13.0), Color8(93, 116, 91))
		draw_rect(Rect2(-81.0, 7.0, 4.0, 9.0), Color8(206, 191, 129))
		for rib_index in range(1 + efficiency_level):
			var rib_x: float = -77.0 + float(rib_index) * 3.7
			draw_line(Vector2(rib_x, 7.0), Vector2(rib_x, 16.0), Color8(180, 191, 152), 1.4, true)
		draw_circle(Vector2(-91.0, 11.0), 3.5, Color8(151, 159, 133))
		if efficiency_level >= 3:
			draw_circle(Vector2(-74.0, 11.5), 2.0, Color8(230, 198, 115))


func _draw_kombi_exhaust() -> void:
	var pipe_start := Vector2(-96.0, 27.0)
	draw_line(pipe_start, KOMBI_EXHAUST_MOUTH, Color8(26, 29, 27), 5.0, true)
	draw_line(pipe_start - Vector2(0.0, 0.9), KOMBI_EXHAUST_MOUTH - Vector2(0.0, 0.9), Color8(134, 132, 119), 1.5, true)
	draw_circle(KOMBI_EXHAUST_MOUTH, 2.2, Color8(24, 27, 25))

func kombi_armor_body_texture() -> Texture2D:
	if vehicle_id != "kombi":
		return null
	match armor_level:
		1:
			return KOMBI_ARMOR_TIER1_TEXTURE
		2:
			return KOMBI_ARMOR_TIER2_TEXTURE
		3:
			return KOMBI_ARMOR_TIER3_TEXTURE
		_:
			return null

func _draw_damage_feedback() -> void:
	var stage: int = visual_damage_stage()
	if stage == 0:
		return
	if vehicle_id == "kombi":
		_draw_kombi_damage_marks(stage)
	else:
		_draw_scraped_metal(Vector2(43.0, 4.0), 0.8 + float(stage) * 0.12)
		if stage >= 3:
			_draw_dented_panel(Vector2(61.0, 7.0), 0.82, false)
	if stage >= 4:
		_draw_engine_damage_smoke(stage)

func _draw_kombi_damage_marks(stage: int) -> void:
	_draw_scraped_metal(Vector2(32.0, 16.0), 0.68)
	if stage < 2:
		return
	_draw_panel_crease(Vector2(-17.0, 21.0), 0.86)
	_draw_scraped_metal(Vector2(-72.0, 7.0), 0.60)
	if stage < 3:
		return
	var glass := Color8(179, 214, 209, 206)
	var crack := PackedVector2Array([
		Vector2(16.0, -17.0), Vector2(23.0, -13.0), Vector2(20.0, -10.0), Vector2(28.0, -6.0), Vector2(32.0, -1.0)
	])
	draw_polyline(crack, glass, 0.9, true)
	draw_polyline(PackedVector2Array([Vector2(20.0, -10.0), Vector2(13.0, -7.0), Vector2(8.0, -9.0)]), glass, 0.8, true)
	draw_polyline(PackedVector2Array([Vector2(23.0, -13.0), Vector2(31.0, -14.0), Vector2(37.0, -11.0)]), glass, 0.8, true)
	_draw_panel_crease(Vector2(76.0, 7.0), 0.76)
	if stage < 4:
		return
	_draw_panel_crease(Vector2(21.0, 23.0), 1.12)
	var front_fold_x: float = 89.0 if armor_level >= 2 else 83.0
	_draw_panel_crease(Vector2(front_fold_x, 16.0), 0.48)
	var dark_glass := PackedVector2Array([
		Vector2(-40.0, -18.0), Vector2(-33.0, -20.0), Vector2(-28.0, -16.0), Vector2(-25.0, -17.0),
		Vector2(-20.0, -13.0), Vector2(-27.0, -11.0), Vector2(-31.0, -6.0), Vector2(-36.0, -9.0), Vector2(-44.0, -10.0)
	])
	if armor_level == 0:
		draw_colored_polygon(dark_glass, Color8(16, 28, 30, 236))
	draw_polyline(dark_glass, Color8(117, 157, 153, 174), 0.8, true)
	if stage < 5:
		return
	# Torn edge of the folded front skin on the wreck.
	draw_colored_polygon(PackedVector2Array([
		Vector2(55.0, 1.0), Vector2(68.0, -1.0), Vector2(77.0, 1.0), Vector2(84.0, 6.0),
		Vector2(79.0, 10.0), Vector2(72.0, 7.0), Vector2(64.0, 9.0), Vector2(60.0, 5.0)
	]), Color8(26, 24, 22))
	draw_polyline(PackedVector2Array([Vector2(55.0, 1.0), Vector2(68.0, -1.0), Vector2(77.0, 1.0), Vector2(84.0, 6.0)]), Color8(159, 118, 81), 1.2, true)

func _draw_scraped_metal(origin: Vector2, scale: float) -> void:
	var gouge := PackedVector2Array([
		origin + Vector2(-15.0, 3.0) * scale, origin + Vector2(-6.0, 1.0) * scale,
		origin + Vector2(-2.0, -2.0) * scale, origin + Vector2(5.0, -1.0) * scale,
		origin + Vector2(14.0, -6.0) * scale, origin + Vector2(10.0, -1.0) * scale,
		origin + Vector2(1.0, 1.0) * scale, origin + Vector2(-5.0, 4.0) * scale
	])
	draw_colored_polygon(gouge, Color8(67, 43, 30, 215))
	draw_polyline(PackedVector2Array([gouge[0], gouge[1], gouge[2], gouge[3], gouge[4]]), Color8(215, 178, 133, 215), 0.85, true)
	draw_line(origin + Vector2(-9.0, 6.0) * scale, origin + Vector2(4.0, 3.0) * scale, Color8(209, 170, 126, 162), 0.8, true)

func _draw_dented_panel(origin: Vector2, scale: float, steel: bool) -> void:
	var fold := PackedVector2Array([
		origin + Vector2(-19.0, 2.0) * scale, origin + Vector2(-8.0, -5.0) * scale,
		origin + Vector2(5.0, -5.5) * scale, origin + Vector2(18.0, -2.0) * scale,
		origin + Vector2(8.0, 1.0) * scale, origin + Vector2(5.0, 6.0) * scale,
		origin + Vector2(-9.0, 5.0) * scale
	])
	draw_colored_polygon(fold, Color8(28, 29, 27, 213) if steel else Color8(87, 43, 27, 211))
	draw_colored_polygon(PackedVector2Array([fold[0], fold[4], fold[5], fold[6]]), Color8(122, 112, 92, 153) if steel else Color8(187, 101, 48, 151))
	draw_polyline(PackedVector2Array([fold[0], fold[1], fold[2], fold[3]]), Color8(217, 176, 126, 174), 1.1, true)
	_draw_scraped_metal(origin + Vector2(0.0, 1.5) * scale, scale * 0.55)

func _draw_engine_damage_smoke(stage: int) -> void:
	var hood_y: float = 1.0 if vehicle_id != "lieferwagen" else -24.0
	var wrecked: bool = stage == 5 or kombi_rear_torn()
	var puff_count: int = 11 if wrecked else 4
	var smoke_length: float = 93.0 if wrecked else 34.0
	var speed_drift: float = clampf(linear_velocity.x / PIXELS_PER_METER / 23.0, 0.0, 1.0)
	for puff_index in range(puff_count - 1, -1, -1):
		var cycle: float = fposmod(_damage_visual_time * 24.0 + float(puff_index) * smoke_length / float(puff_count), smoke_length)
		var drift: float = sin(_damage_visual_time * 2.1 + float(puff_index)) * 4.0 - speed_drift * cycle * 0.65
		var center := Vector2(76.0 + drift, hood_y - cycle * (0.72 if wrecked else 0.60))
		var alpha: int = int(lerpf(201.0 if wrecked else 112.0, 8.0, cycle / smoke_length))
		var radius: float = (5.6 if wrecked else 2.6) + cycle * (0.15 if wrecked else 0.095)
		draw_circle(center, radius * 1.22, Color8(60, 58, 53, int(alpha * 0.23)))
		draw_circle(center, radius, Color8(41, 39, 36, int(alpha * (0.88 if wrecked else 0.72))))
		draw_circle(center - Vector2(radius * 0.25, radius * 0.18), radius * 0.64, Color8(122, 113, 93, int(alpha * 0.38)))

func _draw_roof_crash() -> void:
	if roof_crash_time_s < 0.0:
		return
	# Cancel body rotation so smoke and flames always rise toward the sky.
	draw_set_transform(Vector2(65.0, 0.0), -global_rotation, Vector2.ONE)
	var strength: float = smoothstep(0.0, 0.6, roof_crash_time_s)
	for puff in range(15):
		var age: float = fposmod(_damage_visual_time * 0.42 + float(puff) / 15.0, 1.0)
		var center := Vector2(sin(float(puff) * 2.4 + age * 3.0) * (4.0 + age * 12.0) - age * 12.0, -age * 95.0)
		var radius: float = (5.0 + age * 16.0) * strength
		draw_circle(center, radius, Color(0.16, 0.15, 0.14, (1.0 - age) * 0.52 * strength))
		draw_circle(center + Vector2(-radius * 0.25, -radius * 0.2), radius * 0.65, Color(0.32, 0.30, 0.27, (1.0 - age) * 0.28 * strength))
	var fire: float = smoothstep(1.5, 2.4, roof_crash_time_s)
	if fire > 0.0:
		for tongue in range(6):
			var x: float = float(tongue - 3) * 5.0
			var height: float = (25.0 + 13.0 * sin(_damage_visual_time * 12.0 + float(tongue) * 2.1)) * fire
			var sway: float = sin(_damage_visual_time * 9.0 + float(tongue)) * 6.0
			var shape := PackedVector2Array([Vector2(x - 7.0, 2.0), Vector2(x - 8.0, -height * 0.4), Vector2(x + sway, -height), Vector2(x + 6.0, -height * 0.35), Vector2(x + 7.0, 2.0)])
			draw_colored_polygon(shape, Color(0.98, 0.26, 0.035, 0.88 * fire))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 3.0, 0.0), Vector2(x + sway * 0.5, -height * 0.65), Vector2(x + 4.0, 0.0)]), Color(1.0, 0.78, 0.15, fire))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _update_shake_maneuver(delta: float, accelerate: bool, brake: bool, boosting: bool) -> void:
	_shake_cooldown_s = maxf(0.0, _shake_cooldown_s - delta)
	_shake_ready_s = maxf(0.0, _shake_ready_s - delta)
	if zombie_latches.is_empty() or airborne or overturned:
		_shake_brake_s = 0.0
		return
	# A deliberate brake pulse at actual travelling speed primes the maneuver.
	if brake and absf(linear_velocity.x) > 12.0 * PIXELS_PER_METER:
		if _shake_brake_s == 0.0:
			_shake_brake_start_speed = absf(linear_velocity.x) / PIXELS_PER_METER
		_shake_brake_s += delta
		if _shake_brake_s >= 0.22 and _shake_brake_start_speed - absf(linear_velocity.x) / PIXELS_PER_METER >= 2.0:
			_shake_ready_s = 1.8
	elif not brake:
		_shake_brake_s = 0.0
	if _shake_ready_s <= 0.0 or brake or not accelerate or _shake_cooldown_s > 0.0:
		return
	# Boost pulls harder; a normal throttle reversal still works without buying nitro.
	var pressure: float = 1.15 if boosting else 0.72
	for latch in zombie_latches:
		latch["shake_grip"] = float(latch.get("shake_grip", 0.0)) + delta * pressure
		latch["wind"] = minf(1.0, float(latch.get("wind", 0.0)) + delta * 2.0)
	var count := 0
	for latch in zombie_latches:
		if float(latch.get("shake_grip", 0.0)) >= lerpf(0.34, 0.64, float(latch.get("strength", 0.5))):
			latch["time_left"] = 0.0
			count += 1
	if count > 0:
		_shake_ready_s = 0.0
		_shake_cooldown_s = 1.0
		zombies_shaken.emit(count)

func engine_condition_factor() -> float:
	return lerpf(0.76, 1.0, smoothstep(0.0, 40.0, durability))

func _draw_exposed_engine() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(61, 6), Vector2(83, 2), Vector2(94, 7), Vector2(90, 15), Vector2(65, 15)]), Color8(37, 42, 41))
	for x in [66.0, 72.0, 78.0, 84.0]:
		draw_line(Vector2(x, 5), Vector2(x + 1, 12), Color8(148, 145, 120), 2.0, true)
	draw_polyline(PackedVector2Array([Vector2(62, 11), Vector2(69, 17), Vector2(84, 15), Vector2(91, 10)]), Color8(89, 76, 54), 2.0, true)

func record_damage_contact(world_position: Vector2) -> void:
	var local := to_local(world_position)
	last_damage_local = Vector2(clampf(local.x, -85.0, 87.0), clampf(local.y, 3.0, 25.0))

func wheel_ground_clearance() -> float:
	if vehicle_id != "kombi":
		return 25.0 + wheel_visual_radius()
	var visible_fraction: float = [0.798, 0.948, 0.950, 0.955][clampi(tire_level, 0, 3)]
	var sprite_scale: float = 1.075 if tire_level == 0 else 1.0
	return 25.0 + float(tire_level) * 1.15 + wheel_visual_radius() * visible_fraction * sprite_scale

func suspension_rest_length() -> float:
	if vehicle_id != "kombi":
		return 55.0
	var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity", 350.0)) * gravity_scale
	return wheel_ground_clearance() + mass * gravity / (2.0 * _suspension_strength)

func _draw_panel_crease(origin: Vector2, scale: float) -> void:
	var line := PackedVector2Array([origin + Vector2(-12, 2) * scale, origin + Vector2(-4, -1) * scale, origin + Vector2(3, 0) * scale, origin + Vector2(12, -3) * scale])
	draw_polyline(line, Color8(66, 48, 34, 165), 0.85, true)
	var edge := PackedVector2Array()
	for point in line:
		edge.append(point + Vector2(0, 0.7))
	draw_polyline(edge, Color8(218, 158, 99, 140), 0.6, true)





