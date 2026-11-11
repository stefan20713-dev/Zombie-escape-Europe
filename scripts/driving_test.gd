extends Node2D

const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const ZOMBIE_DATA = preload("res://scripts/zombie_data.gd")
const PIXELS_PER_METER: float = CAMPAIGN_DATA.PIXELS_PER_METER
const WAGON_SCENE: PackedScene = preload("res://scenes/wagon.tscn")
const ENGINE_SOUND: AudioStream = preload("res://assets/audio/engine_loop.wav")
const BOOST_SOUND: AudioStream = preload("res://assets/audio/boost.wav")
const IMPACT_SOUND: AudioStream = preload("res://assets/audio/impact.wav")
const PICKUP_SOUND: AudioStream = preload("res://assets/audio/pickup.wav")
const TEST_COURSE_LENGTH_M: float = DrivingTestCourse.COURSE_LENGTH_M
const AMSTERDAM_FUEL_FACTOR: float = 0.52
const SERIES_LEVELS: Dictionary = {"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}
const TUNED_LEVELS: Dictionary = {"engine": 2, "tires": 2, "tank": 1, "armor": 2, "suspension": 1, "efficiency": 1, "brakes": 1, "nitro": 3, "weapon": 1}

var wagon: EscapeWagon
var course: DrivingTestCourse
var camera: Camera2D
var _instruments: Control
var readout_label: Label
var status_label: Label
var _engine_player: AudioStreamPlayer
var _boost_player: AudioStreamPlayer
var _impact_player: AudioStreamPlayer
var _pickup_player: AudioStreamPlayer
var _test_build_tuned: bool = false
var _boost_was_active: bool = false
var _finished: bool = false
var _arrival_time_s:float=-1.0
var _arrival_brake:float=0.0
var _arrival_income:int=0
var _arrival_balance:int=-1
var _arrival_upgrade_hint:String=""
var _water_crash_time_s: float = -1.0
var _roof_crash_time_s: float = -1.0
var _roof_crash_start_durability: float = 0.0
var _roof_crash_start_y: float = 0.0
var _roof_crash_ground_y: float = 0.0
var _status_text: String = ""
var _status_time_s: float = 0.0
var _landing_count: int = 0
var elapsed_s: float = 0.0
var distance_m: float = 0.0
var _start_x: float = 0.0
var _speed_peak_kmh: float = 0.0
var _impact_count: int = 0
var _last_collision_loss_kmh: float = 0.0
var _combo_count := 0
var _combo_left_s := 0.0
var _combo_coins := 0
var _jump_age_s := 0.0
var _jump_start_x := 0.0
var _jump_max_clearance := 0.0
var _jump_active := false
var _jump_last_reward_x := -10000.0
var _bonus_paid := false
var _combo_label: Label
var _action_hint_label: Label
var _blast_shake_s := 0.0

var _preview_bonus_coins: int = 0
var _zombie_coins: int = 0
var _zombie_latch_cooldown_s: float = 0.0
var _reward_message: String = ""
var _preview_supply_count: int = 0
var _run_started: bool = false
var _paused: bool = false
var _touch_accelerate: bool = false
var _touch_brake: bool = false
var _touch_boost: bool = false
var _touch_buttons: Dictionary = {}
var _touch_fingers: Dictionary = {}
var _touch_accelerate_pulse_s: float = 0.0
var _touch_brake_pulse_s: float = 0.0
var _touch_boost_pulse_s: float = 0.0
var _coins_label: Label
var _zombie_hits_label: Label
var _distance_label: Label
var _hud_layer: CanvasLayer
var _pause_overlay: Control
var _collapse_site: Node2D
var workshop_world_id: String = ""
var workshop_vehicle: String = ""
var workshop_upgrades: Dictionary = {}
var workshop_rewards_enabled: bool = false
var workshop_stock_test: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	course = get_node("Course") as DrivingTestCourse
	course.process_mode = Node.PROCESS_MODE_PAUSABLE
	if course.has_signal("route_decided"):
		course.connect("route_decided", _on_route_decided)
	if course.has_signal("bonus_coin_collected"):
		course.connect("bonus_coin_collected", _on_bonus_coin_collected)
	if course is AmsterdamPreviewCourse:
		(course as AmsterdamPreviewCourse).lock_water_entered.connect(_on_lock_water_entered)
		(course as AmsterdamPreviewCourse).lock_approach.connect(func(): _set_status("SCHLEUSENBRÜCKE · ZIEL %d KM/H" % int(course.LOCK_MIN_SPEED_KMH), 4.0))
	var backdrop_view: Node = get_node_or_null("Backdrop/BackdropView")
	if backdrop_view != null and String(course.call("preview_city_name")) == "Amsterdam":
		backdrop_view.call("configure_preview_world", 0, _course_length_m())
	wagon = WAGON_SCENE.instantiate() as EscapeWagon
	wagon.name = "Wagon"
	wagon.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(wagon)
	if backdrop_view != null and backdrop_view.has_method("bind_route_surface"):
		backdrop_view.call("bind_route_surface", course, wagon)
	wagon.landed.connect(_on_wagon_landed)
	wagon.zombies_shaken.connect(_on_zombies_shaken)
	if course is AmsterdamPreviewCourse:
		course.action.message.connect(func(text: String): _set_status(text, 3.0))
		course.action.hazard_hit.connect(_on_crane_hit)
		course.explosives.exploded.connect(_on_drum_exploded)
	_collapse_site = course.get_node_or_null("CollapseSite") as Node2D
	if is_instance_valid(_collapse_site):
		_collapse_site.connect("message", func(message: String): _set_status(message, 2.0))
		_collapse_site.connect("blast", _on_structure_blast)
		_collapse_site.connect("clean_pass", _on_structure_passed)
	course.zombie_shot.connect(_on_zombie_shot)
	course.encounter_hit.connect(_on_encounter_hit)
	camera = get_node("Camera2D") as Camera2D
	camera.make_current()
	_setup_audio()
	_start_test_run()
	_build_hud()

func _process(delta: float) -> void:
	if _status_time_s > 0.0:
		_status_time_s = maxf(0.0, _status_time_s - delta)
		if status_label != null:
			status_label.queue_redraw()
	if _engine_player != null and not _finished:
		var speed_fraction: float = clampf(absf(wagon.speed_mps) / 20.0, 0.0, 1.0)
		var throttle: bool = _touch_accelerate or _touch_accelerate_pulse_s > 0.0 or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
		_engine_player.pitch_scale = clampf(0.78 + speed_fraction * 0.78 + (0.12 if throttle else 0.0), 0.72, 1.72)
		_engine_player.volume_db = lerpf(-23.0, -9.0, speed_fraction) if throttle else lerpf(-29.0, -13.0, speed_fraction)
	elif _engine_player != null:
		_engine_player.volume_db = lerpf(_engine_player.volume_db, -42.0, 1.0 - exp(-delta * 4.0))
		if _engine_player.playing and _engine_player.volume_db <= -41.5:
			_engine_player.stop()
	var boosting: bool = wagon != null and wagon.boost_active
	if boosting and not _boost_was_active and _boost_player != null:
		_boost_player.play()
	_boost_was_active = boosting

func _physics_process(delta: float) -> void:
	if _finished or _paused:
		return
	if _arrival_time_s>=0.0:
		_update_arrival(delta)
		return
	if _water_crash_time_s >= 0.0:
		wagon.update_zombie_latches(delta)
		_water_crash_time_s += delta
		wagon.modulate.a = 1.0 - smoothstep(0.15, 1.2, _water_crash_time_s)
		wagon.position.y += delta * 25.0
		if _water_crash_time_s >= 1.25:
			_finish_test_run("GAME OVER")
		return
	if _roof_crash_time_s >= 0.0:
		wagon.update_zombie_latches(delta)
		if course is AmsterdamPreviewCourse:course.update_wreck_horde(delta)
		_roof_crash_time_s += delta
		wagon.position.y = lerpf(_roof_crash_start_y, _roof_crash_ground_y, smoothstep(0.0, 0.45, _roof_crash_time_s))
		wagon.roof_crash_time_s = _roof_crash_time_s
		wagon.durability = _roof_crash_start_durability * (1.0 - smoothstep(1.5, 3.8, _roof_crash_time_s))
		if _roof_crash_time_s >= 1.5:
			_set_status("MOTOR IN FLAMMEN", 1.0)
		_update_hud(false, false, false)
		if _roof_crash_time_s >= 3.8:
			_finish_test_run("GAME OVER")
		return
	_zombie_latch_cooldown_s = maxf(0.0, _zombie_latch_cooldown_s - delta)
	_touch_accelerate_pulse_s = maxf(0.0, _touch_accelerate_pulse_s - delta)
	_touch_brake_pulse_s = maxf(0.0, _touch_brake_pulse_s - delta)
	_touch_boost_pulse_s = maxf(0.0, _touch_boost_pulse_s - delta)
	var accelerate: bool = _touch_accelerate or _touch_accelerate_pulse_s > 0.0 or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var brake: bool = _touch_brake or _touch_brake_pulse_s > 0.0 or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	var balance: float = float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var boost: bool = _touch_boost or _touch_boost_pulse_s > 0.0 or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SHIFT)
	if not _run_started:
		if accelerate or brake or boost or balance != 0.0:
			_run_started = true
			wagon.freeze = false
		else:
			_update_hud(false, false, false)
			return
	_update_action_tracking(delta, brake)
	var road_angle: float = course.slope_at(wagon.position.x)
	# Introductory city: armor and upgraded tires are optional; later cities own their tuning.
	wagon.route_damage_factor = lerpf(0.70, 0.22, smoothstep(700.0, 1000.0, distance_m)) if course is AmsterdamPreviewCourse else 1.0
	var route_fuel_factor: float = AMSTERDAM_FUEL_FACTOR if course is AmsterdamPreviewCourse else course.fuel_factor()
	if course is AmsterdamPreviewCourse and course.lock_flight_active:
		wagon.update_zombie_latches(delta)
		wagon.fuel = maxf(0.0, wagon.fuel - delta * wagon.fuel_consumption_rate(accelerate, boost) * route_fuel_factor)
	else:
		wagon.simulate(delta, accelerate, brake, boost, balance, road_angle, -1.0, route_fuel_factor)
		wagon.update_overturn_state(delta, course.height_at(wagon.position.x), road_angle)
	elapsed_s += delta
	var current_distance: float = (wagon.position.x - _start_x) / PIXELS_PER_METER
	distance_m = maxf(distance_m, minf(_course_length_m(), current_distance))
	_speed_peak_kmh = maxf(_speed_peak_kmh, absf(wagon.speed_mps) * 3.6)
	var speed_fraction: float = clampf(absf(wagon.speed_mps) / 24.0, 0.0, 1.0)
	# Frame the wagon close to the reference image while keeping enough visible
	# approach for the next encounter. At 1280x720 the body uses about 27% of
	# the width and the wheels sit just above the street's lower third.
	var camera_lead: float = lerpf(278.0, 285.0, speed_fraction) + (7.0 if wagon.boost_active else 0.0)
	var camera_y: float = wagon.position.y - 75.0
	var target_zoom: float = lerpf(1.55, 1.50, speed_fraction) - (0.015 if wagon.boost_active else 0.0)
	if course is AmsterdamPreviewCourse:
		var meter: float = wagon.position.x / PIXELS_PER_METER
		var bridge_view: float = smoothstep(390.0, 423.0, meter) * (1.0 - smoothstep(469.0, 502.0, meter))
		camera_lead += 218.0 * bridge_view
		target_zoom -= 0.53 * bridge_view
		var lock_view: float = smoothstep(1200.0, 1265.0, meter) * (1.0 - smoothstep(course.LOCK_LANDING_M + 5.0, course.LOCK_REJOIN_M, meter))
		camera_lead += 320.0 * lock_view
		target_zoom -= 0.70 * lock_view
		camera_y = lerpf(camera_y, course.lock_base_y() - 15.0, lock_view)
		if course._lock_missed:
			camera_y = lerpf(camera_y, wagon.position.y - 75.0, smoothstep(0.75, 1.65, course._lock_flight_time))
	if is_instance_valid(_collapse_site):
		var framing: float = _collapse_site.camera_weight(wagon.position.x)
		camera_lead += 176.0 * framing
		target_zoom -= 0.39 * framing
	_blast_shake_s = maxf(0.0, _blast_shake_s - delta)
	var target_camera := Vector2(wagon.position.x + camera_lead, camera_y)
	if _blast_shake_s > 0.0:
		target_camera += Vector2(sin(elapsed_s * 83.0), cos(elapsed_s * 67.0)) * 3.0 * (_blast_shake_s / 0.18)
	camera.position = camera.position.lerp(target_camera, 1.0 - exp(-10.0 * delta))
	camera.zoom = camera.zoom.lerp(Vector2.ONE * target_zoom, 1.0 - exp(-5.0 * delta))
	_update_hud(accelerate, brake, boost)
	if distance_m >= _course_length_m():
		if course is AmsterdamPreviewCourse:_begin_arrival()
		else:_finish_test_run()
	elif wagon.overturned:
		_begin_roof_crash()
	elif wagon.durability <= 0.0:
		_finish_test_run("KAROSSERIE ZERSTÖRT")
	elif wagon.fuel <= 0.0 and absf(wagon.speed_mps) < 0.4:
		_finish_test_run("TANK LEER")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_R:
		_start_test_run()
	elif event.keycode == KEY_T and not _test_profile_label().is_empty():
		_toggle_test_profile()
	elif event.keycode == KEY_ESCAPE:
		_toggle_pause()

