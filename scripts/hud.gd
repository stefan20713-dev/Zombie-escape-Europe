extends Control

const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const QA_DIAGNOSTICS = preload("res://scripts/qa_diagnostics.gd")
const REDRAW_INTERVAL_S: float = 1.0 / 30.0
const MOBILE_GESTURE_INSET: float = 48.0
const ENDING_SEQUENCE_DURATION_S: float = 12.0
const SPEEDOMETER_MAX_KMH: float = 160.0
const GARAGE_PARTS: Array[String] = ["engine", "tires", "tank", "armor", "nitro", "weapon"]
const GARAGE_LABELS: Dictionary = {"engine": "MOTOR", "tires": "REIFEN", "tank": "TANK", "armor": "PANZERUNG", "nitro": "NITRO", "weapon": "WAFFE"}
const TIRE_STAGE_NAMES: Array[String] = ["SERIENREIFEN", "MISCHPROFIL", "GELÄNDEPROFIL", "SCHWERER BEADLOCK"]
const TIRE_STAGE1_TEXTURE: Texture2D = preload("res://assets/kombi_wheel_tier1_0.7.0.png")
const TIRE_STAGE2_TEXTURE: Texture2D = preload("res://assets/kombi_wheel_0.6.0.png")
const TIRE_STAGE3_TEXTURE: Texture2D = preload("res://assets/kombi_wheel_tier3_0.7.0.png")
const ROUTE_OVERVIEW_TEXTURE: Texture2D = preload("res://assets/amsterdam_gameplay_panorama_0.5.56.png")
const HOOD_CANNON_TEXTURE: Texture2D = preload("res://assets/kombi_hood_cannon_0.9.0.png")
const FIRST_DRIVE_TUTORIAL_PAGES: Array[Dictionary] = [
	{
		"title": "GAS GEBEN UND BREMSEN",
		"body": "Halte GAS, um den Kombi in Bewegung zu halten. Lass GAS vor einer Gefahr los oder bremse, wenn du Tempo abbauen musst.",
		"mobile": "GAS unten rechts halten · BREMSEN oberhalb davon",
		"desktop": "W / ↑ halten = GAS · S / ↓ halten = BREMSEN"
	},
	{
		"title": "SPRÜNGE SICHER LANDEN",
		"body": "Nimm Schwung für Rampen und richte den Wagen in der Luft mit A und D aus. Lande möglichst auf beiden Rädern. Für die Schleuse brauchst du etwa 110 km/h beim Absprung. Motor II und Nitro I geben dir Reserve.",
		"mobile": "◀ / ▶ links am Bildschirm halten, solange der Wagen fliegt",
		"desktop": "A / D oder ← / → in der Luft halten"
	},
	{
		"title": "BENZIN UND BOOST",
		"body": "Gas verbraucht Treibstoff. Kaufe Nitro in der Werkstatt für zusätzlichen Schub. Wenn du die Nitro-Taste loslässt, füllt sich der Vorrat langsam wieder auf. Nutze Boost an Anstiegen und im Anlauf zum Schleusensprung.",
		"mobile": "BOOST-Taste rechts über GAS kurz halten",
		"desktop": "LEERTASTE halten = NITRO · loslassen = Vorrat erholt sich"
	},
	{
		"title": "MÜNZEN IN DER WERKSTATT",
		"body": "Für Amsterdam reichen MOTOR II, NITRO I und TANK I. REIFEN und PANZERUNG sind freiwillige Hilfen. Auch Fehlversuche bringen Münzen. Jeder Kauf verbessert nur seine Kategorie und bleibt gespeichert.",
		"mobile": "Fundstück sammeln · den Amsterdam-Eintrag später im Funkarchiv lesen",
		"desktop": "Werkstatt: Teil wählen, Nutzen und Preis prüfen, kaufen und erneut losfahren"
	}
]

var game
var ads_service: Node
var buttons: Array[Dictionary] = []
var active_touches: Dictionary = {}
var font: Font
var _redraw_elapsed: float = 0.0
var _first_draw_reported: bool = false
var _last_screen_state: String = ""
var _last_paused: bool = false
var _privacy_visible: bool = false
var _privacy_text: String = ""
var _first_drive_tutorial_page: int = 0
var _safe_area_insets: Vector4 = Vector4.ZERO
var _safe_area_reported: bool = false
var _safe_controls_reported: bool = false
var _garage_selected_part: String = "engine"
var _garage_settings_open: bool = false
var _journey_open: bool = false
var _part_transition: float = 1.0
var _upgrade_flash: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	game = get_node("../..")
	ads_service = get_node_or_null("/root/AdsService")
	font = ThemeDB.fallback_font
	_privacy_text = FileAccess.get_file_as_string("res://assets/privacy_policy_de.txt")
	if is_instance_valid(ads_service):
		ads_service.connect("rewarded_ads_changed", _on_rewarded_ads_changed)
		ads_service.connect("privacy_options_changed", _on_privacy_options_changed)
		ads_service.connect("rewarded_coins_earned", _on_rewarded_coins_earned)


func _on_rewarded_ads_changed() -> void:
	queue_redraw()


func _on_privacy_options_changed() -> void:
	queue_redraw()


func _on_rewarded_coins_earned(amount: int, failed_run_id: int) -> void:
	if is_instance_valid(game):
		game.grant_rewarded_video_coins(amount, failed_run_id)
		queue_redraw()

func _process(delta: float) -> void:
	if game!=null and game.screen_state=="GARAGE" and (_part_transition<1.0 or _upgrade_flash>0):
		_part_transition=minf(1.0,_part_transition+delta*5.0)
		_upgrade_flash=maxf(0.0,_upgrade_flash-delta)
		queue_redraw()
	if game != null and (game.screen_state != "RUN" or game.paused) and not active_touches.is_empty():
		_clear_game_control_touches()
	if game == null:
		return
	var current_screen_state: String = String(game.screen_state)
	var current_paused: bool = bool(game.paused)
	if current_screen_state != _last_screen_state or current_paused != _last_paused:
		if is_instance_valid(ads_service):
			if current_screen_state == "RESULT":
				ads_service.call("set_failure_context", game.run_attempt_id)
			elif _last_screen_state == "RESULT":
				ads_service.call("clear_failure_context")
		_last_screen_state = current_screen_state
		_last_paused = current_paused
		_redraw_elapsed = 0.0
		queue_redraw()
		return
	if current_screen_state != "RUN" or current_paused:
		return
	_redraw_elapsed += delta
	if _redraw_elapsed >= REDRAW_INTERVAL_S:
		_redraw_elapsed = 0.0
		queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		clear_active_touches()

func clear_active_touches() -> void:
	active_touches.clear()
	if is_instance_valid(game):
		game.clear_touch_actions()

func _clear_game_control_touches() -> void:
	if not is_instance_valid(game):
		return
	var control_touch_ids: Array[int] = []
	for touch_id in active_touches.keys():
		if game.touch_actions.has(String(active_touches[touch_id])):
			control_touch_ids.append(int(touch_id))
	for touch_id in control_touch_ids:
		var action: String = String(active_touches[touch_id])
		active_touches.erase(touch_id)
		game.touch_actions[action] = false
		if QA_DIAGNOSTICS.enabled():
			print("[PERF] touch_up=%s action=%s" % [touch_id, action])

func handle_system_back() -> bool:
	if _journey_open:
		_journey_open=false
		queue_redraw()
		return true
	if _privacy_visible:
		_privacy_visible = false
		queue_redraw()
		return true
	if is_instance_valid(game) and game.screen_state in ["MENU", "GARAGE"] and _garage_settings_open:
		_garage_settings_open = false
		queue_redraw()
		return true
	if is_instance_valid(game) and String(game.screen_state) == "ENDING":
		game.finish_ending_sequence()
		queue_redraw()
		return true
	if is_instance_valid(game) and game.is_first_drive_tutorial_active() and _first_drive_tutorial_page > 0:
		_first_drive_tutorial_page -= 1
		queue_redraw()
		return true
	return false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		_drag_at(event.position, event.index)
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_drag_at(event.position, -1)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Godot also synthesizes a mouse click for each Android/iOS touch. Ignore
		# that duplicate so a toggle control cannot pause and immediately resume.
		if OS.has_feature("android") or OS.has_feature("ios"):
			return
		if event.pressed:
			_press_at(event.position, -1)
		else:
			_release_touch(-1)
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_press_at(event.position, event.index)
		else:
			_release_touch(event.index)
		return

func _press_at(position: Vector2, touch_id: int) -> void:
	if game.is_first_drive_tutorial_active():
		for item in buttons:
			var tutorial_id: String = String(item["id"])
			var tutorial_rect: Rect2 = item["rect"]
			if not tutorial_id.begins_with("tutorial:") or not tutorial_rect.has_point(position):
				continue
			_handle_button(tutorial_id)
			queue_redraw()
			accept_event()
			return
		accept_event()
		return
	if QA_DIAGNOSTICS.enabled():
		print("[PERF] touch_down=%s" % position)
	for item in buttons:
		var hit_rect: Rect2 = item["rect"]
		if not hit_rect.has_point(position):
			continue
		var button_id: String = String(item["id"])
		if button_id.begins_with("touch:"):
			var action: String = button_id.trim_prefix("touch:")
			active_touches[touch_id] = action
			game.set_touch_action(action, true)
			if QA_DIAGNOSTICS.enabled():
				print("[PERF] touch_hit=%s" % action)
		elif button_id == "volume_slider":
			active_touches[touch_id] = button_id
			_update_volume_slider(position)
			if QA_DIAGNOSTICS.enabled():
				print("[PERF] touch_hit=%s" % button_id)
		elif button_id == "music_volume_slider":
			active_touches[touch_id] = button_id
			_update_music_volume_slider(position)
			if QA_DIAGNOSTICS.enabled():
				print("[PERF] touch_hit=%s" % button_id)
		elif button_id == "haptics_slider":
			active_touches[touch_id] = button_id
			_update_haptics_slider(position)
			if QA_DIAGNOSTICS.enabled():
				print("[PERF] touch_hit=%s" % button_id)
		else:
			if QA_DIAGNOSTICS.enabled():
				print("[PERF] touch_hit=%s" % button_id)
			_handle_button(button_id)
		queue_redraw()
		accept_event()
		return
	if QA_DIAGNOSTICS.enabled():
		print("[PERF] touch_miss=%s" % position)

func _release_touch(touch_id: int) -> void:
	if not active_touches.has(touch_id):
		return
	var released_action: String = String(active_touches[touch_id])
	if QA_DIAGNOSTICS.enabled():
		print("[PERF] touch_up=%s action=%s" % [touch_id, released_action])
	active_touches.erase(touch_id)
	var still_held: bool = false
	for active_action in active_touches.values():
		if String(active_action) == released_action:
			still_held = true
			break
	if not still_held:
		if game.touch_actions.has(released_action):
			game.set_touch_action(released_action, false)
		elif released_action == "volume_slider":
			game.set_master_volume(float(game.master_volume), true)
		elif released_action == "music_volume_slider":
			game.set_music_volume(float(game.music_volume), true)
		elif released_action == "haptics_slider":
			game.set_haptic_strength(float(game.haptic_strength), true)
	queue_redraw()
	accept_event()

func _drag_at(position: Vector2, touch_id: int) -> void:
	var active_action: String = String(active_touches.get(touch_id, ""))
	if active_action == "volume_slider":
		_update_volume_slider(position)
	elif active_action == "music_volume_slider":
		_update_music_volume_slider(position)
	elif active_action == "haptics_slider":
		_update_haptics_slider(position)
	else:
		return
	queue_redraw()
	accept_event()

func _update_volume_slider(position: Vector2) -> void:
	var left: float = get_size().x * 0.5 - 182.0
	var value: float = clampf((position.x - left) / 254.0, 0.0, 1.0)
	game.set_master_volume(value, false)

func _update_music_volume_slider(position: Vector2) -> void:
	var left: float = get_size().x * 0.5 - 182.0
	var value: float = clampf((position.x - left) / 254.0, 0.0, 1.0)
	game.set_music_volume(value, false)

func _update_haptics_slider(position: Vector2) -> void:
	var left: float = get_size().x * 0.5 - 182.0
	var value: float = clampf((position.x - left) / 254.0, 0.0, 1.0)
	game.set_haptic_strength(value, false)

func _handle_button(button_id: String) -> void:
	if button_id == "journey_open":
		_journey_open=true
		game._play_audio("ui")
	elif button_id == "journey_close":
		_journey_open=false
	elif button_id == "ending_skip":
		game.finish_ending_sequence()
	elif button_id == "tutorial:skip":
		game.complete_first_drive_tutorial()
	elif button_id == "tutorial:previous":
		_first_drive_tutorial_page = maxi(0, _first_drive_tutorial_page - 1)
	elif button_id == "tutorial:next":
		advance_first_drive_tutorial()
	elif button_id == "tutorial:start":
		game.complete_first_drive_tutorial()
		game.start_run()
	elif button_id == "start":
		game.start_run()
	elif button_id == "rescue_start":
		game.start_final_rescue()
	elif button_id == "garage":
		_garage_settings_open = false
		game.to_garage()
	elif button_id == "main_menu":
		_garage_settings_open = false
		game.open_main_menu()
	elif button_id == "pause":
		game.toggle_pause()
	elif button_id == "pause_open":
		game.set_paused(true)
	elif button_id == "pause_resume":
		game.set_paused(false)
	elif button_id == "restart_campaign":
		game.restart_campaign()
	elif button_id == "map_open":
		_journey_open=false
		game.open_world_map()
	elif button_id == "map_back":
		game.close_world_map()
	elif button_id == "archive_open":
		game.open_radio_archive()
	elif button_id == "archive_back":
		game.close_radio_archive()
	elif button_id.begins_with("story_select:"):
		game.select_story_log(int(button_id.trim_prefix("story_select:")))
	elif button_id.begins_with("world_select:"):
		var world_index: int = int(button_id.trim_prefix("world_select:"))
		game.select_campaign_world(world_index)
	elif button_id == "vehicle_next":
		game.select_next_vehicle()
	elif button_id == "volume_mute":
		game.toggle_master_mute()
	elif button_id == "music_volume_mute":
		game.toggle_music_mute()
	elif button_id == "haptics_toggle":
		game.toggle_haptics()
	elif button_id == "privacy_open":
		_privacy_visible = true
	elif button_id == "privacy_close":
		_privacy_visible = false
	elif button_id == "privacy_options":
		if is_instance_valid(ads_service):
			ads_service.call("show_privacy_options")
	elif button_id == "rewarded_coins":
		if is_instance_valid(ads_service):
			ads_service.call("show_rewarded_ad_for_current_failure")
	elif button_id == "upgrade":
		if game.buy_upgrade(_garage_selected_part, game.stock_test_mode):
			_upgrade_flash=0.75
			game._set_toast("%s STUFE %d EINGEBAUT" % [String(GARAGE_LABELS.get(_garage_selected_part,_garage_selected_part)),game.upgrade_level(_garage_selected_part)])
	elif button_id == "stock_test_toggle":
		game.toggle_stock_test_mode()
	elif button_id == "stock_test_open":
		game.open_stock_test_workshop()
	elif button_id == "stock_test_reset":
		game.reset_stock_test_upgrades()
		_garage_selected_part = "engine"
		_garage_settings_open = false
	elif button_id.begins_with("garage_part:"):
		var part: String = button_id.trim_prefix("garage_part:")
		if GARAGE_PARTS.has(part):
			_garage_selected_part = part
			_part_transition=0.0
		_garage_settings_open = false
	elif button_id == "garage_settings_toggle":
		_garage_settings_open = not _garage_settings_open
	elif button_id == "starter_package":
		game.buy_starting_hill_package()
	elif button_id.begins_with("upgrade:"):
		var parts: PackedStringArray = button_id.split(":")
		if parts.size() > 1:
			game.buy_upgrade(parts[1])

