extends Node2D

const SAVE_PATH: String = "user://progress.cfg"
const SAVE_TEMP_PATH: String = "user://progress.cfg.tmp"
const SAVE_BACKUP_PATH: String = "user://progress.cfg.bak"
const SAVE_CORRUPT_PATH: String = "user://progress.cfg.corrupt"
const SAVE_INTEGRITY_SECTION: String = "zz_save_integrity"
const SAVE_INTEGRITY_MARKER: String = "ZEE_SAVE_COMPLETE_V1"
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const QA_DIAGNOSTICS = preload("res://scripts/qa_diagnostics.gd")
const CHALLENGE_DATA = preload("res://scripts/challenge_data.gd")
const STORY_DATA = preload("res://scripts/story_data.gd")
const ZOMBIE_DATA = preload("res://scripts/zombie_data.gd")
const PIXELS_PER_METER: float = CAMPAIGN_DATA.PIXELS_PER_METER
const START_OFFSET_M: float = CAMPAIGN_DATA.WORLD_START_OFFSET_M
const ROUTE_LENGTH_M: float = CAMPAIGN_DATA.ROUTE_LENGTH_M
const GARAGE_CAMERA_ZOOM: float = 2.42
const PROGRESS_SAVE_INTERVAL_S: float = 6.0
const DEFAULT_MASTER_VOLUME: float = 0.8
const DEFAULT_MUSIC_VOLUME: float = 1.0
const DEFAULT_HAPTIC_STRENGTH: float = 0.65
const FIRST_DRIVE_TUTORIAL_SCHEMA: int = 8
const CAMPAIGN_SAVE_SCHEMA: int = 12
# Completion markers have been mandatory since schema 10, independently of campaign revisions.
const TRANSACTIONAL_SAVE_SCHEMA: int = 10
const TUNING_TRIAL_RESET_REVISION: int = 2
const ANDROID_BACK_DEBOUNCE_MS: int = 1000
const ENDING_SEQUENCE_DURATION_S: float = 12.0
const FAILURE_COAST_MIN_S: float = 2.4
const FAILURE_COAST_MAX_S: float = 12.0
const FAILURE_COAST_STOP_SPEED_KMH: float = 5.0
const CHECKPOINT_FUEL_SUPPLY: float = 12.0
const CHECKPOINT_NITRO_SUPPLY: float = 25.0
const CHECKPOINT_REPAIR_SUPPLY: float = 15.0
const PLAYABLE_WORLD_COUNT: int = CAMPAIGN_DATA.PLAYABLE_WORLD_COUNT

const UPGRADE_COSTS: Dictionary = {
	"engine": [55, 95, 155],
	"tires": [45, 80, 135],
	"tank": [40, 75, 120],
	"armor": [35, 70, 115],
	"suspension": [50, 95, 155],
	"efficiency": [45, 85, 140],
	"brakes": [40, 80, 130],
	"nitro": [45, 70, 100],
	"weapon": [650]
}
const UPGRADE_MAX: Dictionary = {"engine": 3, "tires": 3, "tank": 3, "armor": 3, "suspension": 3, "efficiency": 3, "brakes": 3, "nitro": 3, "weapon": 1}
const UPGRADE_PARTS: Array[String] = ["engine", "tires", "tank", "armor", "suspension", "efficiency", "brakes", "nitro", "weapon"]
const CORE_VEHICLE_UPGRADES: Array[String] = ["engine", "tires", "tank", "armor", "nitro"]
const PISTOL_FIRE_INTERVAL_S: float = 0.24
const PISTOL_RANGE_M: float = 5.5

@onready var terrain: EscapeTerrain = get_node("Terrain")
@onready var wagon: EscapeWagon = get_node("Wagon")
@onready var camera: Camera2D = get_node("Camera2D")
@onready var audio_manager: Node = get_node("AudioManager")
@onready var backdrop: Node = get_node("Backdrop/BackdropView")