func _test_profile_label() -> String:
	if not workshop_vehicle.is_empty():
		return ""
	return "MIT SERIENPROFIL STARTEN" if _test_build_tuned else "MIT TUNINGPROFIL STARTEN"

func _toggle_test_profile() -> void:
	_test_build_tuned = not _test_build_tuned
	_start_test_run()
	_set_status("TUNINGSPROFIL · MOTOR II / REIFEN II / PANZERUNG II / NITRO III / WAFFE" if _test_build_tuned else "SERIENPROFIL · NITRO GESPERRT")

func _setup_audio() -> void:
	_engine_player = AudioStreamPlayer.new()
	_engine_player.name = "TestEngineAudio"
	_engine_player.stream = ENGINE_SOUND.duplicate() as AudioStreamWAV
	var engine_stream: AudioStreamWAV = _engine_player.stream as AudioStreamWAV
	if engine_stream != null:
		engine_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		engine_stream.loop_begin = 0
		engine_stream.loop_end = engine_stream.data.size() / 2
	_engine_player.volume_db = -23.0
	add_child(_engine_player)
	_engine_player.play()
	_boost_player = AudioStreamPlayer.new()
	_boost_player.name = "TestBoostAudio"
	_boost_player.stream = BOOST_SOUND
	_boost_player.volume_db = -4.0
	add_child(_boost_player)
	_impact_player = AudioStreamPlayer.new()
	_impact_player.name = "TestImpactAudio"
	_impact_player.stream = IMPACT_SOUND
	_impact_player.volume_db = 0.0
	add_child(_impact_player)
	_pickup_player = AudioStreamPlayer.new()
	_pickup_player.name = "TestPickupAudio"
	_pickup_player.stream = PICKUP_SOUND
	_pickup_player.volume_db = -2.0
	add_child(_pickup_player)