func _draw() -> void:
	if not _first_draw_reported:
		_first_draw_reported = true
		if QA_DIAGNOSTICS.enabled():
			print("[PERF] hud_first_draw_ms=%d" % Time.get_ticks_msec())
	buttons.clear()
	if game == null:
		return
	var size: Vector2 = get_size()
	_safe_area_insets = _read_safe_area_insets(size)
	if QA_DIAGNOSTICS.enabled() and game.mobile_target and not _safe_area_reported:
		_safe_area_reported = true
		print("[SAFE_AREA] logical_insets=%.1f,%.1f,%.1f,%.1f viewport=%.1fx%.1f" % [
			_safe_area_insets.x, _safe_area_insets.y, _safe_area_insets.z, _safe_area_insets.w, size.x, size.y
		])
	match String(game.screen_state):
		"MENU":
			_draw_main_menu(size)
		"GARAGE":
			_draw_garage(size)
			if _journey_open:_draw_journey_overlay(size)
		"MAP":
			_draw_world_map(size)
		"ARCHIVE":
			_draw_radio_archive(size)
		"RUN":
			_draw_run(size)
			_draw_run_notification(size)
			if game.paused:
				_draw_pause(size)
		"RESULT":
			_draw_result(size, false)
		"LEVEL_COMPLETE":
			_draw_result(size, true)
		"ENDING":
			_draw_ending_sequence(size)
		"WIN":
			_draw_result(size, true)
	if _privacy_visible:
		_draw_privacy(size)

func _read_safe_area_insets(size: Vector2) -> Vector4:
	if not OS.has_feature("android") and not OS.has_feature("ios"):
		return Vector4.ZERO
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	if safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return Vector4.ZERO
	var local_to_screen: Transform2D = get_viewport().get_screen_transform() * get_global_transform_with_canvas()
	if is_zero_approx(local_to_screen.determinant()):
		return Vector4.ZERO
	var screen_to_local: Transform2D = local_to_screen.affine_inverse()
	var screen_corners: Array[Vector2] = [
		Vector2(safe_area.position),
		Vector2(safe_area.end.x, safe_area.position.y),
		Vector2(safe_area.end),
		Vector2(safe_area.position.x, safe_area.end.y)
	]
	var first_point: Vector2 = screen_to_local * screen_corners[0]
	var safe_left: float = first_point.x
	var safe_top: float = first_point.y
	var safe_right: float = first_point.x
	var safe_bottom: float = first_point.y
	for index in range(1, screen_corners.size()):
		var point: Vector2 = screen_to_local * screen_corners[index]
		safe_left = minf(safe_left, point.x)
		safe_top = minf(safe_top, point.y)
		safe_right = maxf(safe_right, point.x)
		safe_bottom = maxf(safe_bottom, point.y)
	var inset_limit_x: float = size.x * 0.25
	var inset_limit_y: float = size.y * 0.25
	return Vector4(
		clampf(safe_left, 0.0, inset_limit_x),
		clampf(safe_top, 0.0, inset_limit_y),
		clampf(size.x - safe_right, 0.0, inset_limit_x),
		clampf(size.y - safe_bottom, 0.0, inset_limit_y)
	)

func _safe_bounds(size: Vector2) -> Rect2:
	return Rect2(
		Vector2(_safe_area_insets.x, _safe_area_insets.y),
		Vector2(maxf(0.0, size.x - _safe_area_insets.x - _safe_area_insets.z), maxf(0.0, size.y - _safe_area_insets.y - _safe_area_insets.w))
	)

func _draw_ending_sequence(size: Vector2) -> void:
	var width: float = size.x
	var height: float = size.y
	var elapsed: float = float(game.ending_elapsed)
	var phase: int = game.ending_sequence_phase()
	var sea_y: float = height * 0.625
	var ship_left: float = width * 0.535
	var ship_right: float = width * 0.94
	var ship_top: float = height * 0.285
	var bob: float = sin(elapsed * 1.7) * 2.0

	# Sunset sky and a quiet northern-to-southern European coastline.
	draw_rect(Rect2(Vector2.ZERO, size), Color8(28, 48, 59))
	draw_rect(Rect2(0.0, 0.0, width, height * 0.20), Color8(39, 61, 75))
	draw_rect(Rect2(0.0, height * 0.20, width, height * 0.20), Color8(76, 81, 82))
	draw_rect(Rect2(0.0, height * 0.40, width, height * 0.20), Color8(147, 111, 82))
	draw_circle(Vector2(width * 0.78, height * 0.31), minf(width, height) * 0.075, Color8(229, 174, 105, 205))
	for index in range(42):
		var star_x: float = fposmod(float(index) * 137.0 + 31.0, width)
		var star_y: float = fposmod(float(index) * 53.0 + 19.0, height * 0.34)
		var star_alpha: int = 85 + int((sin(elapsed * 1.2 + float(index)) + 1.0) * 42.0)
		draw_circle(Vector2(star_x, star_y), 1.2 if index % 4 == 0 else 0.8, Color8(245, 221, 177, star_alpha))

	# Low harbor skyline on the left.
	var city_base: float = sea_y - 19.0
	for index in range(17):
		var building_x: float = float(index) * width * 0.033 - 10.0
		var building_width: float = 23.0 + float(index % 3) * 8.0
		var building_height: float = 35.0 + float((index * 7) % 5) * 10.0
		draw_rect(Rect2(building_x, city_base - building_height, building_width, building_height), Color8(49, 62, 60, 235))
		for window_index in range(2):
			var lit: bool = (index + window_index * 3) % 4 != 0
			if lit:
				draw_rect(Rect2(building_x + 5.0 + float(window_index) * 10.0, city_base - building_height + 10.0, 4.0, 6.0), Color8(221, 173, 103, 185))
	# Water is drawn before the ship, dock, and survivors.
	draw_rect(Rect2(0.0, sea_y, width, height - sea_y), Color8(28, 58, 64))
	for index in range(22):
		var wave_x: float = fposmod(float(index) * width / 22.0 + elapsed * (15.0 + float(index % 3) * 4.0), width)
		var wave_y: float = sea_y + 16.0 + float((index * 29) % maxi(1, int(height - sea_y - 28.0)))
		var wave_length: float = 24.0 + float(index % 4) * 11.0
		draw_line(Vector2(wave_x, wave_y), Vector2(minf(width, wave_x + wave_length), wave_y), Color8(111, 146, 133, 90), 1.4, true)

	# Rescue vessel: dark hull, pale deck, lit cabin, mast, and moving beacon.
	var hull_points := PackedVector2Array([
		Vector2(ship_left, sea_y - 86.0 + bob), Vector2(ship_right, sea_y - 86.0 + bob),
		Vector2(ship_right - 30.0, sea_y + 17.0 + bob), Vector2(ship_left + 73.0, sea_y + 30.0 + bob),
		Vector2(ship_left + 20.0, sea_y + 4.0 + bob)
	])
	draw_colored_polygon(hull_points, Color8(33, 48, 49))
	draw_line(Vector2(ship_left + 5.0, sea_y - 79.0 + bob), Vector2(ship_right - 5.0, sea_y - 79.0 + bob), Color8(214, 173, 111), 5.0, true)
	var deck_points := PackedVector2Array([
		Vector2(ship_left + 31.0, sea_y - 91.0 + bob), Vector2(ship_right - 62.0, sea_y - 91.0 + bob),
		Vector2(ship_right - 88.0, ship_top + 30.0 + bob), Vector2(ship_left + 115.0, ship_top + 30.0 + bob)
	])
	draw_colored_polygon(deck_points, Color8(184, 177, 149))
	draw_rect(Rect2(ship_left + 142.0, ship_top - 21.0 + bob, 163.0, 53.0), Color8(112, 131, 120))
	draw_rect(Rect2(ship_left + 164.0, ship_top - 62.0 + bob, 99.0, 42.0), Color8(148, 157, 137))
	draw_rect(Rect2(ship_left + 173.0, ship_top - 51.0 + bob, 17.0, 12.0), Color8(245, 203, 125))
	draw_rect(Rect2(ship_left + 198.0, ship_top - 51.0 + bob, 17.0, 12.0), Color8(245, 203, 125))
	draw_rect(Rect2(ship_left + 223.0, ship_top - 51.0 + bob, 17.0, 12.0), Color8(245, 203, 125))
	draw_rect(Rect2(ship_left + 269.0, ship_top - 11.0 + bob, 21.0, 21.0), Color8(227, 190, 122))
	draw_line(Vector2(ship_left + 212.0, ship_top - 63.0 + bob), Vector2(ship_left + 212.0, ship_top - 111.0 + bob), Color8(69, 82, 76), 4.0, true)
	draw_line(Vector2(ship_left + 212.0, ship_top - 109.0 + bob), Vector2(ship_left + 246.0, ship_top - 100.0 + bob), Color8(210, 180, 130), 2.0, true)
	var beacon_alpha: int = 105 + int((sin(elapsed * 6.0) + 1.0) * 72.0)
	draw_circle(Vector2(ship_left + 212.0, ship_top - 112.0 + bob), 27.0, Color8(244, 197, 120, beacon_alpha / 3))
	draw_circle(Vector2(ship_left + 212.0, ship_top - 112.0 + bob), 6.0, Color8(255, 223, 156, beacon_alpha))
	for index in range(4):
		draw_circle(Vector2(ship_left + 63.0 + float(index) * 69.0, sea_y - 22.0 + bob), 6.0, Color8(221, 174, 96) if index % 2 == 0 else Color8(132, 174, 145))

	# The wooden pier meets the lowered rescue ramp.
	var pier_start := Vector2(width * 0.035, sea_y + 74.0)
	var pier_end := Vector2(ship_left + 72.0, sea_y + 20.0 + bob)
	draw_line(pier_start + Vector2(0.0, 17.0), pier_end + Vector2(0.0, 17.0), Color8(67, 54, 43), 28.0, true)
	draw_line(pier_start, pier_end, Color8(150, 119, 79), 19.0, true)
	draw_line(pier_start + Vector2(0.0, -7.0), pier_end + Vector2(0.0, -7.0), Color8(219, 183, 124), 3.0, true)
	for index in range(10):
		var fraction: float = float(index) / 10.0
		var plank := pier_start.lerp(pier_end, fraction)
		draw_line(plank + Vector2(-3.0, -8.0), plank + Vector2(4.0, 9.0), Color8(88, 72, 53), 2.0, true)
	var ramp_start := Vector2(ship_left + 35.0, sea_y - 69.0 + bob)
	var ramp_end := Vector2(ship_left + 73.0, sea_y + 12.0 + bob)
	draw_line(ramp_start, ramp_end, Color8(195, 172, 128), 13.0, true)
	draw_line(ramp_start, ramp_end, Color8(75, 83, 72), 2.0, true)

	# The orange Kombi waits at the end of the journey; survivors walk aboard.
	var car_x: float = width * 0.075
	var car_y: float = sea_y + 39.0
	if phase < 2:
		draw_rect(Rect2(car_x + 18.0, car_y - 37.0, 92.0, 34.0), Color8(171, 105, 64))
		draw_colored_polygon(PackedVector2Array([Vector2(car_x + 33.0, car_y - 38.0), Vector2(car_x + 51.0, car_y - 58.0), Vector2(car_x + 93.0, car_y - 58.0), Vector2(car_x + 111.0, car_y - 37.0)]), Color8(186, 125, 75))
		draw_rect(Rect2(car_x + 56.0, car_y - 53.0, 31.0, 14.0), Color8(117, 149, 143))
		draw_circle(Vector2(car_x + 43.0, car_y - 1.0), 13.0, Color8(27, 33, 31))
		draw_circle(Vector2(car_x + 43.0, car_y - 1.0), 6.0, Color8(173, 157, 115))
		draw_circle(Vector2(car_x + 98.0, car_y - 1.0), 13.0, Color8(27, 33, 31))
		draw_circle(Vector2(car_x + 98.0, car_y - 1.0), 6.0, Color8(173, 157, 115))
	var boarding_fraction: float = clampf((elapsed - 2.4) / 4.5, 0.0, 1.0)
	for index in range(3):
		var start_x: float = width * (0.205 + float(index) * 0.041)
		var finish_x: float = ship_left + 44.0
		var person_x: float = lerpf(start_x, finish_x, boarding_fraction)
		if phase < 2 or boarding_fraction < 1.0:
			_draw_ending_person(Vector2(person_x, sea_y + 38.0 + bob * 0.35), 1.0, Color8(60, 79, 67) if index != 1 else Color8(78, 93, 76), elapsed * 7.0 + float(index))

	# Story card and a visible opt-out that also works with touch.
	var safe_rect: Rect2 = _safe_bounds(size)
	var card_width: float = minf(775.0, safe_rect.size.x - 44.0)
	var card := Rect2(safe_rect.position.x + 22.0, safe_rect.end.y - 163.0, card_width, 140.0)
	_draw_panel(card, Color8(22, 33, 32, 242))
	var phase_label: String
	var title: String
	var body: String
	match phase:
		0:
			phase_label = "SÜDHAFEN · RETTUNG"
			title = "LEA · RETTUNGSTEAM"
			body = "Lea senkt die Rampe. Das Rettungsschiff nimmt das Lichtsignal auf."
		1:
			phase_label = "ÜBERLEBENDE AN BORD"
			title = "„WIR HABEN EUCH!“"
			body = "Die letzten Überlebenden verlassen den Kai und gehen an Bord."
		_:
			phase_label = "EUROPA VERBUNDEN"
			title = "DIE FLUCHT IST ZU ENDE"
			body = "Die Motoren starten. Hinter euch liegt die Flucht aus Amsterdam. Das Rettungsschiff bringt euch in Sicherheit."
	_draw_text(phase_label, card.position.x + 19.0, card.position.y + 25.0, 11, Color8(218, 174, 103))
	_draw_text(title, card.position.x + 19.0, card.position.y + 58.0, 23, Color8(240, 222, 185))
	draw_multiline_string(font, Vector2(card.position.x + 19.0, card.position.y + 84.0), body, HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 38.0, 15, 2, Color8(203, 211, 192))
	var progress_rect := Rect2(card.position.x + 19.0, card.end.y - 15.0, card.size.x - 38.0, 4.0)
	draw_rect(progress_rect, Color8(63, 72, 65))
	draw_rect(Rect2(progress_rect.position, Vector2(progress_rect.size.x * clampf(elapsed / ENDING_SEQUENCE_DURATION_S, 0.0, 1.0), progress_rect.size.y)), Color8(214, 169, 96))
	var skip_rect := Rect2(safe_rect.end.x - 190.0, safe_rect.end.y - 57.0, 168.0, 38.0)
	_draw_button(skip_rect, "WEITER  ›", "ending_skip", Color8(111, 83, 53))