var screen_state: String = "GARAGE"
var skip_main_menu_on_launch: bool = false
var map_return_to_menu: bool = false
var paused: bool = false
var campaign_meter: float = 0.0
var selected_world_index: int = 0
var unlocked_world_index: int = 0
var run_world_index: int = 0
var world_best_distances: Array[float] = []
var world_completed_flags: Array[bool] = []
var world_challenge_completed: Array[bool] = []
var active_checkpoints: Array[Dictionary] = []
var final_rescue_unlocked: bool = false
var final_rescue_completed: bool = false
var final_rescue_challenge_completed: bool = false
var ending_sequence_seen: bool = false
var ending_elapsed: float = 0.0
var run_is_final_rescue: bool = false
var run_attempt_id: int = 0
var rewarded_bonus_run_ids: Dictionary = {}
var money: int = 100
var master_volume: float = DEFAULT_MASTER_VOLUME
var music_volume: float = DEFAULT_MUSIC_VOLUME
var haptic_strength: float = DEFAULT_HAPTIC_STRENGTH
var first_drive_tutorial_completed: bool = false
var collected_story_logs: Array[bool] = []
var archive_selected_log_index: int = 0
var archive_return_state: String = "GARAGE"
var run_story_log_collected: bool = false
var _last_android_back_request_msec: int = -ANDROID_BACK_DEBOUNCE_MS
var upgrades: Dictionary = {"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0, "weapon": 0}
var resume_stock_test_upgrades: Dictionary = {}
var stock_test_mode: bool = false
var tuning_trial_mode: bool = false
var tuning_trial_seen: bool = false
var _stock_test_saved_upgrades: Dictionary = {}
var _stock_test_saved_vehicle: String = ""
var _stock_test_saved_money: int = -1
var _pistol_fire_cooldown_s: float = 0.0
var vehicle_upgrades: Dictionary = {
	"kombi": {"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0, "weapon": 0},
	"lieferwagen": {"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0, "weapon": 0},
	"offroad_pickup": {"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0, "weapon": 0}
}
var selected_vehicle: String = "kombi"
var unlocked_vehicles: Array[String] = ["kombi"]
var run_start_meter: float = 0.0
var last_resolved_meter: float = 0.0
var run_zombie_reward: int = 0
var run_collectible_reward: int = 0
var run_distance: float = 0.0
var run_reward: int = 0
var run_checkpoint_reward: int = 0
var run_challenge_reward: int = 0
var run_challenge_success: bool = false
var run_zombie_contacts: int = 0
var run_repair_pickups: int = 0
var run_hazard_passed: bool = false
var run_hazard_hits: int = 0
var run_peak_speed_kmh: float = 0.0
var failure_coast_elapsed_s: float = 0.0
var vehicle_unlocked_this_run: bool = false
var unlocked_vehicle_names_this_run: Array[String] = []
var next_checkpoint_index: int = 0
var toast_text: String = ""
var toast_time: float = 0.0
var progress_save_timer: float = 0.0
var _save_generation: int = 0
var _last_progress_load_source: String = "defaults"
var _last_drive_report_msec: int = -1
var _last_state_report_msec: int = -1
var _last_landing_haptic_msec: int = -1000
var _camera_shake_time: float = 0.0
var _camera_shake_duration: float = 0.0
var _camera_shake_strength: float = 0.0
var _camera_shake_phase: float = 0.0
var _boost_was_active: bool = false
var route_length_m: float = ROUTE_LENGTH_M
var touch_actions: Dictionary = {"accelerate": false, "brake": false, "boost": false, "tilt_left": false, "tilt_right": false}
var mobile_target: bool = false
@export var show_mobile_controls_in_editor: bool = false

func _ready() -> void:
	if OS.get_environment("ZEE_AMSTERDAM_PREVIEW") == "1" or "--amsterdam-preview" in OS.get_cmdline_user_args() or "--amsterdam-preview" in OS.get_cmdline_args():
		call_deferred("_start_amsterdam_preview")
		return
	if "--driving-test" in OS.get_cmdline_user_args() or "--driving-test" in OS.get_cmdline_args():
		call_deferred("_start_pc_driving_test")
		return
	mobile_target = show_mobile_controls_in_editor or OS.has_feature("android") or OS.has_feature("ios")
	wagon.landed.connect(_on_wagon_landed)
	_initialize_world_progress()
	_load_progress()
	# Keep authored routes selectable for this test build.
	var saved_selected_world_index: int = selected_world_index
	unlocked_world_index = maxi(unlocked_world_index, PLAYABLE_WORLD_COUNT - 1)
	selected_world_index = clampi(selected_world_index, 0, PLAYABLE_WORLD_COUNT - 1)
	campaign_meter = 0.0 if world_completed_flags[selected_world_index] else clampf(world_best_distances[selected_world_index], 0.0, float(CAMPAIGN_DATA.CAMPAIGN_WORLDS[selected_world_index].get("length_m", ROUTE_LENGTH_M)))
	if QA_DIAGNOSTICS.enabled():
		print("[PERF] loaded_progress_m=%.2f world=%d" % [campaign_meter, selected_world_index])
		print("[AUDIO_SETTINGS_QA] loaded_music_volume=%.2f" % music_volume)
	_apply_master_volume()
	_configure_selected_world()
	wagon.configure(upgrades, selected_vehicle)
	terrain.reset_entities(campaign_meter)
	wagon.reset_at((campaign_meter + START_OFFSET_M) * PIXELS_PER_METER, terrain)
	last_resolved_meter = campaign_meter
	_set_camera(1.0, true)
	if not resume_stock_test_upgrades.is_empty() and can_test_stock_vehicle():
		_activate_stock_test_mode(resume_stock_test_upgrades)
	if not skip_main_menu_on_launch:
		call_deferred("_show_launch_menu")
	if QA_DIAGNOSTICS.enabled():
		print("[PERF] game_ready_ms=%d screen=%s" % [Time.get_ticks_msec(), screen_state])
	if selected_world_index != saved_selected_world_index:
		_save_progress()

func _start_pc_driving_test() -> void:
	get_tree().change_scene_to_file("res://scenes/driving_test.tscn")

func _show_launch_menu() -> void:
	if get_tree().current_scene == self and screen_state == "GARAGE":
		open_main_menu()

func open_main_menu() -> void:
	screen_state = "MENU"
	map_return_to_menu = false
	_set_camera(1.0, true)
	backdrop.queue_redraw()
	_play_audio("ui")

func close_world_map() -> void:
	if map_return_to_menu:
		open_main_menu()
	else:
		to_garage()

func _start_amsterdam_preview() -> void:
	get_tree().change_scene_to_file("res://scenes/amsterdam_preview.tscn")

func _process(delta: float) -> void:
	if screen_state == "ENDING":
		ending_elapsed = minf(ENDING_SEQUENCE_DURATION_S, ending_elapsed + delta)
		if ending_elapsed >= ENDING_SEQUENCE_DURATION_S:
			finish_ending_sequence()
		else:
			var ending_hud: CanvasItem = get_node_or_null("HUDLayer/HUD") as CanvasItem
			if ending_hud != null:
				ending_hud.queue_redraw()
	if QA_DIAGNOSTICS.enabled() and screen_state == "RUN":
		var now_msec: int = Time.get_ticks_msec()
		if _last_state_report_msec < 0:
			_last_state_report_msec = now_msec
		var wall_elapsed_msec: int = now_msec - _last_state_report_msec
		if wall_elapsed_msec >= 1000:
			_last_state_report_msec = now_msec
			print("[PERF] frame wall_delta=%.3fs engine_delta=%.3fs fps=%d process_ms=%.2f physics_ms=%.2f draw_calls=%d screen=%s paused=%s gas_touch=%s speed_x=%.1fkmh route=%.1fm fuel=%.1f frozen=%s" % [
				float(wall_elapsed_msec) / 1000.0,
				delta,
				Engine.get_frames_per_second(),
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				screen_state,
				paused,
				str(bool(touch_actions["accelerate"])),
				wagon.speed_mps * 3.6,
				_meter_at(wagon.position.x),
				wagon.fuel,
				str(wagon.freeze)
			])
	else:
		_last_state_report_msec = -1
	if toast_time > 0.0:
		toast_time = maxf(0.0, toast_time - delta)
	if screen_state == "RUN" and not paused:
		progress_save_timer += delta
		if progress_save_timer >= PROGRESS_SAVE_INTERVAL_S:
			progress_save_timer = 0.0
			_save_progress()
	_set_camera(delta)
	_update_camera_shake(delta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var now_msec: int = Time.get_ticks_msec()
		if now_msec - _last_android_back_request_msec < ANDROID_BACK_DEBOUNCE_MS:
			if QA_DIAGNOSTICS.enabled():
				print("[PERF] android_back_action=debounced screen=%s paused=%s delta_ms=%d" % [screen_state, paused, now_msec - _last_android_back_request_msec])
			return
		_last_android_back_request_msec = now_msec
		_clear_hud_touch_state()
		var hud: Node = get_node_or_null("HUDLayer/HUD")
		if hud != null and hud.has_method("handle_system_back") and bool(hud.call("handle_system_back")):
			if QA_DIAGNOSTICS.enabled():
				print("[PERF] android_back_action=overlay screen=%s" % screen_state)
			return
		var back_action: String = "quit"
		match screen_state:
			"ENDING":
				finish_ending_sequence()
				back_action = "ending_skip"
			"ARCHIVE":
				close_radio_archive()
				back_action = "archive_close"
			"RUN":
				if paused:
					to_garage()
					back_action = "garage"
				else:
					set_paused(true)
					back_action = "pause"
			"MAP":
				close_world_map()
				back_action = "map_close"
			"RESULT", "LEVEL_COMPLETE", "WIN":
				to_garage()
				back_action = "garage"
			"GARAGE":
				open_main_menu()
				back_action = "menu"
			"MENU":
				_save_progress()
				get_tree().quit()
		if QA_DIAGNOSTICS.enabled():
			print("[PERF] android_back_action=%s screen=%s paused=%s" % [back_action, screen_state, paused])
		return
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_clear_hud_touch_state()
		var pause_when_backgrounded: bool = OS.has_feature("android") or OS.has_feature("ios")
		if pause_when_backgrounded and screen_state == "RUN" and not paused:
			set_paused(true, false)
		else:
			_save_progress()

func _clear_hud_touch_state() -> void:
	clear_touch_actions()
	var hud: Node = get_node_or_null("HUDLayer/HUD")
	if hud != null and hud.has_method("clear_active_touches"):
		hud.call("clear_active_touches")

func _physics_process(delta: float) -> void:
	if screen_state == "RUN" and not paused:
		var accelerate: bool = Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or bool(touch_actions["accelerate"])
		var brake: bool = Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or bool(touch_actions["brake"])
		var balance: float = float(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or bool(touch_actions["tilt_right"])) - float(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or bool(touch_actions["tilt_left"]))
		var boost: bool = Input.is_key_pressed(KEY_SPACE) or bool(touch_actions["boost"])
		var road_angle: float = terrain.slope_at(wagon.position.x)
		wagon.simulate(delta, accelerate, brake, boost, balance, road_angle, terrain.height_at(wagon.position.x))
		_update_campaign_pistol(delta)
		wagon.update_overturn_state(delta, terrain.height_at(wagon.position.x), road_angle)
		terrain.set_zombie_chase_target_x(wagon.position.x + wagon.front_contact_offset_px(), delta)
		if wagon.boost_active and not _boost_was_active:
			_trigger_camera_shake(4.0, 0.26)
			terrain.spawn_event_feedback(wagon.position.x - 86.0, wagon.position.y + 17.0, "boost", 0.85)
		_boost_was_active = wagon.boost_active
		run_peak_speed_kmh = maxf(run_peak_speed_kmh, absf(wagon.speed_mps) * 3.6)
		if QA_DIAGNOSTICS.enabled() and accelerate:
			var now_msec: int = Time.get_ticks_msec()
			if _last_drive_report_msec < 0:
				_last_drive_report_msec = now_msec
			var wall_elapsed_msec: int = now_msec - _last_drive_report_msec
			if wall_elapsed_msec >= 1000:
				_last_drive_report_msec = now_msec
				print("[PERF] drive wall_delta=%.3fs speed_mps=%.2f route_m=%.1f fuel=%.1f paused=%s frozen=%s" % [
					float(wall_elapsed_msec) / 1000.0,
					wagon.speed_mps,
					_meter_at(wagon.position.x),
					wagon.fuel,
					paused,
					wagon.freeze
				])
		else:
			_last_drive_report_msec = -1
		var current_meter: float = _meter_at(wagon.position.x)
		_resolve_checkpoints(last_resolved_meter, current_meter)
		_resolve_entities(last_resolved_meter, current_meter, wagon.front_contact_offset_m())
		last_resolved_meter = maxf(last_resolved_meter, current_meter)
		run_distance = maxf(0.0, current_meter - run_start_meter)
		if current_meter >= route_length_m:
			_finish_run(true)
		elif wagon.overturned:
			_set_toast("Kombi liegt auf dem Dach · Fahrt beendet.")
			_finish_run(false)
		elif wagon.fuel <= 0.0 or wagon.durability <= 0.0:
			if failure_coast_elapsed_s <= 0.0:
				_set_toast("TANK LEER · KOMBI ROLLT AUS" if wagon.fuel <= 0.0 else "KOMBI DEFEKT · ROLLT NOCH AUS")
			failure_coast_elapsed_s += delta
			var stopped_speed_kmh: float = absf(wagon.speed_mps) * 3.6
			if failure_coast_elapsed_s >= FAILURE_COAST_MAX_S or (failure_coast_elapsed_s >= FAILURE_COAST_MIN_S and stopped_speed_kmh <= FAILURE_COAST_STOP_SPEED_KMH):
				_set_toast("FAHRT BEENDET · KOMBI AUSGEROLLT")
				_finish_run(false)
		else:
			failure_coast_elapsed_s = 0.0
	else:
		_boost_was_active = false

func _update_campaign_pistol(delta: float) -> void:
	# The currently playable Amsterdam route supports the Kombi's purchased hood gun.
	if run_world_index != 0 or wagon.weapon_level <= 0 or selected_vehicle != "kombi":
		_pistol_fire_cooldown_s = 0.0
		return
	_pistol_fire_cooldown_s = maxf(0.0, _pistol_fire_cooldown_s - delta)
	if _pistol_fire_cooldown_s > 0.0:
		return
	var car_front_x: float = wagon.position.x + wagon.front_contact_offset_px()
	var target_entity: Dictionary = {}
	var nearest_distance_m: float = PISTOL_RANGE_M
	for entity in terrain.entities:
		if bool(entity.get("done", false)) or String(entity.get("kind", "")) != "zombie":
			continue
		var authored_x: float = float(entity["draw_world_x"]) if entity.has("draw_world_x") else terrain.route_meter_to_world_x(float(entity.get("meter", 0.0)))
		var current_x: float = authored_x - float(entity.get("chase_offset_px", 0.0))
		var distance_m: float = (current_x - car_front_x) / wagon.PIXELS_PER_METER
		if distance_m < 1.0 or distance_m > nearest_distance_m:
			continue
		nearest_distance_m = distance_m
		target_entity = entity
	if target_entity.is_empty():
		return
	_pistol_fire_cooldown_s = PISTOL_FIRE_INTERVAL_S
	var target_x: float = float(target_entity["draw_world_x"]) if target_entity.has("draw_world_x") else terrain.route_meter_to_world_x(float(target_entity.get("meter", 0.0)))
	target_x -= float(target_entity.get("chase_offset_px", 0.0))
	var target_y: float = terrain.height_at(target_x) - 24.0
	wagon.show_weapon_shot(Vector2(target_x, target_y))
	terrain.spawn_event_feedback(target_x, target_y, "weapon", 0.46)
	var variant_id: int = clampi(int(target_entity.get("variant_id", 1)), 1, 5)
	var shots_per_zombie: int = _pistol_shots_to_drop_zombie(variant_id)
	var original_group_size: int = maxi(1, int(target_entity.get("weapon_original_group_size", target_entity.get("group_size", 1))))
	target_entity["weapon_original_group_size"] = original_group_size
	if not target_entity.has("reward_remaining"):
		target_entity["reward_remaining"] = int(target_entity.get("reward", 9))
	var hits_on_member: int = int(target_entity.get("weapon_hits_on_member", 0)) + 1
	if hits_on_member >= shots_per_zombie:
		hits_on_member = 0
		terrain.spawn_shot_zombie_reaction(target_x, terrain.height_at(target_x), variant_id)
		var remaining_group: int = maxi(0, int(target_entity.get("group_size", 1)) - 1)
		var member_reward: int = maxi(1, int(ceil(float(target_entity.get("reward", 9)) / float(original_group_size))))
		var reward_given: int = mini(member_reward, int(target_entity.get("reward_remaining", 0)))
		target_entity["reward_remaining"] = maxi(0, int(target_entity.get("reward_remaining", 0)) - reward_given)
		run_zombie_reward += reward_given
		if remaining_group <= 0:
			target_entity["group_size"] = 1
			target_entity["done"] = true
			_set_toast("PISTOLEN-TREFFER · HORDE VOR DEM KOMBI AUSGEDÜNNT")
		else:
			target_entity["group_size"] = remaining_group
			_set_toast("ZOMBIE ABGESCHOSSEN · NOCH %d IN DER GRUPPE" % remaining_group)
	else:
		target_entity["weapon_hits_on_member"] = hits_on_member
	terrain.queue_redraw()

func _pistol_shots_to_drop_zombie(variant_id: int) -> int:
	match variant_id:
		2:
			return 1
		3:
			return 4
		4:
			return 3
		5:
			return 6
		_:
			return 2

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if screen_state == "ENDING" and event.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		finish_ending_sequence()
		return
	if is_first_drive_tutorial_active():
		if event.keycode == KEY_ESCAPE:
			complete_first_drive_tutorial()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_node("HUDLayer/HUD").call("advance_first_drive_tutorial")
		return
	if screen_state == "ARCHIVE" and event.keycode in [KEY_ESCAPE, KEY_M, KEY_ENTER, KEY_KP_ENTER]:
		close_radio_archive()
		return
	if event.keycode == KEY_ESCAPE:
		if screen_state == "RUN":
			toggle_pause()
		elif screen_state == "MENU" and bool(get_node("HUDLayer/HUD").call("handle_system_back")):
			return
		elif screen_state == "MAP":
			close_world_map()
		elif screen_state == "GARAGE":
			open_main_menu()
		return
	if event.keycode == KEY_R and screen_state == "WIN":
		restart_campaign()
		return
	if event.keycode == KEY_M and screen_state in ["MENU", "GARAGE"]:
		open_world_map()
		return
	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		if screen_state == "MENU":
			to_garage()
		elif screen_state == "GARAGE":
			start_run()
		elif screen_state == "MAP":
			close_world_map()
		elif screen_state == "RESULT" or screen_state == "WIN":
			to_garage()

func start_run() -> void:
	if screen_state != "GARAGE" or (not first_drive_tutorial_completed and not stock_test_mode):
		return
	var route := world_data()
	var scene_path := String(route.get("drive_scene", ""))
	if not scene_path.is_empty():
		var preview := load(scene_path) as PackedScene
		if preview == null:
			_set_toast("STRECKE KONNTE NICHT GELADEN WERDEN")
			return
		var drive := preview.instantiate()
		drive.set("workshop_vehicle", selected_vehicle)
		drive.set("workshop_upgrades", upgrades.duplicate(true))
		drive.set("workshop_rewards_enabled", not stock_test_mode)
		drive.set("workshop_stock_test", stock_test_mode)
		drive.set("workshop_world_id", String(route.get("id", "")))
		get_tree().call_deferred("change_scene_to_node", drive)
		return
	_begin_run(false)

func is_first_drive_tutorial_active() -> bool:
	return screen_state == "GARAGE" and not first_drive_tutorial_completed and not stock_test_mode

func complete_first_drive_tutorial() -> void:
	if first_drive_tutorial_completed:
		return
	first_drive_tutorial_completed = true
	_save_progress()
	get_node("HUDLayer/HUD").queue_redraw()

func start_final_rescue() -> void:
	# The southern rescue route is outside the current two-level build.
	return

func _begin_run(is_final_rescue: bool) -> void:
	if is_final_rescue or selected_world_index < 0 or selected_world_index >= PLAYABLE_WORLD_COUNT:
		return
	run_attempt_id += 1
	run_is_final_rescue = false
	run_world_index = selected_world_index
	_configure_selected_world()
	terrain.set_story_log_available(not is_story_log_collected(0))
	if world_completed_flags[selected_world_index]:
		campaign_meter = 0.0
	clear_touch_actions()
	_reset_camera_shake()
	_last_state_report_msec = Time.get_ticks_msec()
	_last_drive_report_msec = -1
	paused = false
	run_start_meter = campaign_meter
	run_distance = 0.0
	run_zombie_reward = 0
	run_collectible_reward = 0
	run_reward = 0
	run_checkpoint_reward = 0
	run_challenge_reward = 0
	run_challenge_success = false
	run_zombie_contacts = 0
	run_repair_pickups = 0
	run_hazard_passed = false
	run_hazard_hits = 0
	run_peak_speed_kmh = 0.0
	failure_coast_elapsed_s = 0.0
	_pistol_fire_cooldown_s = 0.0
	run_story_log_collected = false
	vehicle_unlocked_this_run = false
	unlocked_vehicle_names_this_run.clear()
	next_checkpoint_index = _next_checkpoint_index(campaign_meter)
	wagon.configure(upgrades, selected_vehicle)
	wagon.reset_at((campaign_meter + START_OFFSET_M) * PIXELS_PER_METER, terrain)
	terrain.reset_entities(campaign_meter)
	last_resolved_meter = campaign_meter
	wagon.freeze = false
	wagon.sleeping = false
	screen_state = "RUN"
	_play_audio("ui")
	_haptic_feedback(14, 0.35)
	_set_toast("Weiter bis %s!" % next_checkpoint_name(campaign_meter))
	_set_camera(1.0, true)
	if QA_DIAGNOSTICS.enabled():
		print("[PERF] run_started_at_m=%0.1f final_rescue=%s" % [campaign_meter, run_is_final_rescue])

func restart_campaign() -> void:
	if screen_state != "WIN":
		return
	screen_state = "MAP"
	paused = false
	clear_touch_actions()
	selected_world_index = 0
	_configure_selected_world()
	_save_progress()

func finish_ending_sequence() -> void:
	if screen_state != "ENDING":
		return
	ending_elapsed = ENDING_SEQUENCE_DURATION_S
	ending_sequence_seen = true
	screen_state = "WIN"
	_save_progress()
	var hud: CanvasItem = get_node_or_null("HUDLayer/HUD") as CanvasItem
	if hud != null:
		hud.queue_redraw()

func ending_sequence_phase() -> int:
	if ending_elapsed < 3.0:
		return 0
	if ending_elapsed < 7.0:
		return 1
	return 2

func toggle_pause(play_sound: bool = true) -> void:
	set_paused(not paused, play_sound)

func set_paused(should_pause: bool, play_sound: bool = true) -> void:
	if screen_state != "RUN" or paused == should_pause:
		return
	paused = should_pause
	clear_touch_actions()
	_reset_camera_shake()
	wagon.freeze = paused
	if paused:
		wagon.boost_active = false
		wagon.queue_redraw()
		_save_progress()
	if play_sound:
		_play_audio("ui")
	_haptic_feedback(10, 0.3)
	if not paused:
		wagon.sleeping = false

func set_touch_action(action: String, pressed: bool) -> void:
	if touch_actions.has(action) and screen_state == "RUN" and not paused:
		touch_actions[action] = pressed
		if QA_DIAGNOSTICS.enabled() and pressed:
			print("[PERF] action_pressed=%s" % action)

func clear_touch_actions() -> void:
	for action in touch_actions.keys():
		touch_actions[action] = false

func set_master_volume(value: float, persist: bool = true) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_master_volume()
	if persist:
		_save_progress()

func toggle_master_mute() -> void:
	set_master_volume(DEFAULT_MASTER_VOLUME if master_volume <= 0.01 else 0.0)

func set_music_volume(value: float, persist: bool = true) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if persist:
		_save_progress()
		if QA_DIAGNOSTICS.enabled():
			print("[AUDIO_SETTINGS_QA] music_volume=%.2f persisted=true" % music_volume)

func toggle_music_mute() -> void:
	set_music_volume(DEFAULT_MUSIC_VOLUME if music_volume <= 0.01 else 0.0)

func set_haptic_strength(value: float, persist: bool = true) -> void:
	haptic_strength = clampf(value, 0.0, 1.0)
	if persist:
		_save_progress()

func toggle_haptics() -> void:
	set_haptic_strength(DEFAULT_HAPTIC_STRENGTH if haptic_strength <= 0.01 else 0.0)

func _haptic_feedback(duration_ms: int, intensity: float = 1.0) -> void:
	if haptic_strength <= 0.01 or (not OS.has_feature("android") and not OS.has_feature("ios")):
		return
	Input.vibrate_handheld(duration_ms, clampf(haptic_strength * intensity, 0.0, 1.0))

func _on_wagon_landed(impact_speed: float) -> void:
	if screen_state != "RUN" or paused or impact_speed < 160.0:
		return
	var now_msec: int = Time.get_ticks_msec()
	if now_msec - _last_landing_haptic_msec < 250:
		return
	_last_landing_haptic_msec = now_msec
	_trigger_camera_shake(clampf(impact_speed / 120.0, 1.5, 6.0), 0.16)
	_haptic_feedback(18, clampf((impact_speed - 160.0) / 440.0, 0.28, 0.85))

func _apply_master_volume() -> void:
	var bus_index: int = AudioServer.get_bus_index("Master")
	if bus_index >= 0:
		AudioServer.set_bus_volume_linear(bus_index, master_volume)

func to_garage() -> void:
	var leaving_failed_result: bool = screen_state == "RESULT"
	clear_touch_actions()
	paused = false
	screen_state = "GARAGE"
	map_return_to_menu = false
	_play_audio("ui")
	_configure_selected_world()
	wagon.freeze = true
	wagon.configure(upgrades, selected_vehicle)
	wagon.reset_at((campaign_meter + START_OFFSET_M) * PIXELS_PER_METER, terrain)
	terrain.reset_entities(campaign_meter)
	last_resolved_meter = campaign_meter
	_set_camera(1.0, true)
	if leaving_failed_result:
		var ads_service: Node = get_node_or_null("/root/AdsService")
		if is_instance_valid(ads_service):
			ads_service.call("register_failed_result_exit")

func grant_rewarded_video_coins(amount: int, rewarded_run_id: int) -> bool:
	if rewarded_run_id != run_attempt_id or amount <= 0 or amount > 500:
		return false
	if rewarded_bonus_run_ids.has(rewarded_run_id):
		return false
	rewarded_bonus_run_ids[rewarded_run_id] = true
	money += amount
	_save_progress()
	if QA_DIAGNOSTICS.enabled():
		print("[AD_QA] reward_grant accepted=true run_id=%d amount=%d money=%d" % [rewarded_run_id, amount, money])
	_set_toast("VIDEO-BONUS · +%d MÜNZEN" % amount)
	_play_audio("upgrade")
	return true

func open_world_map() -> void:
	if is_first_drive_tutorial_active() or not ["MENU", "GARAGE", "LEVEL_COMPLETE", "WIN"].has(screen_state):
		return
	map_return_to_menu = screen_state == "MENU"
	if screen_state == "LEVEL_COMPLETE":
		selected_world_index = mini(run_world_index + 1, PLAYABLE_WORLD_COUNT - 1)
	elif screen_state == "WIN":
		selected_world_index = PLAYABLE_WORLD_COUNT - 1
	screen_state = "MAP"
	selected_world_index = clampi(selected_world_index, 0, mini(unlocked_world_index, PLAYABLE_WORLD_COUNT - 1))
	_configure_selected_world()
	_save_progress()
	_play_audio("ui")

func open_radio_archive() -> void:
	if is_first_drive_tutorial_active() or not ["GARAGE", "MAP"].has(screen_state):
		return
	archive_return_state = screen_state
	archive_selected_log_index = clampi(archive_selected_log_index, 0, maxi(0, story_log_count() - 1))
	screen_state = "ARCHIVE"
	_play_audio("ui")

func close_radio_archive() -> void:
	if screen_state != "ARCHIVE":
		return
	screen_state = archive_return_state if ["GARAGE", "MAP", "RESULT", "LEVEL_COMPLETE", "WIN"].has(archive_return_state) else "GARAGE"
	_play_audio("ui")

func select_story_log(index: int) -> void:
	if screen_state != "ARCHIVE" or index < 0 or index >= STORY_DATA.LOGS.size():
		return
	archive_selected_log_index = index
	_play_audio("ui")

func story_log_count() -> int:
	return STORY_DATA.LOGS.size()

func collected_story_log_count() -> int:
	var count: int = 0
	for is_collected in collected_story_logs:
		if is_collected:
			count += 1
	return count

func is_story_log_collected(index: int) -> bool:
	return index >= 0 and index < collected_story_logs.size() and collected_story_logs[index]

func story_log_data(index: int) -> Dictionary:
	var entry: Dictionary = STORY_DATA.get_log(index)
	if entry.is_empty():
		return {}
	if index < CAMPAIGN_DATA.CAMPAIGN_WORLDS.size():
		entry["city"] = String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[index].get("city", "EUROPA"))
		entry["world"] = index + 1
	else:
		entry["city"] = "AMSTERDAM · FUNDSTÜCK"
		entry["world"] = STORY_DATA.LOGS.size()
	return entry

func select_campaign_world(world_index: int) -> bool:
	if screen_state != "MAP" or not is_world_unlocked(world_index):
		return false
	selected_world_index = clampi(world_index, 0, PLAYABLE_WORLD_COUNT - 1)
	_configure_selected_world()
	wagon.configure(upgrades, selected_vehicle)
	wagon.reset_at((campaign_meter + START_OFFSET_M) * PIXELS_PER_METER, terrain)
	terrain.reset_entities(campaign_meter)
	last_resolved_meter = campaign_meter
	_save_progress()
	_play_audio("ui")
	return true

func is_world_unlocked(world_index: int) -> bool:
	return world_index >= 0 and world_index < PLAYABLE_WORLD_COUNT and world_index <= unlocked_world_index

func is_world_completed(world_index: int) -> bool:
	return world_index >= 0 and world_index < world_completed_flags.size() and world_completed_flags[world_index]

func world_data(world_index: int = -1) -> Dictionary:
	var index: int = selected_world_index if world_index < 0 else world_index
	if index < 0 or index >= CAMPAIGN_DATA.CAMPAIGN_WORLDS.size():
		return {}
	return CAMPAIGN_DATA.CAMPAIGN_WORLDS[index]

func _initialize_world_progress() -> void:
	world_best_distances.clear()
	world_completed_flags.clear()
	world_challenge_completed.clear()
	collected_story_logs.clear()
	for _index in range(CAMPAIGN_DATA.CAMPAIGN_WORLDS.size()):
		world_best_distances.append(0.0)
		world_completed_flags.append(false)
		world_challenge_completed.append(false)
	for _index in range(STORY_DATA.LOGS.size()):
		collected_story_logs.append(false)

func challenge_data(world_index: int = -1, rescue: bool = false) -> Dictionary:
	if rescue:
		return CHALLENGE_DATA.RESCUE_CHALLENGE
	var index: int = selected_world_index if world_index < 0 else world_index
	if index < 0 or index >= CHALLENGE_DATA.WORLD_CHALLENGES.size():
		return {}
	return CHALLENGE_DATA.WORLD_CHALLENGES[index]

func is_world_challenge_completed(world_index: int) -> bool:
	return world_index >= 0 and world_index < world_challenge_completed.size() and world_challenge_completed[world_index]

func completed_challenge_count() -> int:
	var completed_count: int = 0
	for completed in world_challenge_completed:
		if completed:
			completed_count += 1
	return completed_count

func challenge_status() -> Dictionary:
	var is_run_view: bool = ["RUN", "RESULT", "LEVEL_COMPLETE", "WIN"].has(screen_state)
	var rescue_view: bool = is_run_view and (run_is_final_rescue or (screen_state == "WIN" and final_rescue_completed))
	var world_index: int = run_world_index if is_run_view else selected_world_index
	var challenge: Dictionary = challenge_data(world_index, rescue_view)
	if challenge.is_empty():
		return {}
	var permanent_complete: bool = final_rescue_challenge_completed if rescue_view else is_world_challenge_completed(world_index)
	var value: float = _challenge_progress_value(challenge)
	var target: float = float(challenge.get("target", 1.0))
	var progress_text: String = _challenge_progress_text(challenge, value, target)
	var achieved: bool = run_challenge_success if is_run_view else permanent_complete
	if screen_state == "RUN" and not paused and _challenge_requirements_met():
		progress_text = "ZIEL ERREICHT · BIS ZUM ETAPPENENDE HALTEN"
	elif achieved:
		progress_text = "GESCHAFFT" if run_challenge_reward > 0 or not is_run_view else "MEDAILLE BEREITS GESICHERT"
	elif permanent_complete:
		progress_text = "MEDAILLE BEREITS GESICHERT"
	return {
		"title": String(challenge.get("title", "Etappenziel")),
		"short": String(challenge.get("short", "BONUSZIEL")),
		"progress_text": progress_text,
		"fraction": clampf(value / maxf(1.0, target), 0.0, 1.0),
		"achieved": achieved,
		"completed": permanent_complete,
		"reward": int(challenge.get("reward", 0)),
		"earned": run_challenge_reward
	}

func _challenge_progress_value(challenge: Dictionary) -> float:
	match String(challenge.get("kind", "")):
		"coins":
			return float(run_collectible_reward)
		"zombies":
			return float(run_zombie_contacts)
		"condition":
			return float(wagon.durability)
		"speed":
			return run_peak_speed_kmh
		"fuel":
			return float(wagon.fuel)
		"repairs":
			return float(run_repair_pickups)
		"clean_hazard":
			return 1.0 if run_hazard_passed and run_hazard_hits == 0 else 0.0
	return 0.0

func _challenge_requirements_met() -> bool:
	var challenge: Dictionary = challenge_data(run_world_index, run_is_final_rescue)
	if challenge.is_empty():
		return false
	return _challenge_progress_value(challenge) + 0.001 >= float(challenge.get("target", 1.0))

func _challenge_progress_text(challenge: Dictionary, value: float, target: float) -> String:
	match String(challenge.get("kind", "")):
		"coins":
			return "%d/%d MÜNZEN" % [int(value), int(target)]
		"zombies":
			return "%d/%d ZOMBIES" % [int(value), int(target)]
		"condition":
			return "%d/%d%% ZUSTAND" % [int(value), int(target)]
		"speed":
			return "%d/%d KM/H" % [int(value), int(target)]
		"fuel":
			return "%d/%d L AM ZIEL" % [int(value), int(target)]
		"repairs":
			return "%d/%d KISTEN" % [int(value), int(target)]
		"clean_hazard":
			if run_hazard_passed:
				return "TREFFER" if run_hazard_hits > 0 else "HINDERNIS SAUBER PASSIERT"
			return "HINDERNIS STEHT NOCH BEVOR"
	return "NOCH OFFEN"

func _configure_selected_world() -> void:
	selected_world_index = clampi(selected_world_index, 0, PLAYABLE_WORLD_COUNT - 1)
	var definition: Dictionary = CAMPAIGN_DATA.CAMPAIGN_WORLDS[selected_world_index]
	route_length_m = float(definition.get("length_m", ROUTE_LENGTH_M))
	active_checkpoints = _build_world_checkpoints(selected_world_index)
	campaign_meter = 0.0 if world_completed_flags[selected_world_index] else clampf(world_best_distances[selected_world_index], 0.0, route_length_m)
	if is_instance_valid(terrain):
		terrain.configure_world(selected_world_index)
		terrain.set_story_log_available(false)
	if is_instance_valid(backdrop):
		backdrop.call("configure_world", selected_world_index)
	if is_instance_valid(wagon):
		wagon.set_weapon_active(selected_world_index in [0, 1, 2] and selected_vehicle == "kombi")

func _build_world_checkpoints(world_index: int) -> Array[Dictionary]:
	var definition: Dictionary = CAMPAIGN_DATA.CAMPAIGN_WORLDS[world_index]
	var length: float = float(definition.get("length_m", 1800.0))
	var scale: float = 1.0 + float(world_index) * 0.035
	return [
		{"meter": length * 0.38, "name": "VORRATSDEPOT", "reward": int(round(20.0 * scale)), "supply": true},
		{"meter": length * 0.72, "name": "LETZTER KONTROLLPUNKT", "reward": int(round(28.0 * scale)), "supply": true},
		{"meter": length, "name": String(definition.get("city", "ZIEL")).to_upper(), "reward": int(round(35.0 * scale)), "supply": false, "world_goal": true}
	]

func _build_rescue_checkpoints(length: float) -> Array[Dictionary]:
	return [
		{"meter": length * 0.38, "name": "LETZTE SPERRZONE", "reward": 45, "supply": true},
		{"meter": length * 0.72, "name": "HAFENMOLE", "reward": 65, "supply": true},
		{"meter": length, "name": "RETTUNGSSCHIFF", "reward": 0, "supply": false, "world_goal": true}
	]

func is_starting_hill_package_available() -> bool:
	return not stock_test_mode and not tuning_trial_mode and screen_state == "GARAGE" and unlocked_vehicles.size() == 1 and float(campaign_meter) < float(route_length_m) * 0.5 and upgrade_level("engine") == 0 and upgrade_level("tank") == 0

func starting_hill_package_price() -> int:
	if not is_starting_hill_package_available():
		return -1
	var engine_price: int = upgrade_price("engine")
	var tank_price: int = upgrade_price("tank")
	if engine_price < 0 or tank_price < 0:
		return -1
	return engine_price + tank_price

func buy_starting_hill_package() -> bool:
	if tuning_trial_mode:
		_set_toast("Tuning-Test · bitte die Teile einzeln auswählen")
		return false
	if stock_test_mode:
		_set_toast("Serienfahrzeug-Test · Tuning bleibt für diese Runde aus")
		return false
	if not is_starting_hill_package_available():
		return false
	var package_price: int = starting_hill_package_price()
	if package_price < 0:
		return false
	if money < package_price:
		_set_toast("Für das Startpaket fehlen noch %d Münzen." % (package_price - int(money)))
		return false
	money -= package_price
	upgrades["engine"] = 1
	upgrades["tank"] = 1
	vehicle_upgrades[selected_vehicle] = upgrades.duplicate(true)
	wagon.configure(upgrades, selected_vehicle)
	_save_progress()
	_play_audio("upgrade")
	_set_toast("STARTPAKET EINGEBAUT · MEHR ZUG + REICHWEITE")
	return true

func buy_upgrade(part: String, test_only: bool = false) -> bool:
	if screen_state != "GARAGE" or stock_test_mode != test_only or not UPGRADE_COSTS.has(part):
		return false
	if part == "weapon" and not can_buy_weapon_upgrade():
		_set_toast("HAUBENPISTOLE NACH VOLLAUSBAU VON MOTOR, REIFEN, TANK, PANZERUNG UND NITRO")
		return false
	if part == "weapon" and selected_vehicle != "kombi":
		_set_toast("DIE HAUBENPISTOLE PASST NUR AUF DEN KOMBI")
		return false
	var level: int = int(upgrades.get(part, 0))
	if level >= int(UPGRADE_MAX[part]):
		return false
	if test_only:
		upgrades[part] = level + 1
		wagon.configure(upgrades, selected_vehicle)
		_play_audio("upgrade")
		_set_toast("TESTSTUFE %d MONTIERT" % (level + 1))
		return true
	var cost: int = int(UPGRADE_COSTS[part][level])
	if money < cost:
		_set_toast("Dafür fehlen noch Münzen.")
		return false
	money -= cost
	upgrades[part] = level + 1
	vehicle_upgrades[selected_vehicle] = upgrades.duplicate(true)
	if tuning_trial_mode:
		_finish_tuning_trial()
	wagon.configure(upgrades, selected_vehicle)
	_save_progress()
	_play_audio("upgrade")
	_set_toast("Verbesserung eingebaut!")
	return true

func upgrade_price(part: String) -> int:
	if not UPGRADE_COSTS.has(part):
		return -1
	var level: int = int(upgrades.get(part, 0))
	if level >= int(UPGRADE_MAX[part]):
		return -1
	return int(UPGRADE_COSTS[part][level])

func upgrade_preview(part: String) -> Dictionary:
	if not UPGRADE_COSTS.has(part):
		return {"available": false, "text": ""}
	var level: int = upgrade_level(part)
	var price: int = upgrade_price(part)
	if price < 0:
		return {"available": false, "level": level, "price": -1, "text": "VOLL AUSGEBAUT"}
	var vehicle: Dictionary = CAMPAIGN_DATA.VEHICLES.get(selected_vehicle, CAMPAIGN_DATA.VEHICLES["kombi"])
	var preview: Dictionary = {
		"available": true,
		"part": part,
		"level": level,
		"next_level": level + 1,
		"price": price,
		"text": ""
	}
	match part:
		"engine":
			var current_force: float = float(vehicle["base_engine_force"]) + float(level) * float(vehicle["engine_force_per_level"])
			var force_gain: float = float(vehicle["engine_force_per_level"])
			var current_speed_kmh: float = (float(vehicle["base_speed_mps"]) + float(level) * float(vehicle["speed_per_level_mps"])) * 3.6
			var speed_gain_kmh: float = float(vehicle["speed_per_level_mps"]) * 3.6
			preview["current_value"] = current_force
			preview["next_value"] = current_force + force_gain
			preview["current_speed_kmh"] = current_speed_kmh
			preview["next_speed_kmh"] = current_speed_kmh + speed_gain_kmh
			var force_gain_percent: int = int(round(force_gain / maxf(1.0, current_force) * 100.0))
			preview["text"] = "+%s KM/H · +%d%% ZUG" % [String.num(speed_gain_kmh, 1).replace(".", ","), force_gain_percent]
		"tank":
			var current_capacity: float = float(vehicle["base_fuel"]) + float(level) * float(vehicle["fuel_per_tank_level"])
			var capacity_gain: float = float(vehicle["fuel_per_tank_level"])
			preview["current_value"] = current_capacity
			preview["next_value"] = current_capacity + capacity_gain
			preview["text"] = "+%d TANKVORRAT" % int(round(capacity_gain))
		"tires":
			var current_suspension: float = float(vehicle.get("suspension_strength", 9500.0)) + float(level) * 900.0
			var current_damping: float = float(vehicle.get("suspension_damping", 1550.0)) + float(level) * 100.0
			var suspension_gain: float = 900.0
			var damping_gain: float = 100.0
			preview["current_value"] = current_suspension
			preview["next_value"] = current_suspension + suspension_gain
			preview["current_damping"] = current_damping
			preview["next_damping"] = current_damping + damping_gain
			var suspension_percent: int = int(round(suspension_gain / maxf(1.0, current_suspension) * 100.0))
			var damping_percent: int = int(round(damping_gain / maxf(1.0, current_damping) * 100.0))
			preview["current_grip"] = 1.0 + float(level) * 0.07
			preview["next_grip"] = 1.0 + float(level + 1) * 0.07
			preview["text"] = "+%d%% FEDERUNG · +%d%% DÄMPFUNG" % [suspension_percent, damping_percent]
		"armor":
			var base_damage: float = float(vehicle["obstacle_damage"])
			var current_damage: float = maxf(8.0, base_damage - float(level) * 4.0)
			var next_damage: float = maxf(8.0, base_damage - float(level + 1) * 4.0)
			preview["current_value"] = current_damage
			preview["next_value"] = next_damage
			preview["text"] = "-%d SCHADEN JE TREFFER" % int(round(current_damage - next_damage))
		"suspension":
			var current_spring: float = float(vehicle.get("suspension_strength", 9500.0)) + float(upgrade_level("tires")) * 900.0 + float(level) * 1200.0
			var current_damping: float = float(vehicle.get("suspension_damping", 1550.0)) + float(upgrade_level("tires")) * 100.0 + float(level) * 220.0
			preview["current_value"] = current_spring
			preview["next_value"] = current_spring + 1200.0
			preview["current_damping"] = current_damping
			preview["next_damping"] = current_damping + 220.0
			preview["text"] = "+%d FEDERKRAFT · +%d DÄMPFUNG" % [int(round(1200.0 / maxf(1.0, current_spring) * 100.0)), int(round(220.0 / maxf(1.0, current_damping) * 100.0))]
		"efficiency":
			var current_multiplier: float = maxf(0.70, 1.0 - float(level) * 0.08)
			var next_multiplier: float = maxf(0.70, 1.0 - float(level + 1) * 0.08)
			preview["current_value"] = current_multiplier
			preview["next_value"] = next_multiplier
			preview["text"] = "-%d%% VERBRAUCH" % int(round((current_multiplier - next_multiplier) * 100.0))
		"brakes":
			var current_force: float = 6200.0 + float(level) * 930.0
			preview["current_value"] = current_force
			preview["next_value"] = current_force + 930.0
			preview["text"] = "+15% BREMSKRAFT"
		"nitro":
			var current_capacity: float = 0.0 if level == 0 else 100.0 + float(level) * 20.0
			var next_capacity: float = 100.0 + float(level + 1) * 20.0
			preview["current_value"] = current_capacity
			preview["next_value"] = next_capacity
			var current_boost:float=float(vehicle["boost_force"])*(1.0+level*0.08)
			var next_boost:float=float(vehicle["boost_force"])*(1.0+(level+1)*0.08)
			preview["text"] = "BOOST FREI · %d VORRAT" % int(round(next_capacity)) if level == 0 else "+20 VORRAT · +%d%% SCHUB" % roundi((next_boost/current_boost-1.0)*100.0)
		"weapon":
			preview["current_value"] = 0 if level == 0 else 1
			preview["next_value"] = 1
			preview["text"] = "AUTOFEUER · ZOMBIES UND FÄSSER VOR DEM AUTO"
	return preview

func vehicle_core_is_fully_upgraded(vehicle_id: String = "") -> bool:
	var target_vehicle: String = selected_vehicle if vehicle_id.is_empty() else vehicle_id
	var levels: Variant = vehicle_upgrades.get(target_vehicle, upgrades) if target_vehicle != selected_vehicle else upgrades
	if not (levels is Dictionary):
		return false
	for part in CORE_VEHICLE_UPGRADES:
		if int(levels.get(part, 0)) < int(UPGRADE_MAX[part]):
			return false
	return true

func can_show_weapon_upgrade() -> bool:
	return selected_vehicle == "kombi" and (selected_world_index == 0 or stock_test_mode)

func can_buy_weapon_upgrade() -> bool:
	return can_show_weapon_upgrade() and upgrade_level("weapon") == 0 and vehicle_core_is_fully_upgraded()

func can_test_stock_vehicle() -> bool:
	return selected_vehicle == "kombi" and not tuning_trial_mode

func open_stock_test_workshop() -> void:
	if not can_test_stock_vehicle():
		return
	to_garage()
	if not stock_test_mode:
		_activate_stock_test_mode()

func reset_stock_test_upgrades() -> void:
	if screen_state != "GARAGE" or not stock_test_mode:
		return
	upgrades = _stock_upgrade_levels()
	wagon.configure(upgrades, selected_vehicle)
	_set_toast("TEST-KOMBI AUF SERIE ZURÜCKGESETZT")

func toggle_stock_test_mode() -> void:
	if screen_state != "GARAGE" or not can_test_stock_vehicle():
		return
	if stock_test_mode:
		_restore_stock_test_loadout()
	else:
		_activate_stock_test_mode()
	var hud: CanvasItem = get_node_or_null("HUDLayer/HUD") as CanvasItem
	if hud != null:
		hud.queue_redraw()

func _restore_stock_test_loadout() -> void:
	if _stock_test_saved_upgrades.is_empty():
		stock_test_mode = false
		if _stock_test_saved_money >= 0:
			money = _stock_test_saved_money
		_stock_test_saved_money = -1
		wagon.set_stock_test_mode(false)
		return
	selected_vehicle = _stock_test_saved_vehicle if CAMPAIGN_DATA.VEHICLES.has(_stock_test_saved_vehicle) else "kombi"
	upgrades = _stock_test_saved_upgrades.duplicate(true)
	vehicle_upgrades[selected_vehicle] = upgrades.duplicate(true)
	if _stock_test_saved_money >= 0:
		money = _stock_test_saved_money
	stock_test_mode = false
	_stock_test_saved_vehicle = ""
	_stock_test_saved_upgrades.clear()
	_stock_test_saved_money = -1
	wagon.set_stock_test_mode(false)
	wagon.configure(upgrades, selected_vehicle)
	wagon.set_weapon_active(selected_world_index in [0, 1, 2] and selected_vehicle == "kombi")
	wagon.reset_at((campaign_meter + START_OFFSET_M) * PIXELS_PER_METER, terrain)
	_save_progress()
	_play_audio("upgrade")
	_set_toast("GETUNTES TEST-FAHRZEUG WIEDERHERGESTELLT · SPIELSTAND GESICHERT")

func upgrade_level(part: String) -> int:
	return int(upgrades.get(part, 0))

func upgrade_limit(part: String) -> int:
	return int(UPGRADE_MAX.get(part, 0))

func is_vehicle_unlocked(vehicle_id: String) -> bool:
	return unlocked_vehicles.has(vehicle_id)

func current_vehicle_name() -> String:
	var vehicle: Dictionary = CAMPAIGN_DATA.VEHICLES.get(selected_vehicle, CAMPAIGN_DATA.VEHICLES["kombi"])
	return _format_vehicle_name(String(vehicle["name"]))

func next_vehicle_name() -> String:
	var next_id: String = _next_unlocked_vehicle_id()
	var vehicle: Dictionary = CAMPAIGN_DATA.VEHICLES.get(next_id, CAMPAIGN_DATA.VEHICLES["kombi"])
	return _format_vehicle_name(String(vehicle["name"]))

func _format_vehicle_name(raw_name: String) -> String:
	var name_parts: PackedStringArray = raw_name.to_lower().split("-", false)
	for part_index in range(name_parts.size()):
		name_parts[part_index] = name_parts[part_index].capitalize()
	return "-".join(name_parts)

func next_vehicle_unlock_hint() -> String:
	for vehicle_id in CAMPAIGN_DATA.VEHICLE_ORDER:
		if is_vehicle_unlocked(vehicle_id):
			continue
		var vehicle: Dictionary = CAMPAIGN_DATA.VEHICLES[vehicle_id]
		var unlock_world_index: int = int(vehicle.get("unlock_world", 0))
		if unlock_world_index >= PLAYABLE_WORLD_COUNT:
			return "%s AUF EINER SPÄTEREN STRECKE" % String(vehicle["name"])
		unlock_world_index = clampi(unlock_world_index, 0, CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() - 1)
		var unlock_after_city: String = String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[unlock_world_index].get("city", ""))
		return "%s NACH %s" % [String(vehicle["name"]), unlock_after_city.to_upper()]
	return "ALLE FAHRZEUGE FREI"

func vehicle_unlock_message() -> String:
	if unlocked_vehicle_names_this_run.is_empty():
		return ""
	return "%s FREIGESCHALTET" % " · ".join(PackedStringArray(unlocked_vehicle_names_this_run))

func _next_unlocked_vehicle_id() -> String:
	var current_index: int = CAMPAIGN_DATA.VEHICLE_ORDER.find(selected_vehicle)
	if current_index < 0:
		current_index = 0
	for step in range(1, CAMPAIGN_DATA.VEHICLE_ORDER.size() + 1):
		var candidate_index: int = (current_index + step) % CAMPAIGN_DATA.VEHICLE_ORDER.size()
		var candidate_id: String = CAMPAIGN_DATA.VEHICLE_ORDER[candidate_index]
		if is_vehicle_unlocked(candidate_id):
			return candidate_id
	return selected_vehicle

func select_next_vehicle() -> bool:
	if stock_test_mode:
		_set_toast("Serienfahrzeug-Test · Fahrzeugwechsel ist pausiert")
		return false
	if screen_state != "GARAGE":
		return false
	var next_id: String = _next_unlocked_vehicle_id()
	if not is_vehicle_unlocked(next_id):
		_set_toast("%s" % next_vehicle_unlock_hint().to_lower().capitalize())
		return false
	if next_id == selected_vehicle:
		_set_toast("Es ist nur ein Fahrzeug freigeschaltet.")
		return false
	vehicle_upgrades[selected_vehicle] = upgrades.duplicate(true)
	selected_vehicle = next_id
	var stored_levels: Variant = vehicle_upgrades.get(selected_vehicle, {})
	upgrades = stored_levels.duplicate(true) if stored_levels is Dictionary else {"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0, "weapon": 0}
	wagon.configure(upgrades, selected_vehicle)
	wagon.set_weapon_active(selected_world_index in [0, 1, 2] and selected_vehicle == "kombi")
	wagon.reset_at((campaign_meter + START_OFFSET_M) * PIXELS_PER_METER, terrain)
	terrain.reset_entities(campaign_meter)
	last_resolved_meter = campaign_meter
	_save_progress()
	_play_audio("upgrade")
	_set_toast("%s ausgewählt" % current_vehicle_name())
	return true

func _unlock_vehicle(vehicle_id: String) -> bool:
	if not CAMPAIGN_DATA.VEHICLES.has(vehicle_id) or is_vehicle_unlocked(vehicle_id):
		return false
	unlocked_vehicles.append(vehicle_id)
	return true

func _unlock_vehicles_for_world(world_index: int, persist_immediately: bool = true) -> Array[String]:
	var newly_unlocked: Array[String] = []
	for vehicle_id in CAMPAIGN_DATA.VEHICLE_ORDER:
		var vehicle: Dictionary = CAMPAIGN_DATA.VEHICLES[vehicle_id]
		if world_index < int(vehicle.get("unlock_world", 0)):
			continue
		if _unlock_vehicle(vehicle_id):
			newly_unlocked.append(String(vehicle["name"]))
	if not newly_unlocked.is_empty():
		vehicle_unlocked_this_run = true
		for vehicle_name in newly_unlocked:
			unlocked_vehicle_names_this_run.append(vehicle_name)
		if persist_immediately:
			_save_progress()
	return newly_unlocked

func route_leg_label(meter: float) -> String:
	if run_is_final_rescue:
		return "SÜDHAFEN  →  RETTUNGSSCHIFF"
	var departure: Dictionary = world_data(run_world_index if screen_state == "RUN" else selected_world_index)
	var next_index: int = (run_world_index if screen_state == "RUN" else selected_world_index) + 1
	var arrival_name: String = "ZIEL" if next_index >= PLAYABLE_WORLD_COUNT else String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[next_index]["city"]).to_upper()
	return "%s  →  %s" % [String(departure.get("city", "AMSTERDAM")).to_upper(), arrival_name]

func next_checkpoint_name(meter: float) -> String:
	for checkpoint in active_checkpoints:
		if float(checkpoint["meter"]) > meter + 0.5:
			return String(checkpoint["name"])
	return String(world_data().get("city", "AMSTERDAM")).to_upper()

func next_checkpoint_distance(meter: float) -> float:
	for checkpoint in active_checkpoints:
		var checkpoint_meter: float = float(checkpoint["meter"])
		if checkpoint_meter > meter + 0.5:
			return maxf(0.0, checkpoint_meter - meter)
	return maxf(0.0, route_length_m - meter)

func next_road_hazard_warning(route_meter: float, lookahead_m: float = 140.0) -> Dictionary:
	var nearest: Dictionary = {}
	var nearest_distance: float = maxf(0.5, lookahead_m)
	for entity in terrain.entities:
		if String(entity.get("kind", "")) != "setpiece" or bool(entity.get("done", false)):
			continue
		var distance_m: float = float(entity.get("meter", 0.0)) - route_meter
		if distance_m <= 0.5 or distance_m > nearest_distance:
			continue
		nearest = entity.duplicate()
		nearest["distance_m"] = distance_m
		nearest_distance = distance_m
	return nearest

func _next_checkpoint_index(meter: float) -> int:
	for index in range(active_checkpoints.size()):
		if float(active_checkpoints[index]["meter"]) > meter + 0.5:
			return index
	return active_checkpoints.size()

func _resolve_checkpoints(old_meter: float, new_meter: float) -> void:
	if new_meter <= old_meter:
		return
	while next_checkpoint_index < active_checkpoints.size():
		var checkpoint: Dictionary = active_checkpoints[next_checkpoint_index]
		var checkpoint_meter: float = float(checkpoint["meter"])
		if checkpoint_meter > new_meter + 1.0:
			break
		if checkpoint_meter >= old_meter - 0.5:
			var reward: int = int(checkpoint["reward"])
			if bool(checkpoint.get("world_goal", false)) and world_completed_flags[run_world_index]:
				reward = 0
			run_checkpoint_reward += reward
			var supplied: bool = bool(checkpoint.get("supply", false)) and _apply_checkpoint_supply()
			_haptic_feedback(38, 1.0)
			var checkpoint_toast: String = "%s +%d MÜNZEN" % [String(checkpoint["name"]), reward]
			if supplied:
				checkpoint_toast += " · VERSORGT"
			_set_toast(checkpoint_toast)
		next_checkpoint_index += 1

func _apply_checkpoint_supply() -> bool:
	var fuel_added: float = minf(CHECKPOINT_FUEL_SUPPLY, maxf(0.0, wagon.fuel_capacity - wagon.fuel))
	var nitro_added: float = minf(CHECKPOINT_NITRO_SUPPLY, maxf(0.0, wagon.nitro_capacity - wagon.nitro)) if wagon.nitro_level > 0 else 0.0
	var repair_added: float = minf(CHECKPOINT_REPAIR_SUPPLY, maxf(0.0, 100.0 - wagon.durability))
	wagon.fuel += fuel_added
	wagon.nitro += nitro_added
	wagon.durability += repair_added
	return fuel_added > 0.01 or nitro_added > 0.01 or repair_added > 0.01

func _resolve_entities(old_meter: float, new_meter: float, front_offset_m: float = 0.0) -> void:
	for entity in terrain.entities:
		if bool(entity["done"]):
			continue
		var entity_meter: float = float(entity["meter"])
		var entity_kind: String = String(entity["kind"])
		if entity_kind == "zombie":
			var authored_zombie_x: float = float(entity["draw_world_x"]) if entity.has("draw_world_x") else terrain.route_meter_to_world_x(entity_meter)
			var chase_offset_px: float = float(entity.get("chase_offset_px", 0.0))
			var zombie_variant_id: int = int(entity.get("variant_id", 1))
			var group_size: int = int(entity.get("group_size", 1))
			var visual_height: float = float(entity.get("visual_height_px", 78.0))
			var group_spacing: float = float(entity.get("group_spacing_px", 62.4))
			var group_reach_px: float = float(maxi(0, group_size - 1)) * group_spacing * 0.5
			var zombie_center_x: float = authored_zombie_x - chase_offset_px
			var group_left_x: float = zombie_center_x - group_reach_px - visual_height * 0.31
			if wagon.position.x + 130.0 < group_left_x:
				continue
			var group_right_x: float = zombie_center_x + group_reach_px + visual_height * 0.35
			if wagon.position.x - 115.0 > group_right_x:
				entity["done"] = true
				continue
			var zombie_profile: Dictionary = entity["zombie_profile"] if entity.has("zombie_profile") else ZOMBIE_DATA.profile(zombie_variant_id)
			var contact: Dictionary = _zombie_group_spatial_contact(entity, authored_zombie_x, chase_offset_px, group_size, group_spacing, zombie_profile)
			if not bool(contact.get("overlap", false)):
				continue
			var zombie_contact_x: float = float(contact.get("x", authored_zombie_x - chase_offset_px - group_reach_px))
			entity["done"] = true
			var zombie_group: int = int(entity.get("group_size", 1))
			var stop_duration: float = float(entity.get("stop_duration", 0.0))
			var impact_speed_mps: float = absf(wagon.linear_velocity.x) / PIXELS_PER_METER
			wagon.hit_zombie(float(entity.get("damage", 0.0)), float(entity.get("speed_retention", 0.76)), stop_duration, true)
			var attached_count: int = 0
			for member_index in range(zombie_group):
				var latch_profile: Dictionary = _zombie_latch_profile(entity, member_index)
				if latch_profile.is_empty():
					continue
				if wagon.add_zombie_latch(float(latch_profile["duration"]), float(latch_profile["drag"]), member_index, zombie_variant_id, float(latch_profile["damage"])):
					attached_count += 1
			terrain.spawn_event_feedback(zombie_contact_x, terrain.height_at(zombie_contact_x), "zombie", 1.0)
			terrain.begin_zombie_reaction(entity, attached_count, impact_speed_mps)
			run_zombie_contacts += zombie_group
			_trigger_camera_shake(clampf(absf(wagon.speed_mps) * 0.16, 2.0, 5.0), 0.13)
			_play_audio("impact")
			_haptic_feedback(28, 0.9)
			var zombie_reward: int = int(entity.get("reward_remaining", entity.get("reward", 9)))
			run_zombie_reward += zombie_reward
			if zombie_variant_id == 5:
				_set_toast("KETTENBRUTE · KOMBI 1 SEKUNDE GESTOPPT")
			elif attached_count > 0:
				_set_toast("ZOMBIE HÄNGT AM AUTO · TEMPO SINKT" if attached_count == 1 else "%d ZOMBIES HÄNGEN FEST · TEMPO SINKT" % attached_count)
			else:
				_set_toast("Horde durchbrochen  +%d" % zombie_reward if zombie_group > 1 else "Zombie erwischt  +%d" % zombie_reward)
			continue
		if entity_kind in ["barrel", "wreck"]:
			var obstacle_world_x: float = float(entity["draw_world_x"]) if entity.has("draw_world_x") else terrain.route_meter_to_world_x(entity_meter)
			var obstacle_half_width: float = 13.0 if entity_kind == "barrel" else 33.0
			var obstacle_left_x: float = obstacle_world_x - obstacle_half_width
			var obstacle_right_x: float = obstacle_world_x + obstacle_half_width
			if wagon.position.x + 130.0 < obstacle_left_x:
				continue
			if wagon.position.x - 115.0 > obstacle_right_x:
				entity["done"] = true
				continue
			var obstacle_rect: Rect2 = _entity_obstacle_rect(entity)
			if wagon.chassis_overlaps_world_rect(obstacle_rect):
				entity["done"] = true
				_resolve_weighted_obstacle(entity, obstacle_rect)
			continue
		if entity_kind == "setpiece":
			if new_meter <= old_meter:
				continue
			var setpiece_contact_meter: float = entity_meter - maxf(0.0, front_offset_m)
			if setpiece_contact_meter < old_meter - 0.5 or setpiece_contact_meter > new_meter + 1.0:
				continue
			entity["done"] = true
			var setpiece_world_x: float = float(entity["draw_world_x"]) if entity.has("draw_world_x") else terrain.route_meter_to_world_x(entity_meter)
			var setpiece_ground_y: float = float(entity["draw_ground_y"]) if entity.has("draw_ground_y") else terrain.height_at(setpiece_world_x)
			var setpiece_width: float = float(entity.get("hit_width", 110.0))
			var setpiece_height: float = float(entity.get("hit_height", 43.0))
			var setpiece_rect := Rect2(Vector2(setpiece_world_x - setpiece_width * 0.5, setpiece_ground_y - setpiece_height), Vector2(setpiece_width, setpiece_height))
			if wagon.chassis_overlaps_world_rect(setpiece_rect):
				_resolve_setpiece_hazard(entity)
			elif wagon.airborne and int(entity.get("air_route_reward", 0)) > 0:
				var air_reward: int = int(entity["air_route_reward"])
				run_collectible_reward += air_reward
				terrain.spawn_event_feedback(setpiece_world_x, setpiece_ground_y - 35.0, "pickup", 1.1)
				_trigger_camera_shake(3.0, 0.12)
				_play_audio("pickup")
				_haptic_feedback(24, 0.8)
				_set_toast("SPRUNGROUTE GESCHAFFT · +%d MÜNZEN" % air_reward)
			continue
		if new_meter <= old_meter:
			continue
		var trigger_offset_m: float = float(entity.get("trigger_offset_m", front_offset_m))
		var contact_meter: float = entity_meter - maxf(0.0, trigger_offset_m)
		if contact_meter < old_meter - 0.5 or contact_meter > new_meter + 1.0:
			continue
		entity["done"] = true
		match String(entity["kind"]):
			"rescue_ship":
				_set_toast("RETTUNGSSCHIFF IN SICHT!")
			"story_log":
				var story_log_index: int = int(entity.get("story_log_index", 0))
				if story_log_index >= 0 and story_log_index < collected_story_logs.size() and not collected_story_logs[story_log_index]:
					collected_story_logs[story_log_index] = true
					run_story_log_collected = true
					run_collectible_reward += int(entity.get("reward", 20))
					terrain.set_story_log_available(false)
					var story_x: float = float(entity.get("draw_world_x", terrain.route_meter_to_world_x(entity_meter)))
					var story_y: float = float(entity.get("draw_ground_y", terrain.height_at(story_x)))
					terrain.spawn_event_feedback(story_x, story_y - 25.0, "pickup", 0.9)
					_trigger_camera_shake(2.5, 0.12)
					_play_audio("pickup")
					_haptic_feedback(20, 0.7)
					_save_progress()
					_set_toast("AMSTERDAMER FLUCHTPLAN GEBORGEN · +%d MÜNZEN" % int(entity.get("reward", 20)))
			"checkpoint":
				pass
			"setpiece":
				_resolve_setpiece_hazard(entity)
			"launch_ramp":
				var minimum_launch_speed: float = float(entity.get("min_launch_speed_mps", 0.0))
				if bool(entity.get("upper_route_launch", false)):
					if absf(wagon.speed_mps) >= minimum_launch_speed:
						wagon.launch_to_elevated_route(float(entity.get("distance_to_upper_route_m", 14.0)), float(entity.get("upper_route_height_px", 122.0)))
						terrain.spawn_event_feedback(wagon.position.x - 72.0, wagon.position.y + 18.0, "boost", 1.2)
						_trigger_camera_shake(3.5, 0.16)
						_set_toast("OBERE SPRUNGROUTE · AUF DEM CONTAINERDECK LANDEN")
					else:
						_set_toast("UNTERE ROUTE · CONTAINER-SPERRUNG DURCHBRECHEN")
				elif absf(wagon.speed_mps) >= minimum_launch_speed or minimum_launch_speed <= 0.0:
					wagon.launch_from_ramp(float(entity.get("distance_to_hazard_m", 12.0)), float(entity.get("launch_clearance_m", 0.65)))
					terrain.spawn_event_feedback(wagon.position.x - 72.0, wagon.position.y + 18.0, "boost", 1.15)
					_set_toast("SPRUNGRAMPE · IN DER LUFT AUSGLEICHEN")
			"ramp_marker":
				pass
			"coins":
				if not wagon.airborne:
					var coin_reward: int = int(entity.get("reward", 30))
					run_collectible_reward += coin_reward
					var coin_x: float = terrain.route_meter_to_world_x(entity_meter)
					terrain.spawn_event_feedback(coin_x, terrain.height_at(coin_x), "pickup", 0.75)
					_trigger_camera_shake(2.0, 0.10)
					_play_audio("pickup")
					_haptic_feedback(18, 0.65)
					_set_toast("Münzversteck  +%d" % coin_reward)
				else:
					_set_toast("Münzen knapp verfehlt!")
			"nitro":
				if not wagon.airborne:
					if wagon.nitro_level <= 0:
						_set_toast("NITRO-UPGRADE FEHLT · IN DER WERKSTATT KAUFEN")
					else:
						var nitro_amount: float = float(entity.get("amount", 45.0))
						var nitro_found: float = minf(nitro_amount, wagon.nitro_capacity - wagon.nitro)
						wagon.nitro = minf(wagon.nitro_capacity, wagon.nitro + nitro_amount)
						var nitro_x: float = terrain.route_meter_to_world_x(entity_meter)
						terrain.spawn_event_feedback(nitro_x, terrain.height_at(nitro_x), "pickup", 1.0)
						_trigger_camera_shake(2.0, 0.10)
						_play_audio("pickup")
						_haptic_feedback(22, 0.8)
						_set_toast("Nitrokanister  +%d%%" % int(nitro_found) if nitro_found > 0.0 else "Boost ist bereits voll")
				else:
					_set_toast("Nitrokanister knapp verfehlt!")
			"repair":
				if not wagon.airborne:
					var repair_amount: float = float(entity.get("amount", 30.0))
					run_repair_pickups += 1
					var repaired: float = minf(repair_amount, 100.0 - wagon.durability)
					wagon.durability = minf(100.0, wagon.durability + repair_amount)
					var repair_x: float = terrain.route_meter_to_world_x(entity_meter)
					terrain.spawn_event_feedback(repair_x, terrain.height_at(repair_x), "pickup", 0.75)
					if repaired > 0.0:
						_play_audio("pickup")
						_haptic_feedback(24, 0.8)
						_set_toast("Werkzeugkiste  +%d%% ZUSTAND" % int(repaired))
					else:
						_set_toast("Werkzeugkiste, Zustand ist voll")
				else:
					_set_toast("Werkzeugkiste knapp verfehlt!")
			"fuel":
				if not wagon.airborne:
					var fuel_amount: float = float(entity.get("amount", 18.0))
					var fuel_found: float = minf(fuel_amount, wagon.fuel_capacity - wagon.fuel)
					wagon.fuel = minf(wagon.fuel_capacity, wagon.fuel + fuel_amount)
					var fuel_x: float = terrain.route_meter_to_world_x(entity_meter)
					terrain.spawn_event_feedback(fuel_x, terrain.height_at(fuel_x), "pickup", 0.75)
					_trigger_camera_shake(2.0, 0.10)
					_play_audio("pickup")
					_haptic_feedback(22, 0.8)
					_set_toast("Ersatzkanister  +%d" % int(fuel_found) if fuel_found > 0.0 else "Ersatzkanister, Tank ist voll")
				else:
					_set_toast("Kanister knapp verfehlt!")
			_:
				if not wagon.airborne:
					wagon.hit_obstacle()
					var impact_x: float = terrain.route_meter_to_world_x(entity_meter)
					terrain.spawn_event_feedback(impact_x, terrain.height_at(impact_x), "obstacle", 1.1)
					_trigger_camera_shake(clampf(absf(wagon.speed_mps) * 0.22, 3.0, 8.0), 0.18)
					_play_audio("impact")
					_haptic_feedback(35, 1.0)
					_set_toast("Achtung, Hindernis!")
				else:
					_set_toast("Sauber übersprungen!")

func _zombie_group_spatial_contact(entity: Dictionary, authored_x: float, chase_offset_px: float, group_size: int, group_spacing: float, zombie_profile: Dictionary) -> Dictionary:
	var visual_height: float = float(zombie_profile.get("visual_height", 78.0))
	var hit_width: float = visual_height * 0.62
	var ground_half_height: float = visual_height * 0.84
	var best_contact_x: float = authored_x - chase_offset_px
	for member_index in range(group_size):
		var member_x: float = authored_x - chase_offset_px + float(member_index) * group_spacing - float(group_size - 1) * group_spacing * 0.5
		var member_ground: float = terrain.height_at(member_x)
		var zombie_body: Rect2 = Rect2(Vector2(member_x - hit_width * 0.5, member_ground - ground_half_height), Vector2(hit_width, ground_half_height))
		if wagon.chassis_overlaps_world_rect(zombie_body):
			best_contact_x = member_x
			return {"overlap": true, "x": best_contact_x}
	return {"overlap": false, "x": best_contact_x}

func _entity_obstacle_rect(entity: Dictionary) -> Rect2:
	var entity_meter: float = float(entity.get("meter", 0.0))
	var world_x: float = float(entity["draw_world_x"]) if entity.has("draw_world_x") else terrain.route_meter_to_world_x(entity_meter)
	var ground_y: float = float(entity["draw_ground_y"]) if entity.has("draw_ground_y") else terrain.height_at(world_x)
	if String(entity.get("kind", "")) == "barrel":
		return Rect2(Vector2(world_x - 13.0, ground_y - 31.0), Vector2(26.0, 31.0))
	return Rect2(Vector2(world_x - 33.0, ground_y - 38.0), Vector2(66.0, 38.0))

func _resolve_weighted_obstacle(entity: Dictionary, obstacle_rect: Rect2) -> void:
	var resistance: float = float(entity.get("impact_weight", 0.32 if String(entity.get("kind", "")) == "barrel" else 0.95))
	var impact: Dictionary = wagon.hit_weighted_obstacle(resistance, true)
	var impact_x: float = obstacle_rect.get_center().x
	var impact_y: float = obstacle_rect.position.y
	terrain.spawn_event_feedback(impact_x, impact_y, "destruction", lerpf(0.7, 1.25, clampf(resistance, 0.0, 1.0)))
	var impact_speed: float = float(impact.get("speed_before_mps", absf(wagon.speed_mps)))
	_trigger_camera_shake(clampf(impact_speed * lerpf(0.17, 0.27, resistance), 2.0, 10.0), lerpf(0.12, 0.24, resistance))
	_play_audio("impact")
	_haptic_feedback(24 + int(resistance * 15.0), 0.65 + resistance * 0.3)
	var label: String = "TONNE GIBT NACH" if String(entity.get("kind", "")) == "barrel" else "WRACK BREMST HART"
	_set_toast("%s · -%.0f KM/H · -%.0f%% ZUSTAND" % [label, float(impact.get("speed_loss_kmh", 0.0)), float(impact.get("damage", 0.0))])

func _zombie_latch_profile(entity: Dictionary, member_index: int) -> Dictionary:
	var zombie_class: String = String(entity.get("class", "slow"))
	var seeded_roll: int = posmod(int(entity.get("meter", 0.0)) * 31 + member_index * 17 + run_world_index * 53, 100)
	if entity.has("variant_id"):
		return ZOMBIE_DATA.latch_profile(int(entity.get("variant_id", 1)), seeded_roll)
	if zombie_class == "robust":
		if seeded_roll < 18:
			return {}
		if seeded_roll < 46:
			return {"duration": 2.0, "drag": 0.95, "damage": 1.0}
		if seeded_roll < 75:
			return {"duration": 3.4, "drag": 1.7, "damage": 1.8}
		return {"duration": 5.0, "drag": 2.8, "damage": 2.8}
	if zombie_class == "fast":
		if seeded_roll < 28:
			return {}
		if seeded_roll < 64:
			return {"duration": 0.9, "drag": 0.8, "damage": 0.7}
		if seeded_roll < 88:
			return {"duration": 1.8, "drag": 1.5, "damage": 1.4}
		return {"duration": 2.8, "drag": 2.5, "damage": 2.2}
	if seeded_roll < 38:
		return {}
	if seeded_roll < 82:
		return {"duration": 1.5, "drag": 0.8, "damage": 0.55}
	if seeded_roll < 96:
		return {"duration": 2.5, "drag": 1.45, "damage": 1.0}
	return {"duration": 3.5, "drag": 2.25, "damage": 1.6}

func _resolve_setpiece_hazard(entity: Dictionary) -> void:
	run_hazard_passed = true
	var hazard_label: String = String(entity.get("hazard_label", "Straßengefahr"))
	run_hazard_hits += 1
	var durability_before: float = wagon.durability
	var impact_speed: float = absf(wagon.speed_mps)
	wagon.hit_road_hazard(float(entity.get("speed_retention", 0.68)), float(entity.get("damage", 0.0)), true)
	var hazard_x: float = terrain.route_meter_to_world_x(float(entity.get("meter", 0.0)))
	var break_reward: int = int(entity.get("break_reward", 0))
	terrain.spawn_event_feedback(hazard_x, terrain.height_at(hazard_x) - 18.0, "destruction" if break_reward > 0 else "obstacle", clampf(0.78 + impact_speed / 45.0, 0.8, 1.5))
	var damage_taken: int = int(round(durability_before - wagon.durability))
	_trigger_camera_shake(clampf(impact_speed * (0.21 if break_reward > 0 else 0.18), 3.0, 11.0), 0.19 if break_reward > 0 else 0.15)
	_play_audio("impact")
	_haptic_feedback(32, 0.95)
	break_reward = break_reward if not wagon.airborne else 0
	if break_reward > 0:
		run_collectible_reward += break_reward
		terrain.spawn_event_feedback(hazard_x, terrain.height_at(hazard_x) - 24.0, "pickup", 0.85)
		_play_audio("pickup")
		_set_toast("DURCHBRUCH · +%d MÜNZEN · -%d%% ZUSTAND" % [break_reward, damage_taken])
	else:
		_set_toast("%s · -%d%% ZUSTAND" % [hazard_label.to_upper(), damage_taken] if damage_taken > 0 else "%s · TEMPO VERLOREN" % hazard_label.to_upper())

func _finish_run(reached_goal: bool) -> void:
	if screen_state != "RUN":
		return
	clear_touch_actions()
	_reset_camera_shake()
	paused = false
	wagon.freeze = true
	var current_meter: float = minf(route_length_m, _meter_at(wagon.position.x))
	run_distance = maxf(0.0, current_meter - run_start_meter)
	if not run_is_final_rescue:
		campaign_meter = maxf(campaign_meter, current_meter)
		world_best_distances[run_world_index] = maxf(world_best_distances[run_world_index], campaign_meter)
	var route_completed: bool = reached_goal or (not run_is_final_rescue and campaign_meter >= route_length_m) or (run_is_final_rescue and current_meter >= route_length_m)
	run_challenge_success = route_completed and _challenge_requirements_met()
	run_challenge_reward = 0
	if run_challenge_success:
		if run_is_final_rescue:
			if not final_rescue_challenge_completed:
				final_rescue_challenge_completed = true
				run_challenge_reward = int(CHALLENGE_DATA.RESCUE_CHALLENGE["reward"])
		elif not world_challenge_completed[run_world_index]:
			world_challenge_completed[run_world_index] = true
			run_challenge_reward = int(CHALLENGE_DATA.WORLD_CHALLENGES[run_world_index]["reward"])
	run_reward = int(floor(run_distance / 16.0)) + run_zombie_reward + run_collectible_reward + run_checkpoint_reward
	money += run_reward + run_challenge_reward
	if reached_goal or (not run_is_final_rescue and campaign_meter >= route_length_m) or (run_is_final_rescue and current_meter >= route_length_m):
		if run_is_final_rescue:
			final_rescue_completed = true
			ending_sequence_seen = false
			ending_elapsed = 0.0
			screen_state = "ENDING"
		else:
			campaign_meter = route_length_m
			world_best_distances[run_world_index] = route_length_m
			world_completed_flags[run_world_index] = true
			if run_world_index < PLAYABLE_WORLD_COUNT - 1:
				unlocked_world_index = maxi(unlocked_world_index, run_world_index + 1)
			screen_state = "LEVEL_COMPLETE"
			_unlock_vehicles_for_world(run_world_index, false)
	else:
		screen_state = "RESULT"
	_save_progress()
	_set_camera(1.0, true)

func _meter_at(world_x: float) -> float:
	return maxf(0.0, world_x / PIXELS_PER_METER - START_OFFSET_M)

func _set_camera(delta: float, force_update: bool = false) -> void:
	var desired: Vector2
	var showcase: bool = screen_state in ["MENU", "GARAGE"]
	if wagon.showcase_shadow != showcase:
		wagon.showcase_shadow = showcase
		wagon.queue_redraw()
		backdrop.queue_redraw()
	var target_zoom: Vector2 = Vector2.ONE
	if screen_state == "RUN":
		var speed_kmh: float = absf(wagon.speed_mps) * 3.6
		var speed_fraction: float = clampf((speed_kmh - 24.0) / 104.0, 0.0, 1.0)
		# Keep the Kombi close to the reference scale while reserving a clear
		# run-up and landing view ahead of the bumper.
		var camera_lead: float = 266.0 + speed_fraction * 24.0 + (8.0 if wagon.boost_active else 0.0)
		var camera_target_y: float = wagon.position.y - 42.0
		if wagon.airborne:
			# Let the car rise into the upper part of the view instead of following
			# every pixel of the jump. This keeps the landing road and approach visible.
			var road_under_wagon: float = terrain.height_at(wagon.position.x)
			var jump_clearance: float = maxf(0.0, road_under_wagon - wagon.position.y)
			camera_target_y += jump_clearance * 0.52
		desired = Vector2(wagon.position.x + camera_lead, camera_target_y)
	elif showcase:
		var menu: bool = screen_state == "MENU"
		var viewport_size: Vector2 = get_viewport_rect().size
		var zoom_level: float = GARAGE_CAMERA_ZOOM * minf(1.0, viewport_size.y / 720.0)
		target_zoom = Vector2.ONE * zoom_level
		var car_anchor := Vector2(0.68, 0.72) if menu else Vector2(0.355, 0.64)
		desired = wagon.position + (Vector2(0.5, 0.5) - car_anchor) * viewport_size / zoom_level
	else:
		desired = Vector2(wagon.position.x + 180.0, 405.0)
	var weight: float = 1.0 if delta >= 0.9 else 1.0 - exp(-13.0 * maxf(delta, 0.0))
	terrain.visible = not showcase
	camera.position = camera.position.lerp(desired, weight)
	if screen_state == "RUN":
		var speed_fraction: float = clampf(absf(wagon.speed_mps) / 40.0, 0.0, 1.0)
		var zoom_level: float = lerpf(1.31, 1.22, speed_fraction) - (0.025 if wagon.boost_active else 0.0)
		target_zoom = Vector2.ONE * zoom_level
	camera.zoom = camera.zoom.lerp(target_zoom, 1.0 - exp(-7.0 * maxf(delta, 0.0)))
	if force_update:
		camera.force_update_scroll()

func _trigger_camera_shake(strength: float, duration: float) -> void:
	_camera_shake_strength = maxf(_camera_shake_strength, strength)
	_camera_shake_duration = maxf(_camera_shake_duration, duration)
	_camera_shake_time = maxf(_camera_shake_time, duration)
	if QA_DIAGNOSTICS.enabled():
		print("[FEEDBACK] camera_shake strength=%.1f duration=%.2fs" % [strength, duration])

func _update_camera_shake(delta: float) -> void:
	if _camera_shake_time <= 0.0:
		camera.offset = Vector2.ZERO
		return
	_camera_shake_time = maxf(0.0, _camera_shake_time - delta)
	if _camera_shake_time <= 0.0:
		_reset_camera_shake()
		return
	_camera_shake_phase += delta * 72.0
	var fade: float = _camera_shake_time / maxf(0.01, _camera_shake_duration)
	camera.offset = Vector2(sin(_camera_shake_phase * 1.31), cos(_camera_shake_phase * 1.87)) * _camera_shake_strength * fade

func _reset_camera_shake() -> void:
	_camera_shake_time = 0.0
	_camera_shake_duration = 0.0
	_camera_shake_strength = 0.0
	camera.offset = Vector2.ZERO

func _set_toast(message: String) -> void:
	toast_text = message
	toast_time = 2.0

func _stock_start_is_pending() -> bool:
	if OS.get_environment("ZEE_AUTOMATED_QA") == "1":
		return false
	for candidate_path in [SAVE_PATH, SAVE_TEMP_PATH, SAVE_BACKUP_PATH]:
		var candidate: ConfigFile = _read_valid_progress_config(candidate_path)
		if candidate != null and bool(candidate.get_value("testing", "stock_start_seen", false)):
			return false
	return true


func _finish_tuning_trial() -> void:
	tuning_trial_mode = false
	stock_test_mode = false
	_stock_test_saved_vehicle = ""
	_stock_test_saved_upgrades.clear()
	_stock_test_saved_money = -1
	wagon.set_stock_test_mode(false)
	tuning_trial_seen = true

func _stock_upgrade_levels() -> Dictionary:
	var levels := {}
	for part in UPGRADE_PARTS:
		levels[part] = 0
	return levels

func _activate_stock_test_mode(test_upgrades: Dictionary = {}) -> void:
	stock_test_mode = true
	_stock_test_saved_vehicle = selected_vehicle
	_stock_test_saved_money = money
	var stored_levels: Variant = vehicle_upgrades.get(selected_vehicle, upgrades)
	_stock_test_saved_upgrades = stored_levels.duplicate(true) if stored_levels is Dictionary else upgrades.duplicate(true)
	upgrades = _stock_upgrade_levels() if test_upgrades.is_empty() else test_upgrades.duplicate(true)
	if is_instance_valid(wagon):
		wagon.configure(upgrades, selected_vehicle)
		wagon.set_weapon_active(selected_world_index in [0, 1, 2] and selected_vehicle == "kombi")
		wagon.set_stock_test_mode(true)
	_save_progress()
	toast_text = "TUNING-TEST · TEILE KOSTENLOS AUSPROBIEREN"
	toast_time = 4.5
	if QA_DIAGNOSTICS.enabled():
		print("[STOCK_TEST] vehicle=%s saved_upgrades_preserved=true" % selected_vehicle)

func _play_audio(effect: String) -> void:
	if is_instance_valid(audio_manager):
		audio_manager.play_effect(effect)

func _load_progress() -> void:
	var primary_config: ConfigFile = _read_valid_progress_config(SAVE_PATH)
	var temp_config: ConfigFile = _read_valid_progress_config(SAVE_TEMP_PATH)
	var backup_config: ConfigFile = _read_valid_progress_config(SAVE_BACKUP_PATH)
	var config: ConfigFile = primary_config
	var source_path: String = SAVE_PATH if primary_config != null else ""
	if primary_config != null:
		if temp_config != null and _progress_config_generation(temp_config) > _progress_config_generation(primary_config):
			config = temp_config
			source_path = SAVE_TEMP_PATH
	else:
		var fallback_config: ConfigFile = temp_config
		var fallback_path: String = SAVE_TEMP_PATH if temp_config != null else ""
		if backup_config != null and (fallback_config == null or _progress_config_generation(backup_config) > _progress_config_generation(fallback_config)):
			fallback_config = backup_config
			fallback_path = SAVE_BACKUP_PATH
		config = fallback_config
		source_path = fallback_path
	if config == null:
		_last_progress_load_source = "defaults"
		_save_generation = 0
		var found_save_file: bool = false
		for candidate_path in [SAVE_PATH, SAVE_TEMP_PATH, SAVE_BACKUP_PATH]:
			found_save_file = found_save_file or FileAccess.file_exists(candidate_path)
		if found_save_file:
			_set_toast("Spielstand nicht lesbar · neues Profil gestartet")
		if QA_DIAGNOSTICS.enabled():
			print("[SAVE_RECOVERY] source=defaults reason=no_valid_save")
		return
	_save_generation = _progress_config_generation(config)
	_last_progress_load_source = "primary" if source_path == SAVE_PATH else ("temporary" if source_path == SAVE_TEMP_PATH else "backup")
	if source_path != SAVE_PATH:
		var recovery_error: Error = _restore_progress_file(source_path)
		if recovery_error == OK:
			_set_toast("Spielstand aus Sicherung wiederhergestellt")
		else:
			_set_toast("Spielstand geladen · Sicherung wird erneut geschrieben")
		if QA_DIAGNOSTICS.enabled():
			print("[SAVE_RECOVERY] source=%s generation=%d restore_error=%d" % [_last_progress_load_source, _save_generation, recovery_error])
	money = maxi(0, int(config.get_value("progress", "money", 100)))
	tuning_trial_seen = bool(config.get_value("testing", "upgrade_trial_seen", false))
	master_volume = clampf(float(config.get_value("settings", "master_volume", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("settings", "music_volume", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	haptic_strength = clampf(float(config.get_value("settings", "haptic_strength", DEFAULT_HAPTIC_STRENGTH)), 0.0, 1.0)
	var saved_schema: int = int(config.get_value("campaign", "schema", 0))
	first_drive_tutorial_completed = bool(config.get_value("tutorial", "first_drive_completed", saved_schema < FIRST_DRIVE_TUTORIAL_SCHEMA))
	var saved_story_logs: Variant = config.get_value("campaign", "collected_story_logs", PackedByteArray())
	if saved_story_logs is Array or saved_story_logs is PackedByteArray:
		for index in range(mini(collected_story_logs.size(), saved_story_logs.size())):
			collected_story_logs[index] = bool(saved_story_logs[index])
	var previously_unlocked_world_index: int = 0
	var has_campaign_progress: bool = saved_schema >= 2
	if has_campaign_progress:
		previously_unlocked_world_index = maxi(0, int(config.get_value("campaign", "unlocked_world", 0)))
		unlocked_world_index = clampi(previously_unlocked_world_index, 0, CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() - 1)
		selected_world_index = clampi(int(config.get_value("campaign", "selected_world", unlocked_world_index)), 0, unlocked_world_index)
		final_rescue_unlocked = bool(config.get_value("campaign", "final_rescue_unlocked", false))
		final_rescue_completed = bool(config.get_value("campaign", "final_rescue_completed", false)) if saved_schema >= 3 else false
		ending_sequence_seen = bool(config.get_value("campaign", "ending_sequence_seen", false)) if saved_schema >= 7 else false
		if saved_schema >= 4:
			final_rescue_challenge_completed = bool(config.get_value("campaign", "final_rescue_challenge_completed", false))
		var saved_ids: PackedStringArray = config.get_value("campaign", "world_ids", PackedStringArray(["amsterdam"]))
		if config.has_section_key("campaign", "selected_world_id"):
			var saved_city := String(config.get_value("campaign", "selected_world_id"))
			selected_world_index = maxi(0, CAMPAIGN_DATA.world_index_for_id(saved_city))
		var saved_distances: Variant = config.get_value("campaign", "best_distances", [])
		var saved_completed: Variant = config.get_value("campaign", "completed_worlds", [])
		var saved_challenges: Variant = config.get_value("campaign", "completed_challenges", [])
		for index in range(world_best_distances.size()):
			var source := saved_ids.find(String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[index].id))
			if source < 0:
				continue
			if (saved_distances is Array or saved_distances is PackedFloat32Array or saved_distances is PackedFloat64Array) and source < saved_distances.size():
				world_best_distances[index] = maxf(0.0, float(saved_distances[source]))
			if (saved_completed is Array or saved_completed is PackedByteArray) and source < saved_completed.size():
				world_completed_flags[index] = bool(saved_completed[source])
			if saved_schema >= 4 and (saved_challenges is Array or saved_challenges is PackedByteArray) and source < saved_challenges.size():
				world_challenge_completed[index] = bool(saved_challenges[source])
		campaign_meter = world_best_distances[selected_world_index]
	else:
		# Older saves used one combined route meter. Keep migration bounded to the
		# sole active Amsterdam route; campaign progress is reset below while the
		# player's coins and purchased vehicle upgrades remain intact.
		var legacy_meter: float = clampf(float(config.get_value("progress", "meters", 0.0)), 0.0, ROUTE_LENGTH_M)
		selected_world_index = 0
		unlocked_world_index = 0
		campaign_meter = minf(legacy_meter, float(CAMPAIGN_DATA.CAMPAIGN_WORLDS[0]["length_m"]))
		world_best_distances[0] = campaign_meter
		world_completed_flags[0] = campaign_meter >= float(CAMPAIGN_DATA.CAMPAIGN_WORLDS[0]["length_m"])
	# This campaign revision intentionally starts Amsterdam over from zero. Keep
	# durable player property (money, settings, vehicle unlocks and upgrades),
	# while dropping route completion and obsolete-city progress only once.
	if saved_schema < CAMPAIGN_SAVE_SCHEMA:
		selected_world_index = 0
		unlocked_world_index = 0
		campaign_meter = 0.0
		for index in range(world_best_distances.size()):
			world_best_distances[index] = 0.0
			world_completed_flags[index] = false
			world_challenge_completed[index] = false
		final_rescue_unlocked = false
		final_rescue_completed = false
		final_rescue_challenge_completed = false
		ending_sequence_seen = false
	var legacy_upgrades: Dictionary = {}
	for part in UPGRADE_PARTS:
		legacy_upgrades[part] = clampi(int(config.get_value("upgrades", part, 0)), 0, int(UPGRADE_MAX[part]))
	var saved_vehicle_upgrades: Variant = config.get_value("vehicles", "upgrades") if config.has_section_key("vehicles", "upgrades") else null
	if saved_vehicle_upgrades is Dictionary:
		for vehicle_id in CAMPAIGN_DATA.VEHICLE_ORDER:
			var saved_levels: Variant = saved_vehicle_upgrades.get(vehicle_id, {})
			var sanitized_levels: Dictionary = {}
			for part in UPGRADE_PARTS:
				var fallback_level: int = int(legacy_upgrades[part]) if vehicle_id == "kombi" else 0
				var raw_level: int = int(saved_levels.get(part, fallback_level)) if saved_levels is Dictionary else fallback_level
				sanitized_levels[part] = clampi(raw_level, 0, int(UPGRADE_MAX[part]))
			vehicle_upgrades[vehicle_id] = sanitized_levels
	else:
		vehicle_upgrades["kombi"] = legacy_upgrades.duplicate(true)
		for vehicle_id in CAMPAIGN_DATA.VEHICLE_ORDER:
			if vehicle_id != "kombi":
				vehicle_upgrades[vehicle_id] = {"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0, "weapon": 0}
	unlocked_vehicles.clear()
	var saved_unlocks: Variant = config.get_value("vehicles", "unlocked", PackedStringArray(["kombi"]))
	if saved_unlocks is Array or saved_unlocks is PackedStringArray:
		for raw_vehicle_id in saved_unlocks:
			var vehicle_id: String = String(raw_vehicle_id)
			if CAMPAIGN_DATA.VEHICLES.has(vehicle_id) and not unlocked_vehicles.has(vehicle_id):
				unlocked_vehicles.append(vehicle_id)
	if not unlocked_vehicles.has("kombi"):
		unlocked_vehicles.push_front("kombi")
	var migrated_vehicle_unlock: bool = false
	for vehicle_id in CAMPAIGN_DATA.VEHICLE_ORDER:
		var vehicle: Dictionary = CAMPAIGN_DATA.VEHICLES[vehicle_id]
		if previously_unlocked_world_index > int(vehicle.get("unlock_world", 0)):
			migrated_vehicle_unlock = _unlock_vehicle(vehicle_id) or migrated_vehicle_unlock
	var saved_selected_vehicle: String = String(config.get_value("vehicles", "selected", "kombi"))
	selected_vehicle = saved_selected_vehicle if is_vehicle_unlocked(saved_selected_vehicle) else "kombi"
	var selected_levels: Variant = vehicle_upgrades.get(selected_vehicle, legacy_upgrades)
	upgrades = selected_levels.duplicate(true) if selected_levels is Dictionary else legacy_upgrades.duplicate(true)
	if migrated_vehicle_unlock or saved_schema < CAMPAIGN_SAVE_SCHEMA:
		_save_progress()

func save_amsterdam_drive_reward(amount: int, completed: bool = false) -> int:
	return save_route_drive_reward("amsterdam", amount, 1800.0 if completed else 0.0, completed)

func save_route_drive_reward(city_id: String, amount: int, distance: float, completed: bool) -> int:
	var index := CAMPAIGN_DATA.world_index_for_id(city_id)
	if index < 0:
		return -1
	_initialize_world_progress()
	_load_progress()
	var length: float = float(world_data(index).length_m)
	money += amount
	world_best_distances[index] = maxf(world_best_distances[index], clampf(distance, 0.0, length))
	if completed:
		world_completed_flags[index] = true
		world_best_distances[index] = length
	return money if _save_progress() == OK else -1

func _save_progress() -> Error:
	var config := ConfigFile.new()
	var saved_meter: float = campaign_meter
	var saved_money: int = money
	if stock_test_mode and not tuning_trial_mode and _stock_test_saved_money >= 0:
		# Purchases in the stock test are temporary and never reduce saved coins.
		saved_money = _stock_test_saved_money
	if screen_state == "RUN":
		var saved_run_distance: float = 0.0
		if not run_is_final_rescue:
			saved_meter = maxf(saved_meter, _meter_at(wagon.position.x))
			saved_run_distance = maxf(0.0, saved_meter - run_start_meter)
			world_best_distances[run_world_index] = maxf(world_best_distances[run_world_index], saved_meter)
			if not (stock_test_mode and not tuning_trial_mode):
				saved_money += int(floor(saved_run_distance / 16.0)) + run_zombie_reward + run_collectible_reward + run_checkpoint_reward
	config.set_value("progress", "meters", saved_meter)
	config.set_value("progress", "money", saved_money)
	config.set_value("campaign", "schema", CAMPAIGN_SAVE_SCHEMA)
	var world_ids := PackedStringArray()
	for world in CAMPAIGN_DATA.CAMPAIGN_WORLDS:
		world_ids.append(String(world.id))
	config.set_value("campaign", "world_ids", world_ids)
	config.set_value("campaign", "selected_world_id", world_ids[selected_world_index])
	config.set_value("campaign", "selected_world", selected_world_index)
	config.set_value("campaign", "unlocked_world", unlocked_world_index)
	config.set_value("campaign", "best_distances", world_best_distances)
	var completed_bytes := PackedByteArray()
	for is_completed in world_completed_flags:
		completed_bytes.append(1 if is_completed else 0)
	config.set_value("campaign", "completed_worlds", completed_bytes)
	var challenge_bytes := PackedByteArray()
	for is_completed in world_challenge_completed:
		challenge_bytes.append(1 if is_completed else 0)
	config.set_value("campaign", "completed_challenges", challenge_bytes)
	var story_log_bytes := PackedByteArray()
	for is_collected in collected_story_logs:
		story_log_bytes.append(1 if is_collected else 0)
	config.set_value("campaign", "collected_story_logs", story_log_bytes)
	config.set_value("campaign", "final_rescue_unlocked", final_rescue_unlocked)
	config.set_value("campaign", "final_rescue_completed", final_rescue_completed)
	config.set_value("campaign", "final_rescue_challenge_completed", final_rescue_challenge_completed)
	config.set_value("campaign", "ending_sequence_seen", ending_sequence_seen)
	config.set_value("settings", "master_volume", master_volume)
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "haptic_strength", haptic_strength)
	config.set_value("tutorial", "first_drive_completed", first_drive_tutorial_completed)
	config.set_value("testing", "stock_start_seen", true)
	config.set_value("testing", "upgrade_trial_seen", tuning_trial_seen or tuning_trial_mode)
	config.set_value("testing", "upgrade_trial_active", tuning_trial_mode)
	config.set_value("testing", "upgrade_trial_revision", TUNING_TRIAL_RESET_REVISION if tuning_trial_seen or tuning_trial_mode else 0)
	var persisted_upgrades: Dictionary = upgrades
	var persisted_vehicle: String = selected_vehicle
	if stock_test_mode:
		persisted_upgrades = _stock_test_saved_upgrades.duplicate(true)
		persisted_vehicle = _stock_test_saved_vehicle
		vehicle_upgrades[persisted_vehicle] = persisted_upgrades.duplicate(true)
	else:
		vehicle_upgrades[selected_vehicle] = upgrades.duplicate(true)
	config.set_value("vehicles", "selected", persisted_vehicle)
	config.set_value("vehicles", "unlocked", PackedStringArray(unlocked_vehicles))
	config.set_value("vehicles", "upgrades", vehicle_upgrades.duplicate(true))
	for part in UPGRADE_PARTS:
		config.set_value("upgrades", part, int(persisted_upgrades.get(part, 0)))
	var save_error: Error = _save_progress_transactionally(config)
	if QA_DIAGNOSTICS.enabled():
		print("[PERF] save_result=%d generation=%d path=%s meters=%.2f" % [save_error, _save_generation, ProjectSettings.globalize_path(SAVE_PATH), saved_meter])
	return save_error

func _read_valid_progress_config(path: String) -> ConfigFile:
	if not FileAccess.file_exists(path):
		return null
	var candidate := ConfigFile.new()
	if candidate.load(path) != OK:
		return null
	var has_money: bool = candidate.has_section_key("progress", "money")
	var has_legacy_meter: bool = candidate.has_section_key("progress", "meters")
	var has_schema: bool = candidate.has_section_key("campaign", "schema")
	if not has_money and not has_legacy_meter and not has_schema:
		return null
	if has_money:
		var saved_money: Variant = candidate.get_value("progress", "money")
		if typeof(saved_money) != TYPE_INT and typeof(saved_money) != TYPE_FLOAT:
			return null
	if has_legacy_meter:
		var legacy_meter: Variant = candidate.get_value("progress", "meters")
		if typeof(legacy_meter) != TYPE_INT and typeof(legacy_meter) != TYPE_FLOAT:
			return null
	if has_schema:
		var saved_schema: Variant = candidate.get_value("campaign", "schema")
		if typeof(saved_schema) != TYPE_INT and typeof(saved_schema) != TYPE_FLOAT:
			return null
		if int(saved_schema) >= TRANSACTIONAL_SAVE_SCHEMA:
			if String(candidate.get_value(SAVE_INTEGRITY_SECTION, "complete", "")) != SAVE_INTEGRITY_MARKER:
				return null
			var generation: Variant = candidate.get_value(SAVE_INTEGRITY_SECTION, "generation", -1)
			if typeof(generation) != TYPE_INT or int(generation) < 1:
				return null
	if candidate.has_section_key(SAVE_INTEGRITY_SECTION, "generation"):
		var generation_value: Variant = candidate.get_value(SAVE_INTEGRITY_SECTION, "generation")
		if typeof(generation_value) != TYPE_INT or int(generation_value) < 1:
			return null
	return candidate

func _progress_config_generation(config: ConfigFile) -> int:
	if config == null:
		return 0
	return maxi(0, int(config.get_value(SAVE_INTEGRITY_SECTION, "generation", 0)))

func _restore_progress_file(source_path: String) -> Error:
	var file_bytes: PackedByteArray = FileAccess.get_file_as_bytes(source_path)
	if file_bytes.is_empty():
		return ERR_FILE_CORRUPT
	var target_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if target_file == null:
		return FileAccess.get_open_error()
	target_file.store_buffer(file_bytes)
	target_file.flush()
	target_file.close()
	return OK if _read_valid_progress_config(SAVE_PATH) != null else ERR_FILE_CORRUPT

func _save_progress_transactionally(config: ConfigFile) -> Error:
	var latest_generation: int = _save_generation
	var source_paths: Array[String] = [SAVE_PATH, SAVE_TEMP_PATH, SAVE_BACKUP_PATH]
	for source_path in source_paths:
		var source_config: ConfigFile = _read_valid_progress_config(source_path)
		if source_config != null:
			latest_generation = maxi(latest_generation, _progress_config_generation(source_config))
	var next_generation: int = latest_generation + 1
	config.set_value(SAVE_INTEGRITY_SECTION, "generation", next_generation)
	config.set_value(SAVE_INTEGRITY_SECTION, "complete", SAVE_INTEGRITY_MARKER)
	var temp_error: Error = config.save(SAVE_TEMP_PATH)
	if temp_error != OK:
		return temp_error
	if _read_valid_progress_config(SAVE_TEMP_PATH) == null:
		return ERR_FILE_CORRUPT

	var previous_primary: ConfigFile = _read_valid_progress_config(SAVE_PATH)
	if previous_primary != null:
		var backup_error: Error = previous_primary.save(SAVE_BACKUP_PATH)
		if backup_error != OK:
			return backup_error
		if _read_valid_progress_config(SAVE_BACKUP_PATH) == null:
			return ERR_FILE_CORRUPT
	elif FileAccess.file_exists(SAVE_PATH) and not FileAccess.file_exists(SAVE_CORRUPT_PATH):
		var preserve_error: Error = DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(SAVE_CORRUPT_PATH))
		if preserve_error != OK:
			return preserve_error

	var save_absolute_path: String = ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		var remove_error: Error = DirAccess.remove_absolute(save_absolute_path)
		if remove_error != OK:
			return remove_error
	var rename_error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_TEMP_PATH), save_absolute_path)
	if rename_error != OK:
		var backup_after_rename_error: ConfigFile = _read_valid_progress_config(SAVE_BACKUP_PATH)
		if backup_after_rename_error != null:
			_restore_progress_file(SAVE_BACKUP_PATH)
		return rename_error
	if _read_valid_progress_config(SAVE_PATH) == null:
		if not FileAccess.file_exists(SAVE_CORRUPT_PATH):
			DirAccess.copy_absolute(save_absolute_path, ProjectSettings.globalize_path(SAVE_CORRUPT_PATH))
		DirAccess.remove_absolute(save_absolute_path)
		var backup_after_commit_error: ConfigFile = _read_valid_progress_config(SAVE_BACKUP_PATH)
		if backup_after_commit_error != null:
			_restore_progress_file(SAVE_BACKUP_PATH)
		return ERR_FILE_CORRUPT
	_save_generation = next_generation
	return OK