func _start_test_run() -> void:
	_paused = false
	_run_started = false
	_touch_accelerate = false
	_touch_brake = false
	_touch_boost = false
	_touch_fingers.clear()
	_touch_accelerate_pulse_s = 0.0
	_touch_brake_pulse_s = 0.0
	_touch_boost_pulse_s = 0.0
	if get_tree().paused:
		get_tree().paused = false
	if is_instance_valid(_pause_overlay):
		_pause_overlay.queue_free()
	_pause_overlay = null
	if course != null:
		course.set_physics_process(true)
	var backdrop_view: Node = get_node_or_null("Backdrop/BackdropView")
	if backdrop_view != null:
		backdrop_view.set_process(true)
	_finished = false
	_arrival_time_s=-1.0
	_arrival_income=0
	_arrival_balance=-1
	_arrival_upgrade_hint=""
	_roof_crash_time_s = -1.0
	_water_crash_time_s = -1.0
	wagon.modulate = Color.WHITE
	wagon.roof_crash_time_s = -1.0
	elapsed_s = 0.0
	distance_m = 0.0
	_speed_peak_kmh = 0.0
	_impact_count = 0
	_last_collision_loss_kmh = 0.0
	_blast_shake_s = 0.0
	_combo_count = 0
	_combo_left_s = 0.0
	_combo_coins = 0
	_jump_active = false
	_jump_age_s = 0.0
	_jump_max_clearance = 0.0
	_jump_last_reward_x = -10000.0
	_bonus_paid = false
	_preview_bonus_coins = 0
	_zombie_coins = 0
	_zombie_latch_cooldown_s = 0.0
	_reward_message = ""
	_preview_supply_count = 0
	_landing_count = 0
	_status_time_s = 0.0
	var levels: Dictionary = TUNED_LEVELS if _test_build_tuned else SERIES_LEVELS
	if not workshop_vehicle.is_empty():
		levels = workshop_upgrades
	wagon.configure(levels, "kombi" if workshop_vehicle.is_empty() else workshop_vehicle)
	wagon.route_damage_factor = 1.0
	wagon.set_weapon_active(_test_build_tuned or int(levels.get("weapon", 0)) > 0)
	wagon.reset_at(DrivingTestCourse.START_M * PIXELS_PER_METER, course)
	wagon.freeze = true
	wagon.linear_velocity = Vector2.ZERO
	wagon.angular_velocity = 0.0
	_start_x = wagon.position.x
	course.reset_test_run(wagon)
	_boost_was_active = false
	var initial_lead: float = 278.0
	camera.position = Vector2(wagon.position.x + initial_lead, wagon.position.y - 75.0)
	camera.zoom = Vector2.ONE * 1.55
	camera.force_update_scroll()
	if _engine_player != null and not _engine_player.playing:
		_engine_player.play()
	if _engine_player != null:
		_engine_player.stream_paused = false
	_update_hud(false, false, false)