func _draw_ending_person(center: Vector2, scale: float, color: Color, walk_phase: float) -> void:
	var swing: float = sin(walk_phase) * 5.0 * scale
	draw_circle(center + Vector2(0.0, -26.0 * scale), 6.0 * scale, Color8(204, 157, 111))
	draw_line(center + Vector2(0.0, -19.0 * scale), center + Vector2(0.0, -6.0 * scale), color, 7.0 * scale, true)
	draw_line(center + Vector2(0.0, -16.0 * scale), center + Vector2(-9.0 * scale, -9.0 * scale), color, 3.0 * scale, true)
	draw_line(center + Vector2(0.0, -16.0 * scale), center + Vector2(9.0 * scale, -10.0 * scale), color, 3.0 * scale, true)
	draw_line(center + Vector2(0.0, -6.0 * scale), center + Vector2(-5.0 * scale + swing, 0.0), color, 4.0 * scale, true)
	draw_line(center + Vector2(0.0, -6.0 * scale), center + Vector2(5.0 * scale - swing, 0.0), color, 4.0 * scale, true)

func _draw_main_menu(size: Vector2) -> void:
	var safe_rect: Rect2 = _safe_bounds(size)
	var left: float = safe_rect.position.x + 35.0
	var top: float = safe_rect.position.y
	var width: float = minf(335.0, safe_rect.size.x * 0.32)
	var title_size: int = mini(68, int(width * 0.215))
	var cream := Color8(246, 223, 171)
	for index in range(2):
		var title: String = "ZOMBIE" if index == 0 else "ESCAPE"
		var baseline := Vector2(left, top + 107.0 + float(index) * float(title_size) * 0.92)
		draw_string_outline(font, baseline, title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, title_size, 9, Color8(19, 17, 15))
		draw_string(font, baseline, title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, title_size, cream)
	var banner_y: float = top + 120.0 + float(title_size)
	draw_colored_polygon(PackedVector2Array([
		Vector2(left + 2.0, banner_y + 6.0), Vector2(left + width * 0.80, banner_y),
		Vector2(left + width * 0.74, banner_y + 42.0), Vector2(left, banner_y + 49.0)
	]), Color8(129, 42, 31))
	_draw_text("E U R O P E", left + 18.0, banner_y + 34.0, 25, cream)
	var city: String = String(game.world_data().get("city", "")).to_upper()
	var city_width: float = maxf(160.0, font.get_string_size(city, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 36.0)
	var city_rect := Rect2(safe_rect.end.x - city_width - 20.0, top + 21.0, city_width, 42.0)
	_draw_workshop_plate(city_rect)
	_draw_text(city, city_rect.position.x + 18.0, city_rect.position.y + 28.0, 18, cream)
	var button_y: float = maxf(banner_y + 75.0, safe_rect.get_center().y - 54.0)
	_draw_button(Rect2(left, button_y, width, 56.0), "▶  WEITERFAHREN", "garage", Color8(149, 84, 24))
	_draw_button(Rect2(left, button_y + 68.0, width, 54.0), "STRECKENKARTE", "map_open", Color8(28, 28, 25, 246))
	_draw_button(Rect2(left, button_y + 134.0, width, 54.0), "EINSTELLUNGEN", "garage_settings_toggle", Color8(28, 28, 25, 246))
	if game.can_test_stock_vehicle():
		var test_label := "TUNING-TEST FORTSETZEN" if game.stock_test_mode else "SERIENFAHRZEUG TESTEN"
		_draw_button(Rect2(left, button_y + 200.0, width, 54.0), test_label, "stock_test_open", Color8(53, 43, 32, 240))
	_draw_fitted_levels(Vector2(size.x * 0.68 - 107.0, safe_rect.end.y - 55.0))
	if _garage_settings_open:
		buttons.clear()
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.018, 0.018, 0.62))
		_draw_garage_settings(Rect2(safe_rect.get_center() - Vector2(180.0, 205.0), Vector2(360.0, 410.0)))

func _draw_workshop_plate(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(0.0, 4.0), rect.size), Color8(9, 7, 6, 120))
	draw_rect(rect, Color8(23, 25, 23, 246))
	draw_rect(rect.grow(-2.0), Color8(188, 141, 72, 220), false, 1.5)

func _draw_fitted_levels(origin: Vector2) -> void:
	var rect := Rect2(origin, Vector2(214.0, 32.0))
	_draw_workshop_plate(rect)
	var levels: String = "MOTOR %d   ·   TANK %d" % [game.upgrade_level("engine"), game.upgrade_level("tank")]
	draw_string(font, origin + Vector2(0.0, 22.0), levels, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13, Color8(236, 211, 157))

func _draw_garage(size: Vector2) -> void:
	var safe_rect: Rect2 = _safe_bounds(size)
	var left: float = safe_rect.position.x + 18.0
	var top: float = safe_rect.position.y + 14.0
	var right: float = safe_rect.end.x - 18.0
	var footer_y: float = safe_rect.end.y - 98.0
	var detail_width: float = minf(345.0, safe_rect.size.x * 0.30)
	var panel_x: float = right - detail_width
	var cream := Color8(246, 223, 171)
	_draw_button(Rect2(left, top, 136.0, 44.0), "‹  HAUPTMENÜ", "main_menu", Color8(35, 34, 28, 244))
	_draw_button(Rect2(left + 145.0, top, 99.0, 44.0), "KARTE", "map_open", Color8(35, 34, 28, 244))
	_draw_button(Rect2(left + 253.0, top, 117.0, 44.0), "OPTIONEN", "garage_settings_toggle", Color8(35, 34, 28, 244))
	_draw_workshop_plate(Rect2(safe_rect.get_center().x - 142.0, top, 284.0, 55.0))
	_draw_text("WERKSTATT", safe_rect.get_center().x - 91.0, top + 38.0, 29, cream)
	_draw_coin_badge(right - 176.0, top, "%d MÜNZEN" % int(game.money))
	var city: String = String(game.world_data().get("city", "")).to_upper()
	_draw_workshop_plate(Rect2(left, top + 58.0, 224.0, 35.0))
	_draw_text("%s  ·  %s" % [city, game.current_vehicle_name().to_upper()], left + 11.0, top + 81.0, 14, cream)
	var shortcut_y: float = top + 104.0
	if game.unlocked_vehicles.size() > 1:
		_draw_button(Rect2(left, shortcut_y, 224.0, 42.0), "FAHRZEUG WECHSELN", "vehicle_next", Color8(35, 34, 28, 244))
		shortcut_y += 48.0
	if game.can_test_stock_vehicle():
		var stock_label: String = "KAMPAGNEN-KOMBI LADEN" if game.stock_test_mode else "SERIENFAHRZEUG TESTEN"
		_draw_button(Rect2(left, shortcut_y, 224.0, 42.0), stock_label, "stock_test_toggle", Color8(53, 43, 32, 240))
	if game.stock_test_mode:
		_draw_button(Rect2(left, shortcut_y + 48.0, 224.0, 42.0), "TEST-KOMBI AUF SERIE", "stock_test_reset", Color8(53, 43, 32, 240))
	var detail_rect := Rect2(panel_x, top + 72.0, detail_width, minf(465.0, footer_y - top - 85.0))
	if _garage_settings_open:
		_draw_garage_settings(detail_rect)
	else:
		_draw_garage_upgrade_panel(detail_rect)
	var visible_parts: Array[String] = ["engine", "tires", "tank", "armor", "nitro"]
	if game.can_show_weapon_upgrade():
		visible_parts.append("weapon")
	if not visible_parts.has(_garage_selected_part):
		_garage_selected_part = "engine"
	var gap: float = 8.0
	var card_width: float = (panel_x - left) / float(visible_parts.size()) - gap
	draw_rect(Rect2(safe_rect.position.x, footer_y - 10.0, safe_rect.size.x, 108.0), Color8(11, 15, 16, 237))
	for index in range(visible_parts.size()):
		_draw_garage_category_card(Rect2(left + float(index) * (card_width + gap), footer_y, card_width, 80.0), visible_parts[index])
	var start_label: String = "WELT WIEDERHOLEN" if game.is_world_completed(game.selected_world_index) else "LOSFAHREN  »"
	if game.stock_test_mode:
		start_label = "TESTFAHRT STARTEN  »"
	_draw_button(Rect2(panel_x, footer_y, detail_width, 80.0), start_label, "start", Color8(149, 84, 24))
	_draw_fitted_levels(Vector2(size.x * 0.355 - 107.0, footer_y - 55.0))
	if game.backdrop.has_method("workshop_poster_rect"):
		var poster:Rect2=game.backdrop.workshop_poster_rect(size)
		buttons.append({"rect":poster.grow(5),"id":"journey_open"})
	if game.is_first_drive_tutorial_active():
		_draw_first_drive_tutorial(size)

func _draw_garage_upgrade_panel(rect: Rect2) -> void:
	var part:String=_garage_selected_part
	var level:int=game.upgrade_level(part)
	var price:int=game.upgrade_price(part)
	var preview:Dictionary=game.upgrade_preview(part)
	var locked:bool=part=="weapon" and level==0 and not game.can_buy_weapon_upgrade()
	var cream:=Color("f6dfab")
	var left:float=rect.position.x+20
	var top:float=rect.position.y
	_draw_workshop_plate(rect)
	_draw_text(String(GARAGE_LABELS.get(part,part.to_upper())),left,top+38,25,cream)
	_draw_garage_level_pips(Vector2(rect.end.x-84,top+27),level,game.upgrade_limit(part),14,5)
	draw_line(Vector2(left,top+57),Vector2(rect.end.x-20,top+57),Color("706248"),1,true)
	var center:=Vector2(rect.get_center().x,top+139)
	var pulse:float=sin(_part_transition*PI)*5.0
	draw_circle(center+Vector2(0,10),69,Color(.025,.045,.05,.55))
	draw_arc(center,72,deg_to_rad(205),deg_to_rad(335),40,Color("8d7952"),1,true)
	var illustration:=Rect2(center-Vector2.ONE*(65+pulse),Vector2.ONE*(130+pulse*2))
	var kombi_tire_preview:bool=part=="tires" and game.wagon.vehicle_id=="kombi"
	if kombi_tire_preview:
		_draw_tire_preview(illustration,mini(level+1 if price>=0 else level,3),130)
	else:
		preload("res://scripts/workshop_icons.gd").draw_preview(self,illustration,part)
	_draw_text("NÄCHSTER REIFEN" if kombi_tire_preview and price>=0 else "TEILEKATEGORIE",left,top+226,11,Color("b9b49a"))
	if _upgrade_flash>0:
		var text:String="EINGEBAUT"
		draw_string(font,Vector2(rect.end.x-117,top+226),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(.65,.83,.53,clampf(_upgrade_flash*3,0,1)))
	var cell_width:float=(rect.size.x-48)*.5
	for next in [false,true]:
		var x:float=left+(cell_width+8 if next else 0)
		var box:=Rect2(x,top+241,cell_width,65)
		draw_rect(box,Color("253235") if next else Color("192326"))
		draw_line(box.position,box.position+Vector2(box.size.x,0),Color("c3924f") if next else Color("68736a"),2,true)
		_draw_text("NÄCHSTER AUSBAU" if next else "MONTIERT",x+9,top+258,10,Color("d4bd91") if next else Color("aeb8ac"))
		var shown_level:int=mini(level+1,game.upgrade_limit(part)) if next else level
		var state:String="MAXIMUM" if next and price<0 else "GESPERRT" if next and locked else "STUFE %d" % shown_level
		_draw_text(state,x+9,top+280,16,cream)
		var value:String=_garage_compare_value(part,preview,next)
		_draw_text(value,x+9,top+298,11,Color("aebfaf"))
	var benefit:String="Nach vollständigem Ausbau freischaltbar." if locked else String(preview.get("text",""))
	var text_box:=Rect2(left,top+320,rect.size.x-40,52)
	_draw_wrapped_garage_text(benefit,text_box,15,cream)
	var package_available:bool=game.is_starting_hill_package_available()
	var action_y:float=rect.end.y-(105 if package_available else 69)
	if price>=0:
		var price_label := "IM TEST KOSTENLOS" if game.stock_test_mode else "%d MÜNZEN" % price
		_draw_text(price_label,left,action_y-15,20,cream)
	var action:String="MAXIMAL AUSGEBAUT" if price<0 else "GESPERRT" if locked else "TESTSTUFE MONTIEREN" if game.stock_test_mode else "ZU WENIG MÜNZEN" if game.money<price else "KAUFEN"
	var available:bool=price>=0 and not locked and (game.stock_test_mode or game.money>=price)
	_draw_button(Rect2(left,action_y,rect.size.x-40,48),action,"upgrade",Color8(149,84,24) if available else Color8(56,52,43))
	if package_available:
		_draw_button(Rect2(left,rect.end.y-48,rect.size.x-40,36),"STARTPAKET  ·  %d" % game.starting_hill_package_price(),"starter_package",Color8(72,66,48))