func _on_encounter_hit(kind: String, resistance: float, variant_id: int, _group_size: int, world_x: float, ground_y: float, speed_before_mps: float) -> void:
	if _finished or _paused or _arrival_time_s>=0:
		return
	if kind == "supply_crate":
		_preview_supply_count += 1
		var fuel_before: float = wagon.fuel
		var durability_before: float = wagon.durability
		var fuel_gain: float = minf(wagon.fuel_capacity * 0.22, wagon.fuel_capacity - wagon.fuel)
		var durability_gain: float = minf(15.0, 100.0 - wagon.durability)
		wagon.fuel = minf(wagon.fuel_capacity, wagon.fuel + fuel_gain)
		wagon.durability = minf(100.0, wagon.durability + durability_gain)
		var fuel_percent_gain: int = int(round((wagon.fuel - fuel_before) / maxf(1.0, wagon.fuel_capacity) * 100.0))
		var durability_percent_gain: int = int(round(wagon.durability - durability_before))
		course.spawn_impact_particles(world_x, ground_y, 0.24)
		if _pickup_player != null:
			_pickup_player.play()
		_set_status("KAIVORRÄTE · +%d%% TANK · +%d%% KAROSSERIE" % [fuel_percent_gain, durability_percent_gain], 1.4)
		return
	_impact_count += 1
	wagon.record_damage_contact(Vector2(world_x, ground_y - 20.0))
	if kind in ["zombie_group", "runner_group"]:
		_zombie_coins += 2
		_combo_event("TREFFER")
		var profile: Dictionary = ZOMBIE_DATA.profile(variant_id)
		var speed_fraction: float = clampf(speed_before_mps / 24.0, 0.0, 1.0)
		var retention: float = lerpf(0.96, float(profile.get("speed_retention", 0.78)), speed_fraction)
		if course is AmsterdamPreviewCourse:
			retention = lerpf(retention, 1.0, 0.62)
		var damage: float = float(profile.get("hit_damage", 5.5)) * lerpf(0.22, 0.36, speed_fraction) * 0.65
		wagon.hit_zombie(damage, retention, float(profile.get("stop_duration", 0.0)) * 0.35, true)
		var attached := false
		if variant_id in [1, 2, 3, 4, 5] and wagon.zombie_latches.size() < 2 and _zombie_latch_cooldown_s <= 0.0:
			var latch: Dictionary = ZOMBIE_DATA.latch_profile(variant_id, floori(world_x / PIXELS_PER_METER) * 17)
			if not latch.is_empty():
				attached = wagon.add_zombie_latch(minf(3.6, float(latch["duration"]) * 0.75), float(latch["drag"]) * 0.55, wagon.zombie_latches.size(), variant_id, float(latch["damage"]) * 0.25, _impact_count % 3)
				_zombie_latch_cooldown_s = 0.8
		course.spawn_impact_particles(world_x, ground_y, 0.68)
		var enemy_name: String = "LÄUFER" if variant_id == 2 else "SCHWERER ZOMBIE" if variant_id >= 3 else "ZOMBIE"
		_set_status("ZOMBIE KLAMMERT · KURZ BREMSEN, DANN GAS / NITRO" if attached else "%s GETROFFEN · -%.0f KM/H" % [enemy_name, (1.0 - retention) * speed_before_mps * 3.6])
	else:
		var impact: Dictionary = wagon.hit_weighted_obstacle(resistance, true)
		_last_collision_loss_kmh = float(impact.get("speed_loss_kmh", 0.0))
		course.spawn_impact_particles(world_x, ground_y, resistance)
		_break_combo()
		var label: String = "LEICHTE BARRIERE GIBT NACH" if resistance < 0.5 else "SCHWERE SPERRE · SCHWUNG VERLOREN"
		match kind:
			"harbor_timber_barrier":
				label = "HOLZSPERRE ZERSPLITTERT"
				course.spawn_timber_fragments(world_x, ground_y, speed_before_mps)
			"harbor_metal_gate": label = "METALLSPERRE VERBOGEN · SCHWUNG VERLOREN"
			"barrel_stack": label = "FÄSSER ROLLEN WEG"
			"tram_wreck": label = "TRAMWRACK · SCHWUNG VERLOREN"
			"canal_cart": label = "KAI-LADUNG · AUFPRALL"
			"scaffold": label = "BAUGERÜST BRICHT ZUSAMMEN"
		_set_status("%s · -%.0f KM/H · -%.0f%% ZUSTAND" % [label, _last_collision_loss_kmh, float(impact.get("damage", 0.0))])
	if _impact_player != null:
		_impact_player.pitch_scale = 1.0
		_impact_player.play()

func _on_wagon_landed(impact_speed: float) -> void:
	if _arrival_time_s>=0:return
	_check_clean_landing(impact_speed)
	_landing_count += 1
	if course is AmsterdamPreviewCourse and impact_speed > 1.0:
		course.spawn_impact_particles(wagon.position.x, wagon.position.y + 25.0 + wagon.wheel_visual_radius(), 0.12, true)
	_set_status("LANDUNG · AUFSETZEN MIT %.1f M/S" % (impact_speed / PIXELS_PER_METER) if impact_speed > PIXELS_PER_METER else "LANDUNG · STABIL AUF ALLEN RÄDERN")
	if impact_speed > 4.0 and _impact_player != null:
		_impact_player.pitch_scale = 1.0
		_impact_player.play()

func _on_route_decided(route_name: String, upper_route: bool) -> void:
	_set_status(route_name + (" · BONUSROUTE" if upper_route else " · DURCHBRUCH"), 1.4)

func _on_bonus_coin_collected(amount: int) -> void:
	_preview_bonus_coins += amount
	_set_status("BRÜCKENBONUS · +%d MÜNZEN" % amount, 0.9)

func _on_zombie_shot() -> void:
	if _arrival_time_s>=0 or _finished:return
	_combo_event("TREFFER")
	_zombie_coins += 2
	_impact_count += 1
	if _impact_player != null:
		_impact_player.pitch_scale = 1.0
		_impact_player.play()

func _record_workshop_reward() -> void:
	if _bonus_paid:
		return
	_bonus_paid = true
	var distance_coins: int = floori(minf(distance_m, _course_length_m()) / 16.0)
	var earned: int = distance_coins + _zombie_coins + _preview_bonus_coins
	if earned <= 0:
		return
	var progress: Node = load("res://scripts/game.gd").new()
	var balance: int
	if workshop_world_id.is_empty() or workshop_world_id == "amsterdam":
		balance = progress.save_amsterdam_drive_reward(earned, _arrival_time_s >= 0.0)
	else:
		balance = progress.save_route_drive_reward(workshop_world_id, earned, distance_m, distance_m >= _course_length_m())
	_arrival_income=earned
	_arrival_balance=balance
	_reward_message = "+%d Münzen  ·  Strecke %d  ·  Zombies %d  ·  Aktionen %d" % [earned, distance_coins, _zombie_coins, _preview_bonus_coins]
	if balance < 0:
		_reward_message += "\nSpeichern fehlgeschlagen"
	else:
		_arrival_upgrade_hint=_affordable_upgrade_text(progress,balance)
		_reward_message += "\n" + _arrival_upgrade_hint
	progress.free()

func _affordable_upgrade_text(progress: Node, balance: int) -> String:
	var names := {"engine": "Motor", "nitro": "Nitro", "tires": "Reifen", "tank": "Tank", "armor": "Panzerung", "suspension": "Fahrwerk", "efficiency": "Verbrauch", "brakes": "Bremsen", "weapon": "Waffe"}
	for part: String in names:
		if part == "weapon" and not progress.can_buy_weapon_upgrade():
			continue
		var price: int = progress.upgrade_price(part)
		if price > 0 and price <= balance:
			return "Bezahlbar: %s (%d)  ·  Guthaben %d" % [names[part], price, balance]
	return "Guthaben %d Münzen" % balance

func _on_lock_water_entered() -> void:
	if _finished or _water_crash_time_s >= 0.0:
		return
	_water_crash_time_s = 0.0
	wagon.boost_active = false
	wagon.freeze = true
	wagon.linear_velocity = Vector2.ZERO
	wagon.angular_velocity = 0.0
	_touch_fingers.clear()
	_touch_accelerate = false
	_touch_boost = false
	if _engine_player != null:
		_engine_player.stop()
	_set_status("INS WASSER GEFALLEN", 2.0)

func _begin_arrival() -> void:
	if _arrival_time_s>=0 or _finished:return
	_arrival_time_s=0.0
	distance_m=_course_length_m()
	_arrival_brake=maxf(1.0,absf(wagon.linear_velocity.x)/1.7)
	wagon.boost_active=false
	wagon.set_weapon_active(false)
	_touch_fingers.clear()
	_touch_accelerate=false
	_touch_brake=false
	_touch_boost=false
	course.begin_finish_safety()
	# Attached opponents visibly let go; they cannot damage a completed run.
	for latch in wagon.zombie_latches:wagon._release_latched_zombie(latch)
	wagon.zombie_latches.clear()
	_set_status("AMSTERDAM GESCHAFFT · HAFENAUSFAHRT",2.0)

func _update_arrival(delta:float) -> void:
	_arrival_time_s+=delta
	var saved_fuel:float=wagon.fuel
	var saved_health:float=wagon.durability
	wagon.simulate(delta,false,false,false,0.0,course.slope_at(wagon.position.x),-1.0,0.0)
	wagon.fuel=saved_fuel
	wagon.durability=saved_health
	wagon.linear_velocity.x=move_toward(wagon.linear_velocity.x,0.0,_arrival_brake*delta)
	wagon.update_zombie_latches(delta)
	camera.position=camera.position.lerp(wagon.position+Vector2(220,-75),1-exp(-4*delta))
	camera.zoom=camera.zoom.lerp(Vector2.ONE*1.5,1-exp(-3*delta))
	_update_hud(false,false,false)
	if _arrival_time_s>=2.0:_finish_test_run("AMSTERDAM GESCHAFFT")

func _begin_roof_crash() -> void:
	if _roof_crash_time_s >= 0.0 or _finished:
		return
	_roof_crash_time_s = 0.0
	_roof_crash_start_durability = wagon.durability
	_roof_crash_start_y = wagon.position.y
	_roof_crash_ground_y = wagon.position.y
	if wagon.vehicle_id == "kombi":
		# Once the wreck is frozen, settle its visible roof onto the road.
		# The generous driving collision box otherwise leaves the art floating.
		var roof_extent: float = maxf(Vector2(-65.0, wagon.KOMBI_ROOF_GRIP_Y).rotated(wagon.rotation).y, Vector2(65.0, wagon.KOMBI_ROOF_GRIP_Y).rotated(wagon.rotation).y)
		_roof_crash_ground_y = course.height_at(wagon.position.x) - roof_extent
	wagon.roof_crash_time_s = 0.0
	if course is AmsterdamPreviewCourse:course.start_wreck_horde()
	wagon.freeze = true
	wagon.linear_velocity = Vector2.ZERO
	wagon.angular_velocity = 0.0
	wagon.boost_active = false
	_touch_fingers.clear()
	_touch_accelerate = false
	_touch_brake = false
	_touch_boost = false
	if _engine_player != null:
		_engine_player.stop()
	_set_status("ÜBERSCHLAGEN – MOTOR RAUCHT", 3.8)