func _garage_compare_value(part:String,preview:Dictionary,next:bool) -> String:
	var prefix:String="next_" if next else "current_"
	if not preview.has(prefix+"value"):
		return _garage_current_stage_name(part,game.upgrade_level(part))
	match part:
		"engine":return "%.0f KM/H" % float(preview.get(prefix+"speed_kmh",0))
		"tank","nitro":return "%d VORRAT" % roundi(float(preview[prefix+"value"]))
		"armor":return "%d TREFFERSCHADEN" % roundi(float(preview[prefix+"value"]))
		"tires":return _garage_current_stage_name(part,mini(game.upgrade_level(part)+(1 if next else 0),game.upgrade_limit(part)))
		"weapon":return "AUTOFEUER" if float(preview[prefix+"value"])>0 else "OHNE WAFFE"
	return ""

func _draw_wrapped_garage_text(text:String,rect:Rect2,font_size:int,color:Color) -> void:
	var line:String=""
	var y:float=rect.position.y+font_size
	for word in text.split(" "):
		var candidate:String=(line+" "+word).strip_edges()
		if font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>rect.size.x and not line.is_empty():
			_draw_text(line,rect.position.x,y,font_size,color)
			y+=font_size+5
			line=word
		else:line=candidate
	if not line.is_empty():_draw_text(line,rect.position.x,y,font_size,color)

func _draw_garage_category_card(rect: Rect2, part: String) -> void:
	var selected: bool = part == _garage_selected_part
	var locked: bool = part == "weapon" and game.upgrade_level(part) == 0 and not game.can_buy_weapon_upgrade()
	draw_rect(rect, Color8(65, 45, 23) if selected else Color8(25, 29, 28))
	draw_rect(rect.grow(-1.0), Color8(241, 175, 67) if selected else Color8(150, 121, 75), false, 2.0 if selected else 1.0)
	var icon_center := Vector2(rect.get_center().x, rect.position.y + 27.0)
	_draw_garage_part_icon(icon_center, part, Color8(115, 121, 108) if locked else Color8(236, 206, 151))
	if locked:
		_draw_lock_badge(Vector2(rect.end.x - 14.0, rect.position.y + 13.0))
	var label: String = String(GARAGE_LABELS.get(part, part.to_upper()))
	draw_string(font, rect.position + Vector2(0.0, 64.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13, Color8(242, 225, 192))
	buttons.append({"rect": rect, "id": "garage_part:" + part})

func _draw_journey_overlay(view_size:Vector2) -> void:
	buttons.clear()
	draw_rect(Rect2(Vector2.ZERO,view_size),Color(.015,.025,.03,.86))
	var safe:Rect2=_safe_bounds(view_size)
	var box:=Rect2(safe.get_center()-Vector2(470,287),Vector2(940,574))
	_draw_workshop_plate(box)
	_draw_text("DEIN WEG DURCH EUROPA",box.position.x+26,box.position.y+39,25,Color("eddbb5"))
	_draw_text("Amsterdam → Algeciras · 20 geplante Etappen",box.position.x+26,box.position.y+65,15,Color("b5b8a3"))
	var completed:Array[String]=[]
	for i in range(CAMPAIGN_DATA.CAMPAIGN_WORLDS.size()):
		if game.is_world_completed(i):completed.append(String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[i].id))
	var current:String=String(game.world_data().get("id","amsterdam"))
	var poster=preload("res://scripts/journey_poster.gd")
	poster.draw(self,Rect2(box.position+Vector2(28,85),Vector2(300,402)),current,completed,true)
	for i in range(poster.STOPS.size()):
		var stop:Dictionary=poster.STOPS[i]
		var col:int=i/10
		var x:float=box.position.x+355+col*273
		var y:float=box.position.y+112+(i%10)*36
		var done:bool=completed.has(String(stop.id))
		var here:bool=String(stop.id)==current
		var color:=Color("e2a050") if here else Color("9fb688") if done else Color("abae9f")
		draw_circle(Vector2(x+5,y-5),4,color)
		_draw_text(("✓ " if done else "")+str(i+1)+"  "+String(stop.city),x+18,y,15,color)
	_draw_text("Aktuell spielbar: Amsterdam. Weitere Städte folgen.",box.position.x+355,box.position.y+486,14,Color("b5b8a3"))
	_draw_button(Rect2(box.position+Vector2(355,515),Vector2(260,43)),"STRECKENKARTE","map_open",Color("7f562d"))
	_draw_button(Rect2(box.position+Vector2(630,515),Vector2(280,43)),"ZURÜCK ZUR WERKSTATT","journey_close",Color("253436"))

func _draw_garage_settings(rect: Rect2) -> void:
	_draw_panel(rect, Color8(13, 23, 25, 248))
	_draw_text("EINSTELLUNGEN", rect.position.x + 20.0, rect.position.y + 39.0, 22, Color8(241, 225, 189))
	_draw_button(Rect2(rect.position.x + 16.0, rect.position.y + 68.0, rect.size.x - 32.0, 42.0), "TON  %d%%" % int(round(float(game.master_volume) * 100.0)), "volume_mute", Color8(51, 64, 56))
	_draw_button(Rect2(rect.position.x + 16.0, rect.position.y + 119.0, rect.size.x - 32.0, 42.0), "MUSIK  %d%%" % int(round(float(game.music_volume) * 100.0)), "music_volume_mute", Color8(51, 64, 56))
	var haptic_label: String = "HAPTIK AUS" if float(game.haptic_strength) <= 0.01 else "HAPTIK %d%%" % int(round(float(game.haptic_strength) * 100.0))
	_draw_button(Rect2(rect.position.x + 16.0, rect.position.y + 170.0, rect.size.x - 32.0, 42.0), haptic_label, "haptics_toggle", Color8(51, 64, 56))
	_draw_button(Rect2(rect.position.x + 16.0, rect.position.y + 221.0, rect.size.x - 32.0, 42.0), "DATENSCHUTZ", "privacy_open", Color8(51, 64, 56))
	_draw_button(Rect2(rect.position.x + 16.0, rect.end.y - 68.0, rect.size.x - 32.0, 48.0), "ZURÜCK", "garage_settings_toggle", Color8(111, 78, 48))

func _garage_current_stage_name(part: String, level: int) -> String:
	if part == "tires":
		return TIRE_STAGE_NAMES[clampi(level, 0, TIRE_STAGE_NAMES.size() - 1)]
	if part == "weapon":
		return "GESPERRT" if level == 0 and not game.can_buy_weapon_upgrade() else "NICHT MONTIERT" if level == 0 else "HAUBENPISTOLE"
	return "SERIE" if level == 0 else "AUSBAUSTUFE %d" % level

func _draw_tire_preview(rect:Rect2,level:int,diameter:float) -> void:
	var texture:Texture2D=preload("res://assets/kombi_wheel_stock_0.7.2.png") if level<=0 else TIRE_STAGE1_TEXTURE if level==1 else TIRE_STAGE2_TEXTURE if level==2 else TIRE_STAGE3_TEXTURE
	var region:Rect2=Rect2(texture.get_image().get_used_rect())
	var width:float=minf(diameter,minf(rect.size.x,rect.size.y))
	var size:Vector2=region.size*width/maxf(region.size.x,region.size.y)
	draw_texture_rect_region(texture,Rect2(rect.get_center()-size*.5,size),region)

func _draw_garage_level_pips(origin: Vector2, level: int, limit: int, pip_width: float, gap: float) -> void:
	for index in range(limit):
		var pip := Rect2(origin.x + float(index) * (pip_width + gap), origin.y, pip_width, 9.0)
		draw_rect(pip, Color8(240, 179, 60) if index < level else Color8(76, 82, 69))

func _draw_garage_part_icon(center: Vector2, part: String, color: Color) -> void:
	preload("res://scripts/workshop_icons.gd").draw(self,center,part,color)

func _draw_lock_badge(center: Vector2) -> void:
	# A small drawn padlock keeps the locked weapon readable on mouse and touch.
	draw_rect(Rect2(center + Vector2(-6.0, -1.0), Vector2(12.0, 10.0)), Color8(24, 34, 34))
	draw_rect(Rect2(center + Vector2(-4.0, 1.0), Vector2(8.0, 6.0)), Color8(193, 154, 86))
	draw_arc(center + Vector2(0.0, -1.0), 4.0, PI, TAU, 12, Color8(193, 154, 86), 1.7, true)

func _draw_gear_icon(center: Vector2, color: Color) -> void:
	draw_circle(center, 13.0, color)
	draw_circle(center, 7.0, Color8(40, 48, 43))
	for index in range(8):
		var angle: float = float(index) * TAU / 8.0
		draw_line(center + Vector2(cos(angle), sin(angle)) * 12.0, center + Vector2(cos(angle), sin(angle)) * 17.0, color, 3.0, true)

func advance_first_drive_tutorial() -> void:
	if not game.is_first_drive_tutorial_active():
		return
	if _first_drive_tutorial_page < FIRST_DRIVE_TUTORIAL_PAGES.size() - 1:
		_first_drive_tutorial_page += 1
		queue_redraw()
		return
	_handle_button("tutorial:start")
	queue_redraw()

func _draw_first_drive_tutorial(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.035, 0.03, 0.82))
	var safe_rect: Rect2 = _safe_bounds(size)
	var panel_size := Vector2(minf(920.0, safe_rect.size.x - 40.0), minf(500.0, safe_rect.size.y - 32.0))
	var panel := Rect2(safe_rect.get_center() - panel_size * 0.5, panel_size)
	draw_rect(panel, Color8(23, 34, 31, 250))
	draw_rect(panel, Color8(213, 174, 109, 235), false, 2.0)
	var page: Dictionary = FIRST_DRIVE_TUTORIAL_PAGES[_first_drive_tutorial_page]
	_draw_text("ERSTE FAHRT  ·  %d / %d" % [_first_drive_tutorial_page + 1, FIRST_DRIVE_TUTORIAL_PAGES.size()], panel.position.x + 34.0, panel.position.y + 43.0, 14, Color8(210, 174, 114))
	_draw_text(String(page["title"]), panel.position.x + 34.0, panel.position.y + 91.0, 28, Color8(245, 228, 190))
	var content_width: float = panel.size.x - 68.0
	var body_bottom: float = _draw_wrapped_text(String(page["body"]), panel.position.x + 34.0, panel.position.y + 140.0, content_width, 19, Color8(220, 224, 206))
	_draw_text("SO STEUERST DU", panel.position.x + 34.0, maxf(panel.position.y + 242.0, body_bottom + 25.0), 13, Color8(210, 174, 114))
	var controls: String = String(page["mobile"] if game.mobile_target else page["desktop"])
	_draw_wrapped_text(controls, panel.position.x + 34.0, maxf(panel.position.y + 276.0, body_bottom + 54.0), content_width, 16, Color8(189, 207, 182))
	var dots_y: float = panel.position.y + panel.size.y - 108.0
	var dots_start: float = panel.position.x + panel.size.x * 0.5 - float(FIRST_DRIVE_TUTORIAL_PAGES.size() - 1) * 13.0
	for index in range(FIRST_DRIVE_TUTORIAL_PAGES.size()):
		draw_circle(Vector2(dots_start + float(index) * 26.0, dots_y), 4.5, Color8(230, 192, 126) if index == _first_drive_tutorial_page else Color8(84, 100, 84))
	var button_y: float = panel.position.y + panel.size.y - 78.0
	_draw_button(Rect2(panel.position.x + 22.0, button_y, 174.0, 54.0), "ÜBERSPRINGEN", "tutorial:skip", Color8(62, 77, 67))
	if _first_drive_tutorial_page > 0:
		_draw_button(Rect2(panel.position.x + panel.size.x - 322.0, button_y, 126.0, 54.0), "ZURÜCK", "tutorial:previous", Color8(62, 77, 67))
	var next_label: String = "LOSFAHREN" if _first_drive_tutorial_page == FIRST_DRIVE_TUTORIAL_PAGES.size() - 1 else "WEITER"
	var next_id: String = "tutorial:start" if _first_drive_tutorial_page == FIRST_DRIVE_TUTORIAL_PAGES.size() - 1 else "tutorial:next"
	_draw_button(Rect2(panel.position.x + panel.size.x - 184.0, button_y, 162.0, 54.0), next_label, next_id, Color8(176, 102, 58))

func _draw_wrapped_text(text: String, x: float, y: float, max_width: float, font_size: int, color: Color) -> float:
	var line_text: String = ""
	var line_index: int = 0
	var line_height: float = float(font_size + 8)
	for word in text.split(" "):
		var candidate: String = word if line_text.is_empty() else line_text + " " + word
		var candidate_width: float = font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if not line_text.is_empty() and candidate_width > max_width:
			_draw_text(line_text, x, y + float(line_index) * line_height, font_size, color)
			line_text = word
			line_index += 1
		else:
			line_text = candidate
	if not line_text.is_empty():
		_draw_text(line_text, x, y + float(line_index) * line_height, font_size, color)
		line_index += 1
	return y + float(line_index) * line_height

func _garage_control_hint() -> String:
	if game.tuning_trial_mode:
		return "KOMBI IN SERIE · TEILE EINZELN KAUFEN · NITRO ZUERST FREISCHALTEN"
	if game.upgrade_level("nitro") <= 0:
		return "NITRO-BOOST IST GESPERRT · NITRO BEI FAHRZEUGTUNING KAUFEN"
	if _first_hill_package_recommended():
		var package_price: int = game.upgrade_price("engine") + game.upgrade_price("tank")
		return "TIPP FÜR WELT %d: MOTOR + TANK FÜR %d MÜNZEN GEBEN MEHR ZUG UND REICHWEITE" % [game.selected_world_index + 1, package_price]
	if float(game.campaign_meter) < game.route_length_m * 0.5 and game.upgrade_level("engine") == 0:
		var engine_price: int = game.upgrade_price("engine")
		var coins_missing: int = maxi(0, engine_price - int(game.money))
		if coins_missing == 0:
			return "MOTOR FÜR %d MÜNZEN GIBT MEHR ZUG • TANK VERLÄNGERT DIE FAHRT • BOOST AM BERG" % engine_price
		return "ERSTER HÜGEL: MOTOR GIBT MEHR ZUG • NOCH %d MÜNZEN SAMMELN" % coins_missing
	if float(game.campaign_meter) < game.route_length_m * 0.5 and game.upgrade_level("tank") == 0:
		var tank_price: int = game.upgrade_price("tank")
		var tank_coins_missing: int = maxi(0, tank_price - int(game.money))
		if tank_coins_missing == 0:
			return "TANK-UPGRADE FÜR %d MÜNZEN VERLÄNGERT DIE FAHRT" % tank_price
		return "TANK VERLÄNGERT DIE FAHRT • NOCH %d MÜNZEN" % tank_coins_missing
	if game.mobile_target:
		return "STARTEN: GAS HALTEN  •  BOOST AM BERG  •  IN DER LUFT NEIGEN"
	return "W / ↑ GAS HALTEN     S / ↓ BREMSEN     A,D / ←,→ NEIGEN     LEERTASTE: BOOST AM BERG"

func _first_hill_package_recommended() -> bool:
	if float(game.campaign_meter) >= game.route_length_m * 0.5:
		return false
	if game.upgrade_level("engine") > 0 or game.upgrade_level("tank") > 0:
		return false
	var package_price: int = game.upgrade_price("engine") + game.upgrade_price("tank")
	return package_price > 0 and int(game.money) >= package_price

func _draw_upgrade_card(rect: Rect2, part: String, label: String, note: String) -> void:
	var level: int = game.upgrade_level(part)
	var limit: int = game.upgrade_limit(part)
	var price: int = game.upgrade_price(part)
	var maxed: bool = price < 0
	var first_hill_package: bool = _first_hill_package_recommended() and (part == "engine" or part == "tank")
	var first_hill_tip: bool = first_hill_package or (part == "engine" and float(game.campaign_meter) < game.route_length_m * 0.5 and level == 0)
	var upgrade_info: Dictionary = game.upgrade_preview(part)
	var card_color: Color = Color8(43, 54, 49) if not maxed else Color8(38, 47, 43)
	draw_rect(rect, card_color)
	draw_rect(rect, Color8(224, 181, 105) if first_hill_tip else Color8(102, 111, 86), false, 3.0 if first_hill_tip else 1.0)
	_draw_text(label, rect.position.x + 12.0, rect.position.y + 24.0, 15, Color8(237, 220, 180))
	_draw_text(note, rect.position.x + 12.0, rect.position.y + 48.0, 10 if rect.size.x < 170.0 else 12, Color8(177, 188, 164))
	_draw_text(String(upgrade_info.get("text", "")), rect.position.x + 12.0, rect.position.y + 65.0, 10, Color8(179, 203, 169) if not maxed else Color8(144, 163, 143))
	for step in range(limit):
		var pip_rect := Rect2(rect.position.x + 12.0 + float(step) * 21.0, rect.position.y + 77.0, 15.0, 7.0)
		draw_rect(pip_rect, Color8(190, 146, 81) if step < level else Color8(71, 79, 66))
	if first_hill_tip:
		var tip: String = "STARTPAKET" if first_hill_package else "TIPP FÜR DEN ERSTEN HÜGEL"
		_draw_text(tip, rect.position.x + 12.0, rect.position.y + 99.0, 10, Color8(232, 194, 121))
	var price_text: String = "MAX" if maxed else "%d  •  VERBESSERN" % price
	_draw_text(price_text, rect.position.x + 12.0, rect.position.y + 120.0, 12, Color8(235, 196, 123) if (maxed or game.money >= price) else Color8(191, 135, 107))
	buttons.append({"rect": rect, "id": "upgrade:" + part})

func _draw_world_map(size: Vector2) -> void:
	var safe_rect: Rect2 = _safe_bounds(size)
	var top_y: float = safe_rect.position.y
	var bottom_y: float = safe_rect.end.y
	draw_rect(Rect2(Vector2.ZERO, size), Color8(15, 24, 23, 242))
	_draw_text("STRECKENKARTE · NIEDERLANDE", safe_rect.position.x + 28.0, top_y + 43.0, 20, Color8(239, 219, 174))
	_draw_text("STRECKEN %d · FREI %d" % [CAMPAIGN_DATA.PLAYABLE_WORLD_COUNT, mini(game.unlocked_world_index + 1, CAMPAIGN_DATA.PLAYABLE_WORLD_COUNT)], safe_rect.end.x - 395.0, top_y + 42.0, 13, Color8(188, 195, 170))
	var map_rect := Rect2(safe_rect.position.x + 18.0, top_y + 60.0, safe_rect.size.x * 0.42, safe_rect.size.y - 78.0)
	_draw_panel(map_rect, Color8(28, 42, 40, 248))
	var map_area := Rect2(map_rect.position.x + 20.0, map_rect.position.y + 40.0, map_rect.size.x - 40.0, map_rect.size.y - 72.0)
	_draw_amsterdam_route_overview(map_area)
	var world_points: Array[Vector2] = []
	for world_index in range(CAMPAIGN_DATA.PLAYABLE_WORLD_COUNT):
		var point: Vector2 = map_area.position + Vector2(map_area.size.x * (0.78 - world_index * 0.24), map_area.size.x * (0.22 + world_index * 0.28))
		world_points.append(point)
	for index in range(world_points.size() - 1):
		var route_color: Color = Color8(212, 164, 87, 215) if index < game.unlocked_world_index else Color8(123, 139, 124, 145)
		draw_line(world_points[index], world_points[index + 1], route_color, 3.0, true)
	for world_index in range(world_points.size()):
		var point: Vector2 = world_points[world_index]
		var unlocked: bool = game.is_world_unlocked(world_index)
		var completed: bool = game.is_world_completed(world_index)
		var marker_color: Color = Color8(223, 176, 91) if completed else Color8(184, 102, 62) if unlocked else Color8(60, 72, 67)
		draw_circle(point, 11.0 if world_index == game.selected_world_index else 8.0, Color8(238, 219, 174) if world_index == game.selected_world_index else Color8(25, 35, 32))
		draw_circle(point, 7.0 if world_index == game.selected_world_index else 5.0, marker_color)
		var marker_label: String = "%d" % (world_index + 1)
		draw_string(font, point + Vector2(9.0, -6.0), marker_label, HORIZONTAL_ALIGNMENT_LEFT, 24.0, 10, Color8(238, 227, 197) if unlocked else Color8(125, 138, 127))
	var selected_world: Dictionary = game.world_data()
	var selected_city: String = String(selected_world.get("city", "Amsterdam"))
	draw_string(font, Vector2(map_rect.position.x + 16.0, map_rect.end.y - 17.0), "NIEDERLANDE · AMSTERDAM UND UTRECHT", HORIZONTAL_ALIGNMENT_LEFT, map_rect.size.x - 32.0, 12, Color8(215, 196, 153))
	var list_x: float = map_rect.end.x + 15.0
	var list_width: float = safe_rect.end.x - list_x - 18.0
	_draw_panel(Rect2(list_x, top_y + 60.0, list_width, safe_rect.size.y - 78.0), Color8(24, 35, 33, 245))
	_draw_text("WELT %02d · %s" % [game.selected_world_index + 1, selected_city.to_upper()], list_x + 16.0, top_y + 91.0, 18, Color8(239, 219, 174))
	_draw_text(String(selected_world.get("setpiece", "")), list_x + 16.0, top_y + 114.0, 12, Color8(188, 195, 170))
	_draw_text("HERAUSFORDERUNG: %s" % String(selected_world.get("challenge", "")), list_x + 16.0, top_y + 137.0, 12, Color8(215, 181, 119))
	var world_challenge: Dictionary = game.challenge_data(game.selected_world_index)
	var medal_state: String = "MEDAILLE GESICHERT" if game.is_world_challenge_completed(game.selected_world_index) else "NOCH OFFEN · +%d MÜNZEN" % int(world_challenge.get("reward", 0))
	_draw_text("BONUSZIEL: %s · %s" % [String(world_challenge.get("title", "")), medal_state], list_x + 16.0, top_y + 159.0, 11, Color8(232, 194, 121))
	_draw_text("FAHRZEUG-EMPFEHLUNG: %s" % String(selected_world.get("vehicle", "Kombi")), list_x + 16.0, top_y + 179.0, 12, Color8(188, 195, 170))
	var column_gap: float = 10.0
	var column_width: float = (list_width - 36.0 - column_gap) * 0.5
	var list_top: float = top_y + 200.0
	for world_index in range(CAMPAIGN_DATA.PLAYABLE_WORLD_COUNT):
		var world: Dictionary = CAMPAIGN_DATA.CAMPAIGN_WORLDS[world_index]
		var rect := Rect2(list_x + 12.0 + float(world_index) * (column_width + column_gap), list_top, column_width, 78.0)
		var unlocked: bool = game.is_world_unlocked(world_index)
		var completed: bool = game.is_world_completed(world_index)
		var fill: Color = Color8(122, 78, 49) if world_index == game.selected_world_index else Color8(46, 60, 54) if unlocked else Color8(34, 43, 40)
		draw_rect(rect, fill)
		draw_rect(rect, Color8(224, 181, 105) if world_index == game.selected_world_index else Color8(98, 116, 93), false, 1.0)
		var city_color: Color = Color8(245, 232, 200) if unlocked else Color8(128, 140, 130)
		_draw_text("ETAPPE %02d" % (world_index + 1), rect.position.x + 12.0, rect.position.y + 25.0, 10, Color8(218, 177, 101))
		_draw_text(String(world.get("city", "")), rect.position.x + 12.0, rect.position.y + 48.0, 16, city_color)
		_draw_text("ABGESCHLOSSEN" if completed else "BEREIT" if unlocked else "GESPERRT", rect.position.x + 12.0, rect.position.y + 67.0, 9, Color8(220, 196, 147) if completed or unlocked else Color8(132, 143, 132))
		if unlocked:
			buttons.append({"rect": rect, "id": "world_select:%d" % world_index})
	var footer_y: float = bottom_y - 58.0
	_draw_button(Rect2(list_x + 12.0, top_y + 298.0, minf(182.0, list_width - 24.0), 42.0), "FUNKARCHIV", "archive_open", Color8(48, 60, 54, 235))
	_draw_text("WEITERE STRECKEN FOLGEN SPÄTER", list_x + 16.0, footer_y + 23.0, 12, Color8(215, 181, 119))
	_draw_button(Rect2(safe_rect.end.x - 234.0, footer_y, 208.0, 42.0), "ZUM HAUPTMENÜ" if game.map_return_to_menu else "ZUR WERKSTATT", "map_back", Color8(176, 102, 58))
	_draw_text("Wähle eine Strecke und starte sie in der Werkstatt.", list_x + 16.0, footer_y - 5.0, 11, Color8(172, 185, 165))

func _draw_radio_archive(size: Vector2) -> void:
	var safe_rect: Rect2 = _safe_bounds(size)
	draw_rect(Rect2(Vector2.ZERO, size), Color8(15, 24, 23, 248))
	_draw_text("FUNKARCHIV · AMSTERDAM", safe_rect.position.x + 26.0, safe_rect.position.y + 40.0, 23, Color8(239, 219, 174))
	_draw_text("GEBORGEN %d / %d" % [game.collected_story_log_count(), game.story_log_count()], safe_rect.position.x + 28.0, safe_rect.position.y + 65.0, 13, Color8(188, 195, 170))
	_draw_button(Rect2(safe_rect.end.x - 206.0, safe_rect.position.y + 13.0, 180.0, 42.0), "ZURÜCK", "archive_back", Color8(106, 81, 55))
	var content_top: float = safe_rect.position.y + 82.0
	var content_height: float = safe_rect.size.y - 101.0
	var detail_width: float = minf(395.0, safe_rect.size.x * 0.34)
	var detail_rect := Rect2(safe_rect.position.x + 18.0, content_top, detail_width, content_height)
	_draw_panel(detail_rect, Color8(27, 39, 36, 250))
	var selected_index: int = clampi(int(game.archive_selected_log_index), 0, game.story_log_count() - 1)
	var selected_log: Dictionary = game.story_log_data(selected_index)
	var collected: bool = game.is_story_log_collected(selected_index)
	var detail_x: float = detail_rect.position.x + 22.0
	_draw_text("ETAPPE %02d · %s" % [int(selected_log.get("world", selected_index + 1)), String(selected_log.get("city", "EUROPA")).to_upper()], detail_x, detail_rect.position.y + 34.0, 13, Color8(210, 174, 114))
	draw_rect(Rect2(detail_x, detail_rect.position.y + 52.0, 42.0, 34.0), Color8(188, 148, 77))
	draw_rect(Rect2(detail_x + 5.0, detail_rect.position.y + 57.0, 32.0, 24.0), Color8(49, 65, 58))
	draw_circle(Vector2(detail_x + 21.0, detail_rect.position.y + 69.0), 7.0, Color8(217, 184, 111))
	draw_circle(Vector2(detail_x + 21.0, detail_rect.position.y + 69.0), 3.5, Color8(55, 67, 60))
	draw_circle(Vector2(detail_x + 35.0, detail_rect.position.y + 60.0), 2.0, Color8(227, 98, 67))
	_draw_text(String(selected_log.get("title", "FUNKARCHIV")) if collected else "NOCH NICHT GEBORGEN", detail_x, detail_rect.position.y + 112.0, 20, Color8(239, 219, 174) if collected else Color8(157, 167, 151))
	if collected:
		_draw_wrapped_text(String(selected_log.get("text", "")), detail_x, detail_rect.position.y + 151.0, detail_rect.size.x - 44.0, 16, Color8(218, 222, 204))
		_draw_text("GEBORGEN · %d/%d" % [game.collected_story_log_count(), game.story_log_count()], detail_x, detail_rect.end.y - 30.0, 11, Color8(210, 174, 114))
	else:
		var city: String = String(selected_log.get("city", "dieser Etappe"))
		_draw_wrapped_text("Ein alter Fluchtplan liegt noch auf der Strecke bei %s. Fahre dicht heran, um den Eintrag und 20 Münzen zu bergen." % city, detail_x, detail_rect.position.y + 151.0, detail_rect.size.x - 44.0, 16, Color8(187, 201, 179))
		_draw_text("EINTRAG NOCH NICHT GEBORGEN", detail_x, detail_rect.end.y - 30.0, 11, Color8(151, 163, 147))
	var list_x: float = detail_rect.end.x + 15.0
	var list_width: float = safe_rect.end.x - list_x - 18.0
	var list_rect := Rect2(list_x, content_top, list_width, content_height)
	_draw_panel(list_rect, Color8(24, 35, 33, 245))
	var list_origin := list_rect.position + Vector2(11.0, 11.0)
	var gap: float = 8.0
	var column_count: int = 1 if game.story_log_count() <= 16 else 2
	var rows_per_column: int = mini(16, maxi(1, game.story_log_count()))
	var column_width: float = (list_rect.size.x - 22.0 - gap * float(column_count - 1)) / float(column_count)
	var row_height: float = 62.0 if game.story_log_count() <= 8 else (list_rect.size.y - 22.0) / float(rows_per_column)
	for log_index in range(game.story_log_count()):
		var column: int = mini(column_count - 1, int(log_index / rows_per_column))
		var row: int = log_index % rows_per_column
		var row_rect := Rect2(list_origin.x + float(column) * (column_width + gap), list_origin.y + float(row) * row_height, column_width, row_height - 2.0)
		var log_data: Dictionary = game.story_log_data(log_index)
		var is_unlocked: bool = game.is_story_log_collected(log_index)
		var row_color: Color = Color8(124, 83, 48) if log_index == selected_index else Color8(44, 62, 54) if is_unlocked else Color8(34, 44, 40)
		draw_rect(row_rect, row_color)
		draw_rect(row_rect, Color8(219, 181, 107, 180) if log_index == selected_index else Color8(92, 110, 91, 150), false, 1.0)
		var log_label: String = "%02d · %s" % [int(log_data.get("world", log_index + 1)), String(log_data.get("city", "EUROPA")).to_upper()]
		_draw_text(log_label, row_rect.position.x + 7.0, row_rect.position.y + row_rect.size.y * 0.68, 11, Color8(235, 225, 190) if is_unlocked else Color8(137, 151, 137))
		if is_unlocked:
			draw_circle(Vector2(row_rect.end.x - 12.0, row_rect.position.y + row_rect.size.y * 0.5), 3.2, Color8(224, 180, 98))
		buttons.append({"rect": row_rect, "id": "story_select:%d" % log_index})