func _finish_test_run(result: String = "ABSCHNITT FERTIG") -> void:
	if _finished:
		return
	_finished = true
	if workshop_rewards_enabled:
		_record_workshop_reward()
	_touch_fingers.clear()
	wagon.freeze = true
	wagon.linear_velocity = Vector2.ZERO
	wagon.angular_velocity = 0.0
	if _engine_player != null:
		_engine_player.stop()
	_set_status(result, 30.0)
	_show_pause_overlay(result)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TestHUD"
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_hud_layer = layer
	var screen := Control.new()
	screen.name = "HUDRoot"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(screen)
	_instruments = preload("res://scripts/driving_instruments.gd").new()
	_instruments.name = "DrivingInstruments"
	_instruments.position = Vector2(20,18)
	_instruments.wagon = wagon
	screen.add_child(_instruments)
	# The route title and distance sit above the skyline, like the reference HUD.
	var center_panel := _make_hud_panel(screen, Rect2(0.0, 15.0, 320.0, 76.0))
	center_panel.anchor_left = 0.5
	center_panel.anchor_right = 0.5
	center_panel.offset_left = -160.0
	center_panel.offset_right = 160.0
	center_panel.color = Color(0.045, 0.075, 0.08, 0.56)
	var city_name: String = course.preview_city_name()
	var city_title := _make_hud_label(center_panel, Vector2(0.0, 5.0), Vector2(320.0, 25.0), "AMSTERDAM" if city_name.is_empty() else city_name.to_upper(), 21, Color8(250, 247, 231))
	city_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_distance_label = _make_hud_label(center_panel, Vector2(0.0, 31.0), Vector2(320.0, 38.0), "0 M", 28, Color8(250, 247, 231))
	_distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Coins and pause remain grouped at the upper-right edge.
	var coins_panel := _make_hud_panel(screen, Rect2(0.0, 18.0, 194.0, 64.0))
	coins_panel.anchor_left = 1.0
	coins_panel.anchor_right = 1.0
	coins_panel.offset_left = -270.0
	coins_panel.offset_right = -68.0
	_coins_label = _make_hud_label(coins_panel, Vector2(10.0, 5.0), Vector2(182.0, 27.0), "◉ 0 MÜNZEN", 17, Color8(250, 230, 184))
	_zombie_hits_label = _make_hud_label(coins_panel, Vector2(10.0, 34.0), Vector2(182.0, 22.0), "ZOMBIE-TREFFER  0", 13, Color8(225, 183, 113))
	var pause_button := _make_hud_button(screen, "Ⅱ", Vector2(0.0, 18.0), Vector2(54.0, 48.0))
	pause_button.anchor_left = 1.0
	pause_button.anchor_right = 1.0
	pause_button.offset_left = -58.0
	pause_button.offset_right = -4.0
	pause_button.pressed.connect(_toggle_pause)
	status_label = Label.new()
	status_label.anchor_left = 0.5
	status_label.anchor_right = 0.5
	status_label.offset_left = -330.0
	status_label.offset_right = 330.0
	status_label.offset_top = 106.0
	status_label.offset_bottom = 138.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color8(241, 220, 176))
	status_label.add_theme_color_override("font_outline_color", Color(0.025, 0.035, 0.03, 0.95))
	status_label.add_theme_constant_override("outline_size", 3)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.visible = false
	screen.add_child(status_label)
	_make_touch_control(screen, "BREMSE", "brake", Vector2(22.0, -118.0), Vector2(152.0, -24.0), 0.0)
	_make_touch_control(screen, "NITRO", "boost", Vector2(-66.0, -118.0), Vector2(66.0, -24.0), 0.5)
	_make_touch_control(screen, "GAS", "accelerate", Vector2(-152.0, -118.0), Vector2(-22.0, -24.0), 1.0)
	_combo_label = _make_hud_label(screen, Vector2(410.0, 145.0), Vector2(460.0, 26.0), "", 17, Color8(255, 210, 117))
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_hint_label = _make_hud_label(screen, Vector2(300.0, 177.0), Vector2(680.0, 30.0), "", 17, Color8(255, 198, 85))
	_action_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_action_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for action_label in [_combo_label, _action_hint_label]:
		action_label.anchor_left = 0.5
		action_label.anchor_right = 0.5
		action_label.add_theme_color_override("font_outline_color", Color8(22, 31, 29))
		action_label.add_theme_constant_override("outline_size", 3)
	_combo_label.offset_left = -230.0
	_combo_label.offset_right = 230.0
	_action_hint_label.offset_left = -340.0
	_action_hint_label.offset_right = 340.0
	_update_hud(false, false, false)

func _update_hud(_accelerate: bool, _brake: bool, _boost: bool) -> void:
	if _instruments == null:
		return
	if _distance_label != null:
		_distance_label.text = "%d M" % int(round(distance_m))
	if _coins_label != null:
		var drive_coins: int = floori(minf(distance_m, _course_length_m()) / 16.0) + _zombie_coins if workshop_rewards_enabled else 0
		_coins_label.text = "◉ %d MÜNZEN" % (_preview_bonus_coins + drive_coins)
	if _action_hint_label != null and _arrival_time_s>=0:
		_action_hint_label.visible=false
	elif _action_hint_label != null:
		_action_hint_label.text = course.action.active_hint(wagon) if course is AmsterdamPreviewCourse and not _finished else ""
		if course is AmsterdamPreviewCourse and not _finished:
			var meter: float = wagon.position.x / PIXELS_PER_METER
			if meter >= course.LOCK_START_M - 75.0 and meter < course.LOCK_LIP_M:
				_action_hint_label.text = "AB 1160 M GAS + NITRO HALTEN · ZIEL %d KM/H" % int(course.LOCK_MIN_SPEED_KMH)
			elif _action_hint_label.text.is_empty():
				_action_hint_label.text = course.explosives.active_hint(wagon)
		if _action_hint_label.text.is_empty() and wagon.durability < 25.0 and not _finished:
			_action_hint_label.text = "MOTOR BESCHÄDIGT · WENIGER ANTRIEB"
		_action_hint_label.visible = not _action_hint_label.text.is_empty()
	if _combo_label != null:
		_combo_label.visible = _combo_left_s > 0.0 and _combo_count > 0
		_combo_label.text = "KOMBO %d · %.1fs · GESAMT +%d" % [_combo_count, _combo_left_s, _combo_coins]
	if _zombie_hits_label != null:
		_zombie_hits_label.text = "ZOMBIE-TREFFER  %d" % (_zombie_coins / 2)
	status_label.visible = false
	if not _run_started and not _finished:
		status_label.visible = true
		status_label.text = "W / ↑ GAS · S / ↓ BREMSE · A/D BALANCE · LEER NITRO"
		status_label.modulate = Color8(255, 244, 211)
	elif _status_time_s > 0.0 and not _finished:
		status_label.visible = true
		status_label.text = _status_text
		var callout_alpha: float = clampf(_status_time_s / 0.22, 0.0, 1.0)
		status_label.modulate = Color(1.0, 0.76, 0.48, callout_alpha)
	elif _finished:
		status_label.visible = true
		status_label.text = _status_text
		status_label.modulate = Color8(255, 218, 153)

func _make_hud_panel(parent: Control, rect: Rect2) -> ColorRect:
	var panel := ColorRect.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.color = Color(0.035, 0.065, 0.065, 0.84)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _make_hud_label(parent: Control, position: Vector2, size: Vector2, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _make_hud_button(parent: Control, text: String, position: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 22)
	for state_name in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.055, 0.085, 0.08, 0.88) if state_name != "pressed" else Color(0.22, 0.16, 0.09, 0.96)
		style.border_color = Color8(222, 188, 125, 230)
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		style.content_margin_left = 7.0
		style.content_margin_right = 7.0
		button.add_theme_stylebox_override(state_name, style)
	button.add_theme_color_override("font_color", Color8(247, 230, 194))
	button.add_theme_color_override("font_hover_color", Color8(255, 249, 226))
	button.add_theme_color_override("font_pressed_color", Color8(255, 220, 151))
	parent.add_child(button)
	return button

func _make_touch_control(parent: Control, text: String, control_name: String, offset_left: Vector2, offset_right: Vector2, horizontal_anchor: float) -> Button:
	var button := Button.new()
	button.text = text
	button.anchor_left = horizontal_anchor
	button.anchor_right = horizontal_anchor
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = offset_left.x
	button.offset_right = offset_right.x
	button.offset_top = offset_left.y
	button.offset_bottom = offset_right.y
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 15)
	for state_name in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.045, 0.07, 0.065, 0.64) if state_name != "pressed" else Color(0.70, 0.43, 0.17, 0.88)
		style.border_color = Color(0.91, 0.84, 0.67, 0.72)
		style.set_border_width_all(3)
		style.set_corner_radius_all(42)
		button.add_theme_stylebox_override(state_name, style)
	button.add_theme_color_override("font_color", Color(1.0, 0.96, 0.84, 0.9))
	button.button_down.connect(_on_touch_button_down.bind(control_name))
	button.button_up.connect(_on_touch_button_up.bind(control_name))
	parent.add_child(button)
	_touch_buttons[control_name] = button
	return button