func _draw_run(size: Vector2) -> void:
	var safe_rect: Rect2 = _safe_bounds(size)
	var left_x: float = safe_rect.position.x
	var top_y: float = safe_rect.position.y
	var right_x: float = safe_rect.end.x
	var route_meter: float = float(game.campaign_meter)
	if String(game.screen_state) == "RUN":
		route_meter += float(game.run_distance)
	var world_index: int = game.run_world_index if String(game.screen_state) in ["RUN", "WIN", "RESULT", "LEVEL_COMPLETE"] else game.selected_world_index
	world_index = clampi(world_index, 0, CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() - 1)
	var city_name: String = String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[world_index].get("city", "EUROPA")).to_upper()
	# Keep the hand-built speed dial and real condition bars, but fit them into a
	# single compact left-corner module like the supplied mobile reference.
	_draw_manual_gauge_cluster(left_x + 16.0, top_y + 14.0, 0.78)
	var center_x: float = (left_x + right_x) * 0.5
	var title_width: float = font.get_string_size(city_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20).x
	_draw_panel(Rect2(center_x - 166.0, top_y + 14.0, 332.0, 73.0), Color8(24, 34, 33, 198))
	_draw_text(city_name, center_x - title_width * 0.5, top_y + 39.0, 20, Color8(245, 233, 204))
	var distance_text: String = "%d M" % int(route_meter)
	var distance_width: float = font.get_string_size(distance_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22).x
	_draw_text(distance_text, center_x - distance_width * 0.5, top_y + 64.0, 22, Color8(249, 244, 222))
	var route_rect := Rect2(center_x - 127.0, top_y + 72.0, 254.0, 5.0)
	draw_rect(route_rect, Color8(67, 73, 61))
	var route_fraction: float = clampf(route_meter / game.route_length_m, 0.0, 1.0)
	draw_rect(Rect2(route_rect.position, Vector2(route_rect.size.x * route_fraction, route_rect.size.y)), Color8(198, 155, 84))
	var fuel_fraction: float = clampf(float(game.wagon.fuel) / maxf(1.0, float(game.wagon.fuel_capacity)), 0.0, 1.0)
	var low_fuel: bool = fuel_fraction <= 0.25
	if String(game.screen_state) == "RUN" and not game.paused:
		_draw_road_hazard_warning(route_meter, center_x - 165.0, top_y + 132.0)
	var checkpoint_text: String = "ZIEL ERREICHT" if String(game.screen_state) == "WIN" else "ZIEL %s · %d M" % [game.next_checkpoint_name(route_meter), int(ceil(game.next_checkpoint_distance(route_meter)))]
	_draw_text(checkpoint_text, center_x - 160.0, top_y + 107.0, 9, Color8(233, 199, 137))
	# Coins and pause share one compact top-right row.
	_draw_coin_badge(right_x - 238.0, top_y + 18.0, "%d MÜNZEN" % int(game.money))
	var pause_y: float = top_y + (MOBILE_GESTURE_INSET if game.mobile_target else 17.0)
	var pause_visual := Rect2(right_x - 51.0, pause_y, 45.0, 42.0)
	_draw_button(pause_visual, "Ⅱ", "pause_open", Color8(74, 82, 68))
	if game.mobile_target:
		buttons.append({"rect": Rect2(right_x - 57.0, pause_y - 5.0, 57.0, 52.0), "id": "pause_open"})
	var recommend_boost: bool = _boost_is_recommended()
	if game.mobile_target:
		_draw_touch_controls(size, recommend_boost)
	else:
		var bottom: Rect2 = Rect2((safe_rect.position.x + safe_rect.end.x) * 0.5 - 305.0, safe_rect.end.y - 40.0, 610.0, 27.0)
		var drive_hint: String
		var hint_panel_color: Color = Color8(24, 34, 33, 205)
		var hint_text_color: Color = Color8(215, 211, 185)
		if low_fuel:
			drive_hint = _low_fuel_hint(route_meter, recommend_boost)
			hint_panel_color = Color8(62, 43, 32, 225)
			hint_text_color = Color8(245, 161, 126)
		elif recommend_boost:
			drive_hint = "HÜGEL ERKANNT — LEERTASTE HALTEN: BOOST"
			hint_text_color = Color8(240, 203, 137)
		else:
			drive_hint = "W / ↑ GAS HALTEN     S / ↓ BREMSE     A,D / ←,→ NEIGEN     LEERTASTE BOOST AM BERG"
		draw_rect(bottom, hint_panel_color)
		_draw_text(drive_hint, bottom.position.x + 16.0, bottom.position.y + 18.0, 12, hint_text_color)
	if game.mobile_target and QA_DIAGNOSTICS.enabled() and not _safe_controls_reported and String(game.screen_state) == "RUN":
		_safe_controls_reported = true
		_validate_mobile_hitboxes(safe_rect)

func _draw_manual_gauge_cluster(x: float, y: float, scale: float = 1.0) -> void:
	# Scale the whole analog cluster uniformly so its typography and dial marks
	# stay crisp while it occupies less of the action view.
	draw_set_transform(Vector2(x * (1.0 - scale), y * (1.0 - scale)), 0.0, Vector2.ONE * scale)
	_draw_panel(Rect2(x, y, 252.0, 122.0), Color8(22, 32, 31, 235))
	var center := Vector2(x + 60.0, y + 61.0)
	var gauge_start: float = deg_to_rad(135.0)
	var gauge_sweep: float = deg_to_rad(270.0)
	var speed_kmh: float = absf(float(game.wagon.speed_mps)) * 3.6
	draw_circle(center, 51.0, Color8(9, 16, 17, 245))
	draw_arc(center, 48.0, gauge_start, gauge_start + gauge_sweep, 64, Color8(177, 154, 111), 2.2, true)
	draw_arc(center, 43.0, gauge_start, gauge_start + gauge_sweep, 64, Color8(64, 76, 67), 1.0, true)
	draw_arc(center, 46.0, gauge_start + gauge_sweep * 0.875, gauge_start + gauge_sweep, 18, Color8(204, 82, 65), 3.0, true)
	for tick_index in range(21):
		var fraction: float = float(tick_index) / 20.0
		var angle: float = gauge_start + gauge_sweep * fraction
		var direction := Vector2(cos(angle), sin(angle))
		var major_tick: bool = tick_index % 5 == 0
		var inner_radius: float = 35.0 if major_tick else 39.0
		draw_line(center + direction * inner_radius, center + direction * 43.5, Color8(235, 218, 178) if major_tick else Color8(136, 151, 133), 1.7 if major_tick else 1.0, true)
		if major_tick:
			var major_value: int = int(round(SPEEDOMETER_MAX_KMH * float(tick_index) / 20.0))
			var label_position: Vector2 = center + direction * (30.0 if major_value == 160 else 28.0)
			var label: String = str(major_value)
			var label_font_size: int = 12 if major_value == 160 else 8
			var label_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_font_size)
			var label_color: Color = Color8(231, 112, 81) if major_value == 160 else Color8(211, 202, 173)
			draw_string(font, Vector2(label_position.x - label_size.x * 0.5, label_position.y + label_size.y * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_font_size, label_color)
	var speed_fraction: float = clampf(speed_kmh / SPEEDOMETER_MAX_KMH, 0.0, 1.0)
	var needle_angle: float = gauge_start + gauge_sweep * speed_fraction
	var needle_tip: Vector2 = center + Vector2(cos(needle_angle), sin(needle_angle)) * 32.0
	draw_line(center, needle_tip, Color8(226, 94, 66), 2.5, true)
	draw_circle(center, 4.0, Color8(220, 184, 120))
	draw_circle(center, 2.0, Color8(43, 50, 43))
	draw_rect(Rect2(center.x - 16.0, center.y + 12.0, 32.0, 16.0), Color8(9, 16, 17, 235))
	var speed_text: String = str(int(round(speed_kmh)))
	var speed_text_width: float = font.get_string_size(speed_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x
	_draw_text(speed_text, center.x - speed_text_width * 0.5, center.y + 24.0, 13, Color8(241, 228, 191))
	var unit_width: float = font.get_string_size("KM/H", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 7).x
	_draw_text("KM/H", center.x - unit_width * 0.5, center.y + 34.0, 7, Color8(161, 175, 151))

	var fuel_fraction: float = clampf(float(game.wagon.fuel) / maxf(1.0, float(game.wagon.fuel_capacity)), 0.0, 1.0)
	_draw_text("TANK", x + 124.0, y + 22.0, 10, Color8(216, 193, 144))
	var fuel_bar := Rect2(x + 124.0, y + 29.0, 96.0, 9.0)
	draw_rect(fuel_bar, Color8(57, 68, 58))
	var fuel_color: Color = Color8(186, 184, 103) if fuel_fraction > 0.25 else Color8(214, 104, 77)
	draw_rect(Rect2(fuel_bar.position, Vector2(fuel_bar.size.x * fuel_fraction, fuel_bar.size.y)), fuel_color)
	for segment_index in range(1, 8):
		var segment_x: float = fuel_bar.position.x + fuel_bar.size.x * float(segment_index) / 8.0
		draw_line(Vector2(segment_x, fuel_bar.position.y), Vector2(segment_x, fuel_bar.end.y), Color8(22, 31, 28, 190), 1.0)
	_draw_text("E", x + 124.0, y + 51.0, 8, Color8(173, 181, 158))
	_draw_text("F", x + 211.0, y + 51.0, 8, Color8(220, 207, 166))
	_draw_text("%d%%" % int(round(fuel_fraction * 100.0)), x + 177.0, y + 51.0, 9, Color8(224, 220, 193) if fuel_fraction > 0.12 else Color8(238, 126, 96))
	var fuel_warning: bool = fuel_fraction <= 0.12
	var blink_on: bool = posmod(int(Time.get_ticks_msec() / 260), 2) == 0
	var fuel_lamp: Color = Color8(227, 73, 57) if fuel_warning and blink_on else Color8(79, 49, 43)
	draw_circle(Vector2(x + 234.0, y + 17.0), 5.5, Color8(31, 25, 24))
	draw_circle(Vector2(x + 234.0, y + 17.0), 3.5, fuel_lamp)

	var health_fraction: float = clampf(float(game.wagon.durability) / 100.0, 0.0, 1.0)
	_draw_text("KAROSSERIE", x + 124.0, y + 76.0, 10, Color8(216, 193, 144))
	var health_percent: int = int(round(health_fraction * 100.0))
	_draw_text("%d%%" % health_percent, x + 204.0, y + 76.0, 9, Color8(238, 129, 98) if health_fraction <= 0.25 else Color8(208, 211, 181))
	var health_bar := Rect2(x + 124.0, y + 83.0, 104.0, 9.0)
	draw_rect(health_bar, Color8(57, 68, 58))
	var health_color: Color = Color8(163, 168, 103) if health_fraction > 0.55 else Color8(204, 147, 79) if health_fraction > 0.25 else Color8(209, 82, 65)
	draw_rect(Rect2(health_bar.position, Vector2(health_bar.size.x * health_fraction, health_bar.size.y)), health_color)
	for segment_index in range(1, 8):
		var segment_x: float = health_bar.position.x + health_bar.size.x * float(segment_index) / 8.0
		draw_line(Vector2(segment_x, health_bar.position.y), Vector2(segment_x, health_bar.end.y), Color8(22, 31, 28, 190), 1.0)
	# A small battered-car pictogram ties the condition meter to body damage.
	var icon_x: float = x + 126.0
	var icon_y: float = y + 103.0
	draw_line(Vector2(icon_x, icon_y + 5.0), Vector2(icon_x + 23.0, icon_y + 5.0), Color8(196, 190, 158), 1.8, true)
	draw_line(Vector2(icon_x + 4.0, icon_y + 5.0), Vector2(icon_x + 8.0, icon_y), Color8(196, 190, 158), 1.5, true)
	draw_line(Vector2(icon_x + 8.0, icon_y), Vector2(icon_x + 17.0, icon_y), Color8(196, 190, 158), 1.5, true)
	draw_line(Vector2(icon_x + 17.0, icon_y), Vector2(icon_x + 21.0, icon_y + 5.0), Color8(196, 190, 158), 1.5, true)
	draw_circle(Vector2(icon_x + 6.0, icon_y + 7.0), 2.4, Color8(31, 38, 34))
	draw_circle(Vector2(icon_x + 18.0, icon_y + 7.0), 2.4, Color8(31, 38, 34))
	draw_line(Vector2(icon_x + 13.0, icon_y - 1.0), Vector2(icon_x + 11.0, icon_y + 3.0), Color8(206, 115, 82), 1.2, true)
	_draw_text("ZUSTAND", x + 157.0, y + 111.0, 8, Color8(171, 184, 163))
	if game.stock_test_mode:
		_draw_text("SERIE", x + 208.0, y + 111.0, 8, Color8(234, 180, 113))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_road_hazard_warning(route_meter: float, text_x: float, top_y: float) -> void:
	var warning: Dictionary = game.next_road_hazard_warning(route_meter)
	if warning.is_empty():
		return
	var distance_m: int = int(ceil(float(warning.get("distance_m", 0.0))))
	var hazard_label: String = String(warning.get("hazard_label", "HINDERNIS")).to_upper()
	var warning_text: String
	var warning_size: int = 10
	if bool(warning.get("branch_choice", false)):
		var minimum_kmh: int = int(round(float(warning.get("min_launch_speed_mps", 18.0)) * 3.6))
		warning_text = "IN %d M: AB %d KM/H SPRUNG · LANGSAM DURCHBRUCH" % [distance_m, minimum_kmh]
		warning_size = 9
	else:
		warning_text = "IN %d M: %s · LUFTSPRUNG VERMEIDET TREFFER" % [distance_m, hazard_label]
	_draw_text(warning_text, text_x, top_y + 20.0, warning_size, Color8(235, 190, 111))

func _draw_run_notification(size: Vector2) -> void:
	if game.paused:
		return
	var safe_rect: Rect2 = _safe_bounds(size)
	var notification_rect: Rect2 = _run_notification_rect(size)
	if notification_rect.size.x <= 0.0:
		return
	var notification_text: String = _run_notification_content()
	if notification_text.is_empty():
		return
	var ticker := Rect2(notification_rect.position, notification_rect.size)
	draw_rect(ticker, Color8(21, 31, 30, 205))
	draw_rect(ticker, Color8(164, 142, 97, 145), false, 1.0)
	draw_rect(Rect2(ticker.position.x, ticker.position.y + 4.0, 3.0, ticker.size.y - 8.0), Color8(211, 171, 93))
	var fitted_text: String = notification_text
	while fitted_text.length() > 4 and font.get_string_size(fitted_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11).x > ticker.size.x - 24.0:
		fitted_text = fitted_text.left(fitted_text.length() - 4) + "..."
	_draw_text(fitted_text, ticker.position.x + 12.0, ticker.position.y + 18.0, 11, Color8(239, 228, 199))

func _run_notification_content() -> String:
	if float(game.toast_time) > 0.0 and not String(game.toast_text).is_empty():
		return String(game.toast_text).replace("\n", " ")
	return ""

func _run_notification_rect(size: Vector2) -> Rect2:
	var safe_rect: Rect2 = _safe_bounds(size)
	var ticker_width: float = minf(420.0, safe_rect.size.x * 0.48)
	if ticker_width < 260.0:
		return Rect2()
	var ticker_left: float = safe_rect.get_center().x - ticker_width * 0.5
	return Rect2(ticker_left, safe_rect.position.y + 118.0, ticker_width, 28.0)

func _boost_is_recommended() -> bool:
	if game == null or game.screen_state != "RUN" or game.paused:
		return false
	if game.wagon.nitro_level <= 0 or game.wagon.fuel <= 0.0 or game.wagon.nitro < 4.0 or bool(game.touch_actions["boost"]):
		return false
	var accelerating: bool = bool(game.touch_actions["accelerate"]) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)
	if not accelerating or absf(game.wagon.speed_mps) >= 14.0:
		return false
	return should_recommend_boost_for_slope(game.terrain.slope_at(game.wagon.global_position.x))

func should_recommend_boost_for_slope(slope_angle: float) -> bool:
	# terrain.slope_at() follows screen coordinates: y grows downward, so an
	# uphill road to the right has a negative angle.
	return slope_angle <= -0.035

func _draw_mobile_drive_hint(size: Vector2, recommend_boost: bool = false, route_meter: float = 0.0, low_fuel: bool = false) -> void:
	var hint: String = _low_fuel_hint(route_meter, recommend_boost) if low_fuel else "NITRO IN DER WERKSTATT FREISCHALTEN" if game.wagon.nitro_level <= 0 else "STEIGUNG ERKANNT  •  BOOST HALTEN" if recommend_boost else "GAS HALTEN  •  BOOST HILFT AM BERG  •  IN DER LUFT NEIGEN"
	var safe_rect: Rect2 = _safe_bounds(size)
	var hint_width: float = minf(560.0, safe_rect.size.x * 0.46)
	var hint_rect := Rect2(safe_rect.position.x + (safe_rect.size.x - hint_width) * 0.5, safe_rect.end.y - 41.0, hint_width, 28.0)
	var hint_panel_color: Color = Color8(24, 34, 33, 205)
	var hint_text_color: Color = Color8(215, 211, 185)
	if low_fuel:
		hint_panel_color = Color8(62, 43, 32, 225)
		hint_text_color = Color8(245, 161, 126)
	elif recommend_boost:
		hint_panel_color = Color8(51, 43, 29, 225)
		hint_text_color = Color8(240, 203, 137)
	_draw_panel(hint_rect, hint_panel_color)
	var text_width: float = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12).x
	_draw_text(hint, maxf(hint_rect.position.x + 8.0, safe_rect.position.x + (safe_rect.size.x - text_width) * 0.5), hint_rect.position.y + 18.0, 12, hint_text_color)