func _input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch:
		return
	var touch := event as InputEventScreenTouch
	if not touch.pressed:
		if _touch_fingers.has(touch.index):
			var released: String = _touch_fingers[touch.index]
			_touch_fingers.erase(touch.index)
			if not _touch_fingers.values().has(released):
				_match_touch_control(released, false)
			get_viewport().set_input_as_handled()
		return
	if _paused or _finished:
		return
	for control_name: String in _touch_buttons:
		var button: Button = _touch_buttons[control_name]
		if button.is_visible_in_tree() and button.get_global_rect().has_point(touch.position):
			_touch_fingers[touch.index] = control_name
			_match_touch_control(control_name, true)
			get_viewport().set_input_as_handled()
			return

func _on_touch_button_down(control_name: String) -> void:
	_match_touch_control(control_name, true)

func _on_touch_button_up(control_name: String) -> void:
	if not _touch_fingers.values().has(control_name):
		_match_touch_control(control_name, false)

func _match_touch_control(control_name: String, is_pressed: bool) -> void:
	if is_pressed:
		# A quick tap can begin and end between physics ticks. Keep a tiny input
		# pulse so mouse and touchscreen taps still register as a deliberate command.
		match control_name:
			"accelerate": _touch_accelerate_pulse_s = 0.16
			"brake": _touch_brake_pulse_s = 0.12
			"boost": _touch_boost_pulse_s = 0.12
	match control_name:
		"accelerate": _touch_accelerate = is_pressed
		"brake": _touch_brake = is_pressed
		"boost": _touch_boost = is_pressed

func _toggle_pause() -> void:
	if _finished:
		return
	_paused = not _paused
	if _paused:
		_touch_fingers.clear()
		_touch_accelerate = false
		_touch_brake = false
		_touch_boost = false
		_touch_accelerate_pulse_s = 0.0
		_touch_brake_pulse_s = 0.0
		_touch_boost_pulse_s = 0.0
		wagon.freeze = true
		course.set_physics_process(false)
		var backdrop_view: Node = get_node_or_null("Backdrop/BackdropView")
		if backdrop_view != null:
			backdrop_view.set_process(false)
		if _engine_player != null:
			_engine_player.stream_paused = true
		_show_pause_overlay()
	else:
		course.set_physics_process(true)
		var backdrop_view: Node = get_node_or_null("Backdrop/BackdropView")
		if backdrop_view != null:
			backdrop_view.set_process(true)
		wagon.freeze = _roof_crash_time_s >= 0.0 or _water_crash_time_s >= 0.0 or (course is AmsterdamPreviewCourse and course.lock_flight_active) or not _run_started
		if _engine_player != null:
			_engine_player.stream_paused = false
		if is_instance_valid(_pause_overlay):
			_pause_overlay.queue_free()
		_pause_overlay = null

func _show_pause_overlay(title_text: String = "PAUSE") -> void:
	if _hud_layer == null or is_instance_valid(_pause_overlay):
		return
	if _finished and _arrival_time_s>=0:
		_show_arrival_result()
		return
	_pause_overlay = Control.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_hud_layer.add_child(_pause_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.035, 0.032, 0.68)
	_pause_overlay.add_child(shade)
	var panel := _make_hud_panel(_pause_overlay, Rect2(-260.0, -124.0, 520.0, 248.0))
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260.0
	panel.offset_right = 260.0
	panel.offset_top = -124.0
	panel.offset_bottom = 124.0
	var title := _make_hud_label(panel, Vector2(0.0, 12.0), Vector2(520.0, 44.0), title_text, 26, Color8(250, 230, 184))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _finished:
		var summary := _make_hud_label(panel, Vector2(0.0, 54.0), Vector2(520.0, 28.0), "%.0f m  ·  %.1f s  ·  %d Zombies" % [minf(distance_m, _course_length_m()), elapsed_s, _zombie_coins / 2], 18, Color8(247, 230, 194))
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if not _reward_message.is_empty():
			var rewards := _make_hud_label(panel, Vector2(4.0, 84.0), Vector2(512.0, 48.0), _reward_message, 15, Color8(247, 230, 194))
			rewards.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		elif _preview_bonus_coins > 0:
			var bonus := _make_hud_label(panel, Vector2(4.0, 84.0), Vector2(512.0, 36.0), "Aktionsbonus  ·  +%d Münzen" % _preview_bonus_coins, 15, Color8(247, 230, 194))
			bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		var resume := _make_hud_button(panel, "WEITERFAHREN", Vector2(98.0, 78.0), Vector2(324.0, 52.0))
		resume.pressed.connect(_toggle_pause)
	var restart := _make_hud_button(panel, "NEUSTART", Vector2(98.0, 142.0), Vector2(324.0, 52.0))
	restart.pressed.connect(_start_test_run)
	var profile_label: String = _test_profile_label()
	if not profile_label.is_empty() and title_text != "GAME OVER":
		var profile := _make_hud_button(panel, profile_label, Vector2(98.0, 201.0), Vector2(324.0, 42.0))
		profile.pressed.connect(_toggle_test_profile)
	else:
		var workshop := _make_hud_button(panel, "ZUR WERKSTATT", Vector2(98.0, 201.0), Vector2(324.0, 42.0))
		workshop.pressed.connect(_return_to_workshop)