func _low_fuel_hint(route_meter: float, recommend_boost: bool) -> String:
	var critical: bool = float(game.wagon.fuel) <= float(game.wagon.fuel_capacity) * 0.1
	var status: String = "TANK KRITISCH" if critical else "TANK NIEDRIG"
	var pickup_distance: float = _next_fuel_pickup_distance(route_meter)
	var pickup_hint: String = "KANISTER SUCHEN" if pickup_distance < 0.0 else "KANISTER IN %d M" % int(ceil(pickup_distance))
	var boost_hint: String = " • BOOST AM BERG" if recommend_boost else ""
	return "%s%s • %s" % [status, boost_hint, pickup_hint]

func _next_fuel_pickup_distance(route_meter: float) -> float:
	var nearest_distance: float = INF
	for entity in game.terrain.entities:
		if String(entity.get("kind", "")) != "fuel" or bool(entity.get("done", false)):
			continue
		var distance: float = float(entity.get("meter", route_meter)) - route_meter
		if distance >= -0.5:
			nearest_distance = minf(nearest_distance, maxf(0.0, distance))
	return -1.0 if is_inf(nearest_distance) else nearest_distance

func _draw_touch_controls(size: Vector2, recommend_boost: bool = false) -> void:
	var safe_rect: Rect2 = _safe_bounds(size)
	# Respect Android cutouts and leave an additional 48 logical pixels for edge gestures.
	var bottom_y: float = safe_rect.end.y - MOBILE_GESTURE_INSET
	# Match the reference: brake on the left, nitro just left of gas, with the
	# two air-trim controls compact beside the brake instead of crowding the top.
	_draw_touch_button(Rect2(safe_rect.position.x + 18.0, bottom_y - 96.0, 92.0, 92.0), "BREMS", "brake")
	_draw_touch_button(Rect2(safe_rect.position.x + 124.0, bottom_y - 65.0, 58.0, 58.0), "◀", "tilt_left")
	_draw_touch_button(Rect2(safe_rect.position.x + 190.0, bottom_y - 65.0, 58.0, 58.0), "▶", "tilt_right")
	_draw_touch_button(Rect2(safe_rect.end.x - 248.0, bottom_y - 92.0, 82.0, 82.0), "BOOST", "boost", recommend_boost)
	_draw_touch_button(Rect2(safe_rect.end.x - 132.0, bottom_y - 112.0, 108.0, 108.0), "GAS", "accelerate")

func _validate_mobile_hitboxes(safe_rect: Rect2) -> void:
	var interactive_count: int = 0
	var invalid_count: int = 0
	for item in buttons:
		var button_id: String = String(item.get("id", ""))
		if not button_id.begins_with("touch:") and button_id != "pause_open":
			continue
		interactive_count += 1
		if not safe_rect.encloses(Rect2(item.get("rect", Rect2()))):
			invalid_count += 1
	var verdict: String = "PASS" if invalid_count == 0 and interactive_count >= 6 else "FAIL"
	print("[SAFE_AREA_QA] %s interactive=%d outside_safe_area=%d bounds=%s" % [verdict, interactive_count, invalid_count, str(safe_rect)])

func _draw_touch_button(rect: Rect2, label: String, action: String, recommended: bool = false) -> void:
	var center: Vector2 = rect.position + rect.size * 0.5
	var radius: float = rect.size.x * 0.5
	var pressed: bool = bool(game.touch_actions.get(action, false))
	if recommended and not pressed:
		var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.008)
		draw_circle(center, radius + 7.0, Color(0.95, 0.63, 0.2, 0.12 + 0.12 * pulse))
	draw_circle(center, radius, Color8(18, 27, 25, 170))
	var button_color: Color = Color8(181, 111, 65, 220) if pressed else Color8(151, 111, 48, 220) if recommended else Color8(68, 82, 70, 205)
	draw_circle(center, radius - 5.0, button_color)
	var label_size: int = 14 if label.length() > 4 else 20
	var text_width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_size).x
	_draw_text(label, center.x - text_width * 0.5, center.y + float(label_size) * 0.36, label_size, Color8(248, 236, 208))
	buttons.append({"rect": rect, "id": "touch:" + action})

func _draw_pause(size: Vector2) -> void:
	buttons.clear()
	draw_rect(Rect2(Vector2.ZERO, size), Color8(13, 20, 19, 150))
	var safe_rect: Rect2 = _safe_bounds(size)
	var panel := Rect2(safe_rect.get_center() - Vector2(210.0, 195.0), Vector2(420.0, 390.0))
	_draw_panel(panel, Color8(30, 41, 37, 248))
	_draw_text("FAHRT PAUSIERT", panel.position.x + 77.0, panel.position.y + 42.0, 26, Color8(239, 219, 174))
	_draw_text("Tippe auf Weiterfahren" if game.mobile_target else "ESC zum Weiterfahren", panel.position.x + 112.0, panel.position.y + 72.0, 15, Color8(184, 193, 169))
	_draw_text("GESAMTLAUTSTÄRKE", panel.position.x + 28.0, panel.position.y + 100.0, 13, Color8(210, 176, 116))
	var volume_slider := Rect2(panel.position.x + 28.0, panel.position.y + 115.0, 254.0, 12.0)
	draw_rect(volume_slider, Color8(61, 70, 59))
	draw_rect(Rect2(volume_slider.position, Vector2(volume_slider.size.x * float(game.master_volume), volume_slider.size.y)), Color8(198, 155, 84))
	draw_circle(Vector2(volume_slider.position.x + volume_slider.size.x * float(game.master_volume), volume_slider.position.y + volume_slider.size.y * 0.5), 9.0, Color8(239, 219, 174))
	buttons.append({"rect": Rect2(volume_slider.position.x - 8.0, volume_slider.position.y - 12.0, volume_slider.size.x + 16.0, 36.0), "id": "volume_slider"})
	var volume_label: String = "AUS" if float(game.master_volume) <= 0.01 else "%d%%" % int(round(float(game.master_volume) * 100.0))
	_draw_button(Rect2(panel.position.x + 312.0, panel.position.y + 96.0, 80.0, 38.0), volume_label, "volume_mute", Color8(74, 82, 68))
	_draw_text("MUSIK", panel.position.x + 28.0, panel.position.y + 158.0, 13, Color8(210, 176, 116))
	var music_volume_slider := Rect2(panel.position.x + 28.0, panel.position.y + 173.0, 254.0, 12.0)
	draw_rect(music_volume_slider, Color8(61, 70, 59))
	draw_rect(Rect2(music_volume_slider.position, Vector2(music_volume_slider.size.x * float(game.music_volume), music_volume_slider.size.y)), Color8(198, 155, 84))
	draw_circle(Vector2(music_volume_slider.position.x + music_volume_slider.size.x * float(game.music_volume), music_volume_slider.position.y + music_volume_slider.size.y * 0.5), 9.0, Color8(239, 219, 174))
	buttons.append({"rect": Rect2(music_volume_slider.position.x - 8.0, music_volume_slider.position.y - 12.0, music_volume_slider.size.x + 16.0, 36.0), "id": "music_volume_slider"})
	var music_volume_label: String = "AUS" if float(game.music_volume) <= 0.01 else "%d%%" % int(round(float(game.music_volume) * 100.0))
	_draw_button(Rect2(panel.position.x + 312.0, panel.position.y + 154.0, 80.0, 38.0), music_volume_label, "music_volume_mute", Color8(74, 82, 68))
	_draw_text("VIBRATION", panel.position.x + 28.0, panel.position.y + 216.0, 13, Color8(210, 176, 116))
	var haptics_slider := Rect2(panel.position.x + 28.0, panel.position.y + 231.0, 254.0, 12.0)
	draw_rect(haptics_slider, Color8(61, 70, 59))
	draw_rect(Rect2(haptics_slider.position, Vector2(haptics_slider.size.x * float(game.haptic_strength), haptics_slider.size.y)), Color8(198, 155, 84))
	draw_circle(Vector2(haptics_slider.position.x + haptics_slider.size.x * float(game.haptic_strength), haptics_slider.position.y + haptics_slider.size.y * 0.5), 9.0, Color8(239, 219, 174))
	# Keep the label area free so a center tap on the pause card resumes the run.
	buttons.append({"rect": Rect2(haptics_slider.position.x - 8.0, haptics_slider.position.y - 6.0, haptics_slider.size.x + 16.0, 24.0), "id": "haptics_slider"})
	var haptics_label: String = "AUS" if float(game.haptic_strength) <= 0.01 else "%d%%" % int(round(float(game.haptic_strength) * 100.0))
	var haptics_value_rect := Rect2(panel.position.x + 312.0, panel.position.y + 212.0, 80.0, 38.0)
	draw_rect(haptics_value_rect, Color8(74, 82, 68))
	draw_rect(haptics_value_rect, Color8(232, 200, 143), false, 2.0)
	var haptics_text_width: float = font.get_string_size(haptics_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16).x
	_draw_text(haptics_label, haptics_value_rect.position.x + (haptics_value_rect.size.x - haptics_text_width) * 0.5, haptics_value_rect.position.y + 25.0, 16, Color8(250, 239, 211))
	_draw_button(Rect2(panel.position.x + 75.0, panel.position.y + 307.0, 270.0, 48.0), "WEITERFAHREN", "pause_resume", Color8(135, 103, 60))
	_draw_button(Rect2(panel.position.x + 75.0, panel.position.y + 260.0, 270.0, 36.0), "DATENSCHUTZ", "privacy_open", Color8(57, 69, 62))
	# Let a tap anywhere on the pause card resume the run on touch screens.
	if game.mobile_target:
		buttons.append({"rect": panel, "id": "pause_resume"})

func _draw_privacy(size: Vector2) -> void:
	buttons.clear()
	draw_rect(Rect2(Vector2.ZERO, size), Color8(13, 20, 19, 225))
	var safe_rect: Rect2 = _safe_bounds(size)
	var panel_width: float = minf(780.0, safe_rect.size.x - 40.0)
	var panel_height: float = minf(500.0, safe_rect.size.y - 40.0)
	var panel := Rect2(safe_rect.get_center() - Vector2(panel_width, panel_height) * 0.5, Vector2(panel_width, panel_height))
	draw_rect(panel, Color8(30, 41, 37, 252))
	draw_rect(panel, Color8(177, 146, 99), false, 2.0)
	_draw_text("DATENSCHUTZ", panel.position.x + 28.0, panel.position.y + 43.0, 24, Color8(239, 219, 174))
	var text_position := Vector2(panel.position.x + 28.0, panel.position.y + 84.0)
	draw_multiline_string(font, text_position, _privacy_text, HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 56.0, 15, -1, Color8(215, 219, 199))
	if is_instance_valid(ads_service) and bool(ads_service.call("is_privacy_options_required")):
		_draw_button(Rect2(panel.position.x + panel.size.x * 0.5 - 142.0, panel.position.y + panel.size.y - 111.0, 284.0, 38.0), "EINWILLIGUNG ÄNDERN", "privacy_options", Color8(57, 69, 62))
	_draw_button(Rect2(panel.position.x + panel.size.x * 0.5 - 110.0, panel.position.y + panel.size.y - 61.0, 220.0, 42.0), "SCHLIESSEN", "privacy_close", Color8(74, 82, 68))