func _show_arrival_result() -> void:
	_pause_overlay=Control.new()
	_pause_overlay.name="ArrivalResult"
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	_hud_layer.add_child(_pause_overlay)
	var shade:=ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color=Color(.015,.025,.03,.78)
	_pause_overlay.add_child(shade)
	var panel:=Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left=-286;panel.offset_right=286;panel.offset_top=-207;panel.offset_bottom=207
	var frame:=StyleBoxFlat.new()
	frame.bg_color=Color("152628");frame.border_color=Color("b39763");frame.set_border_width_all(2);frame.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel",frame)
	_pause_overlay.add_child(panel)
	var title:=_make_hud_label(panel,Vector2(18,20),Vector2(536,42),"AMSTERDAM GESCHAFFT",29,Color("f1dca9"))
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var info:=_make_hud_label(panel,Vector2(18,66),Vector2(536,28),"HAFENAUSFAHRT  ·  1.800 M  ·  %.1f SEKUNDEN" % elapsed_s,15,Color("acbdb4"))
	info.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var distance_coins:int=floori(_course_length_m()/16)
	var total:int=distance_coins+_zombie_coins+_preview_bonus_coins
	var categories:Array[String]=["STRECKE","ZOMBIES","AKTIONEN"]
	var values:Array[int]=[distance_coins,_zombie_coins,_preview_bonus_coins]
	for i in range(3):
		var x:float=24+i*177
		var cell:=ColorRect.new();cell.position=Vector2(x,111);cell.size=Vector2(169,74);cell.color=Color("203639");panel.add_child(cell)
		var label:=_make_hud_label(cell,Vector2(0,10),Vector2(169,22),categories[i],12,Color("a9bbb0"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var value:=_make_hud_label(cell,Vector2(0,33),Vector2(169,33),"+%d" % values[i],24,Color("efd79f"));value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var income:=_make_hud_label(panel,Vector2(24,198),Vector2(524,38),"VERDIENT: %d MÜNZEN" % total,24,Color("edba65"));income.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var bank:String="Vorschaufahrt · Münzen nicht gespeichert"
	if workshop_rewards_enabled:bank="Guthaben: %d Münzen" % _arrival_balance if _arrival_balance>=0 else "Speichern fehlgeschlagen · bitte nicht schließen"
	var bank_label:=_make_hud_label(panel,Vector2(24,240),Vector2(524,25),bank,15,Color("b5c7b8"));bank_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var hint:=_make_hud_label(panel,Vector2(24,270),Vector2(524,34),_arrival_upgrade_hint,14,Color("d0c4a7"));hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var garage:=_make_hud_button(panel,"ZUR WERKSTATT",Vector2(24,334),Vector2(302,54));garage.pressed.connect(_return_to_workshop)
	var replay:=_make_hud_button(panel,"NOCHMAL FAHREN",Vector2(338,334),Vector2(210,54));replay.pressed.connect(_start_test_run)

func _return_to_workshop() -> void:
	var workshop: Node = load("res://scenes/main.tscn").instantiate()
	workshop.set("skip_main_menu_on_launch", true)
	if workshop_stock_test:
		workshop.set("resume_stock_test_upgrades", workshop_upgrades.duplicate(true))
	get_tree().change_scene_to_node(workshop)

func _set_status(text: String, duration_s: float = 0.85) -> void:
	_status_text = text
	_status_time_s = duration_s
	if status_label != null:
		status_label.text = text
		status_label.modulate = Color8(255, 194, 123)

func _course_length_m() -> float:
	return float(course.call("preview_length_m")) if course.has_method("preview_length_m") else TEST_COURSE_LENGTH_M

func _update_action_tracking(delta: float, brake: bool) -> void:
	_combo_left_s = maxf(0.0, _combo_left_s - delta)
	if _combo_left_s <= 0.0:
		_combo_count = 0
	if course is AmsterdamPreviewCourse:
		course.action.update_action(delta, wagon, brake)
	if wagon.airborne:
		if not _jump_active:
			_jump_active = true
			_jump_start_x = wagon.position.x
			_jump_age_s = 0.0
			_jump_max_clearance = 0.0
		_jump_age_s += delta
		_jump_max_clearance = maxf(_jump_max_clearance, course.height_at(wagon.position.x) - wagon.position.y - 45.0)

func _check_clean_landing(impact_speed: float) -> void:
	if not _jump_active:
		return
	var travel: float = wagon.position.x - _jump_start_x
	var clean: bool = _jump_age_s >= 0.35 and travel >= 4.0 * PIXELS_PER_METER and _jump_max_clearance >= 25.0 and absf(wrapf(wagon.rotation - course.slope_at(wagon.position.x), -PI, PI)) < 0.30 and impact_speed < 9.0 * PIXELS_PER_METER
	_jump_active = false
	if clean and wagon.position.x > _jump_last_reward_x + 12.0 * PIXELS_PER_METER:
		_jump_last_reward_x = wagon.position.x
		_preview_bonus_coins += 5
		_combo_event("SAUBERER SPRUNG")
		_set_status("SAUBERER SPRUNG · +5 MÜNZEN", 1.2)
	elif impact_speed > 12.0 * PIXELS_PER_METER:
		_break_combo()

func _combo_event(_kind: String) -> void:
	if _finished or _paused:
		return
	_combo_count = mini(8, _combo_count + 1) if _combo_left_s > 0.0 else 1
	_combo_left_s = 4.5
	if _combo_count >= 2:
		var coins: int = mini(6, _combo_count - 1)
		_combo_coins += coins
		_preview_bonus_coins += coins
		if _pickup_player != null:
			_pickup_player.play()

func _break_combo() -> void:
	_combo_count = 0
	_combo_left_s = 0.0

func _on_zombies_shaken(count: int) -> void:
	if _finished or _paused:
		return
	_set_status("%d ZOMBIE(S) ABGESCHÜTTELT · FREIE FAHRT" % count, 1.4)

func _on_crane_hit() -> void:
	_break_combo()
	if _impact_player != null:
		_impact_player.pitch_scale = 1.0
		_impact_player.play()



func _on_drum_exploded(zombies: int, chain: bool) -> void:
	if _finished or _paused:
		return
	for hit in range(zombies):
		_zombie_coins += 2
		_combo_event("EXPLOSIONSTREFFER")
	_blast_shake_s = 0.18
	if _impact_player != null:
		_impact_player.pitch_scale = 0.65
		_impact_player.play()
	_set_status(("KETTENREAKTION" if chain else "TREIBSTOFFFASS EXPLODIERT") + (" · %d ZOMBIES ERWISCHT" % zombies if zombies > 0 else " · ABSTAND HALTEN"), 1.3)


func _on_structure_blast(strength: float) -> void:
	_blast_shake_s = maxf(_blast_shake_s, strength)
	if _impact_player != null:
		_impact_player.pitch_scale = 0.56
		_impact_player.play()

func _on_structure_passed(amount: int) -> void:
	_preview_bonus_coins += amount
	_set_status("EINSTURZ SAUBER PASSIERT · +%d MÜNZEN" % amount, 2.0)