func _draw_result(size: Vector2, won: bool) -> void:
	buttons.clear()
	draw_rect(Rect2(Vector2.ZERO, size), Color8(13, 20, 19, 72 if won else 145))
	var safe_rect: Rect2 = _safe_bounds(size)
	var show_rewarded_offer: bool = not won and game.mobile_target and is_instance_valid(ads_service) and bool(ads_service.call("has_rewarded_ad_for_current_failure"))
	var panel_height: float = 520.0 if not won and game.mobile_target else 480.0
	var panel_width: float = minf(492.0, safe_rect.size.x - 32.0)
	var panel_x: float = safe_rect.end.x - panel_width - 24.0 if won and safe_rect.size.x >= 980.0 else safe_rect.get_center().x - panel_width * 0.5
	var panel := Rect2(panel_x, safe_rect.get_center().y - panel_height * 0.5, panel_width, panel_height)
	_draw_panel(panel, Color8(30, 41, 37, 250))
	if won:
		draw_rect(Rect2(panel.position, Vector2(panel.size.x, 6.0)), Color8(215, 166, 84))
		var medal_center := Vector2(panel.position.x + 43.0, panel.position.y + 49.0)
		draw_circle(medal_center, 22.0, Color8(215, 166, 84))
		draw_circle(medal_center, 16.0, Color8(50, 56, 43))
		draw_circle(medal_center, 11.0, Color8(231, 190, 108))
		draw_circle(medal_center, 4.0, Color8(101, 70, 42))
		var final_rescue_finished: bool = String(game.screen_state) == "WIN" and game.final_rescue_completed
		var completed_world_index: int = CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() - 1 if final_rescue_finished else game.run_world_index
		var completed_world: Dictionary = game.world_data(completed_world_index)
		var final_world: bool = game.run_world_index == CAMPAIGN_DATA.PLAYABLE_WORLD_COUNT - 1
		_draw_text("RETTUNG ERREICHT" if final_rescue_finished else "ABSCHNITT ABGESCHLOSSEN" if final_world else "WELT ABGESCHLOSSEN", panel.position.x + 78.0, panel.position.y + 39.0, 12, Color8(221, 179, 99))
		_draw_text(String(completed_world.get("city", "AMSTERDAM")).to_upper(), panel.position.x + 78.0, panel.position.y + 70.0, 26, Color8(239, 219, 174))
		var victory_detail: String = "KAMPAGNE ABGESCHLOSSEN · RETTUNGSSCHIFF ERREICHT" if final_rescue_finished else "WEITERE STRECKEN FOLGEN SPÄTER" if final_world else "NÄCHSTE ETAPPE: %s" % String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[game.run_world_index + 1].get("city", "EUROPA")).to_upper()
		if game.vehicle_unlocked_this_run:
			victory_detail = game.vehicle_unlock_message()
		_draw_text(victory_detail, panel.position.x + 28.0, panel.position.y + 105.0, 13, Color8(235, 190, 113))
	else:
		var failed_world: Dictionary = game.world_data(game.run_world_index)
		_draw_text("FAHRT BEENDET · %s" % String(failed_world.get("city", "")).to_upper(), panel.position.x + 45.0, panel.position.y + 57.0, 22, Color8(239, 219, 174))
		_draw_text("Nächstes Etappenziel: %s" % game.next_checkpoint_name(float(game.campaign_meter)), panel.position.x + 45.0, panel.position.y + 91.0, 15, Color8(184, 193, 169))
		var result_unlock_info: String = "%s · IN DER WERKSTATT WÄHLEN" % game.vehicle_unlock_message() if game.vehicle_unlocked_this_run else ""
		if not result_unlock_info.is_empty():
			_draw_text(result_unlock_info, panel.position.x + 45.0, panel.position.y + 116.0, 12, Color8(235, 190, 113))
	_draw_text("Strecke dieser Fahrt", panel.position.x + 45.0, panel.position.y + 139.0, 14, Color8(178, 189, 164))
	var amount_x: float = panel.position.x + panel.size.x - 114.0
	_draw_text("%d m" % int(game.run_distance), amount_x, panel.position.y + 139.0, 17, Color8(235, 225, 190))
	_draw_text("Fahrt, Zombies & Funde", panel.position.x + 45.0, panel.position.y + 173.0, 14, Color8(178, 189, 164))
	_draw_text("+%d" % int(game.run_reward - game.run_checkpoint_reward), amount_x, panel.position.y + 173.0, 17, Color8(235, 190, 113))
	_draw_text("Etappenbonus", panel.position.x + 45.0, panel.position.y + 207.0, 14, Color8(178, 189, 164))
	_draw_text("+%d" % int(game.run_checkpoint_reward), amount_x, panel.position.y + 207.0, 17, Color8(235, 190, 113))
	_draw_text("Kontostand", panel.position.x + 45.0, panel.position.y + 241.0, 14, Color8(178, 189, 164))
	_draw_text("%d" % int(game.money), amount_x, panel.position.y + 241.0, 17, Color8(235, 225, 190))
	var result_challenge: Dictionary = game.challenge_status()
	_draw_text("BONUSZIEL: %s" % String(result_challenge.get("title", "")), panel.position.x + 45.0, panel.position.y + 273.0, 13, Color8(232, 194, 121))
	_draw_text(String(result_challenge.get("progress_text", "NOCH OFFEN")), panel.position.x + 45.0, panel.position.y + 296.0, 12, Color8(195, 207, 177) if bool(result_challenge.get("achieved", false)) else Color8(184, 189, 164))
	var challenge_reward_text: String = "+%d MÜNZEN" % int(result_challenge.get("earned", 0)) if int(result_challenge.get("earned", 0)) > 0 else "MEDAILLE BEREITS GESICHERT" if bool(result_challenge.get("completed", false)) else "BONUS BEI ERFÜLLUNG: %d MÜNZEN" % int(result_challenge.get("reward", 0))
	_draw_text(challenge_reward_text, panel.position.x + panel.size.x - 232.0, panel.position.y + 296.0, 11, Color8(235, 190, 113))
	if not won:
		_draw_text(_next_upgrade_hint(), panel.position.x + 45.0, panel.position.y + 318.0, 11, Color8(232, 194, 121))
	var button_width: float = minf(362.0, panel.size.x - 48.0)
	var button_x: float = panel.position.x + (panel.size.x - button_width) * 0.5
	var garage_button_y: float = 342.0
	var rescue_ready: bool = String(game.screen_state) == "LEVEL_COMPLETE" and game.run_world_index == CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() - 1 and game.final_rescue_unlocked and not game.final_rescue_completed
	_draw_button(Rect2(button_x, panel.position.y + garage_button_y, button_width, 54.0), "LETZTE FLUCHT STARTEN" if rescue_ready else "ZUR WERKSTATT", "rescue_start" if rescue_ready else "garage", Color8(176, 102, 58))
	if won:
		var map_label: String = "EUROPAKARTE" if String(game.screen_state) == "WIN" else "EUROPAKARTE ÖFFNEN"
		_draw_button(Rect2(button_x, panel.position.y + 404.0, button_width, 44.0), map_label, "map_open", Color8(118, 91, 55))
		if not game.mobile_target:
			_draw_text("ENTER: WERKSTATT   •   KARTE: STRECKE WÄHLEN", panel.position.x + 102.0, panel.position.y + 466.0, 12, Color8(178, 183, 157))
	elif game.mobile_target:
		if show_rewarded_offer:
			_draw_button(Rect2(button_x, panel.position.y + 404.0, button_width, 44.0), "VIDEO ANSEHEN · +500 MÜNZEN", "rewarded_coins", Color8(116, 91, 54))
		elif is_instance_valid(ads_service) and String(ads_service.get("service_status")).begins_with("Belohnungsvideo"):
			_draw_text("BELOHNUNGSVIDEO DERZEIT NICHT VERFÜGBAR", panel.position.x + 45.0, panel.position.y + 429.0, 11, Color8(178, 183, 157))
	else:
		_draw_text("ENTER", panel.position.x + 218.0, panel.position.y + 409.0, 12, Color8(178, 183, 157))

func _next_upgrade_hint() -> String:
	var parts: Array[String] = ["engine", "tank", "tires", "armor", "nitro"]
	var labels: Dictionary = {"engine": "MOTOR", "tank": "TANK", "tires": "REIFEN", "armor": "PANZERUNG", "nitro": "NITRO"}
	var tank_price: int = game.upgrade_price("tank")
	if float(game.wagon.fuel) <= 0.01 and tank_price >= 0:
		if int(game.money) >= tank_price:
			return "WERKSTATT: TANK-UPGRADE FÜR %d MÜNZEN BEREIT" % tank_price
		var tank_coins_missing: int = tank_price - int(game.money)
		return "NÄCHSTER KAUF: TANK · NOCH %d MÜNZEN" % tank_coins_missing
	var next_part: String = ""
	for part in parts:
		var price: int = game.upgrade_price(part)
		if price < 0:
			continue
		if next_part.is_empty():
			next_part = part
		if int(game.money) >= price:
			return "WERKSTATT: %s-UPGRADE FÜR %d MÜNZEN BEREIT" % [String(labels[part]), price]
	if next_part.is_empty():
		return "%s VOLL AUSGEBAUT · WEITER BIS %s" % [game.current_vehicle_name().to_upper(), game.next_checkpoint_name(float(game.campaign_meter))]
	var missing: int = maxi(0, game.upgrade_price(next_part) - int(game.money))
	return "NÄCHSTER KAUF: %s · NOCH %d MÜNZEN" % [String(labels[next_part]), missing]

func _draw_panel(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(0.0, 4.0), rect.size), Color8(0, 0, 0, 96))
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), Color8(78, 174, 178, 72))
	draw_rect(rect, Color8(106, 149, 145, 145), false, 1.0)

func _draw_coin_badge(x: float, y: float, text: String) -> void:
	var rect := Rect2(x, y, 176.0, 43.0)
	_draw_panel(rect, Color8(27, 38, 36, 220))
	draw_circle(Vector2(x + 22.0, y + 21.0), 10.0, Color8(215, 166, 84))
	draw_circle(Vector2(x + 22.0, y + 21.0), 5.0, Color8(132, 91, 45))
	_draw_text(text, x + 41.0, y + 27.0, 14, Color8(237, 220, 180))

func _draw_button(rect: Rect2, label: String, button_id: String, color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(0.0, 4.0), rect.size), Color8(0, 0, 0, 125))
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), Color8(255, 226, 167, 105))
	draw_rect(rect, Color8(225, 195, 143, 210), false, 1.5)
	var text_width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_draw_text(label, rect.position.x + (rect.size.x - text_width) * 0.5, rect.position.y + rect.size.y * 0.5 + 7.0, 16, Color8(7, 13, 13, 160))
	_draw_text(label, rect.position.x + (rect.size.x - text_width) * 0.5, rect.position.y + rect.size.y * 0.5 + 6.0, 16, Color8(250, 239, 211))
	buttons.append({"rect": rect, "id": button_id})

func _draw_text(text: String, x: float, y: float, font_size: int, color: Color) -> void:
	draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _format_kilometers(meters: float) -> String:
	return String.num(meters / 1000.0, 1).replace(".", ",")

func _draw_amsterdam_route_overview(area: Rect2) -> void:
	var image_height: float = area.size.x * ROUTE_OVERVIEW_TEXTURE.get_height() / float(ROUTE_OVERVIEW_TEXTURE.get_width())
	var image_rect := Rect2(area.position + Vector2(0.0, 4.0), Vector2(area.size.x, image_height))
	draw_texture_rect(ROUTE_OVERVIEW_TEXTURE, image_rect, false, Color8(195, 205, 187))
	draw_rect(image_rect, Color8(159, 139, 95), false, 1.0)
	_draw_text("DIE GRACHTENROUTE", area.position.x + 12.0, image_rect.end.y + 35.0, 16, Color8(239, 219, 174))
	var stations: Array[Dictionary] = [
		{"name": "START", "meter": 0.0},
		{"name": "BRÜCKENSPRUNG", "meter": AmsterdamPreviewCourse.RAMP_LIP_M - AmsterdamPreviewCourse.START_M},
		{"name": "LASTKAHN", "meter": AmsterdamPreviewCourse.BARGE_START_M - AmsterdamPreviewCourse.START_M},
		{"name": "SCHLEUSENBRÜCKE", "meter": AmsterdamPreviewCourse.LOCK_LIP_M - AmsterdamPreviewCourse.START_M},
		{"name": "ZIEL", "meter": AmsterdamPreviewCourse.AMSTERDAM_LENGTH_M}
	]
	var first_y: float = image_rect.end.y + 70.0
	var last_y: float = area.end.y - 31.0
	var line_x: float = area.position.x + 32.0
	draw_line(Vector2(line_x, first_y), Vector2(line_x, last_y), Color8(70, 84, 72), 5.0, true)
	var best: float = float(game.world_best_distances[0])
	var achieved: float = clampf(best / AmsterdamPreviewCourse.AMSTERDAM_LENGTH_M, 0.0, 1.0)
	draw_line(Vector2(line_x, first_y), Vector2(line_x, lerpf(first_y, last_y, achieved)), Color8(199, 148, 76), 3.0, true)
	for index in range(stations.size()):
		var station: Dictionary = stations[index]
		var y: float = lerpf(first_y, last_y, float(index) / float(stations.size() - 1))
		var reached: bool = best >= float(station["meter"])
		draw_circle(Vector2(line_x, y), 7.0, Color8(225, 202, 151))
		draw_circle(Vector2(line_x, y), 4.0, Color8(187, 105, 55) if reached else Color8(48, 66, 59))
		_draw_text(String(station["name"]), line_x + 24.0, y - 2.0, 14, Color8(234, 219, 183))
		_draw_text("%d M" % int(station["meter"]), line_x + 24.0, y + 16.0, 11, Color8(164, 180, 159))
