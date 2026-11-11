extends "res://scripts/driving_test.gd"

const QUICK_STARTS := {KEY_F5: 205.0, KEY_F6: 563.0, KEY_F7: 916.0, KEY_F8: 1090.0, KEY_F9: 1250.0}
var _jump_zoom := 1.0
var _quick_start_m := 0.0
var _quick_profile := 1

func _ready() -> void:
	if workshop_world_id.is_empty():
		workshop_vehicle = "kombi"
		workshop_upgrades = {"engine": 2, "tank": 1, "nitro": 1, "tires": 0}
	super._ready()
	course.connect("motor_part_found", _on_motor_part_found)
	course.connect("loading_edge_broke", _on_loading_edge_broke)
	course.connect("oil_drums_shot", _on_oil_drums_shot)
	course.connect("worksite_event", _on_worksite_event)
	_set_status("UTRECHT · MOTORTEIL SUCHEN" + (" · F4–F9: TESTSTART · F10: AUSBAU" if workshop_world_id.is_empty() else ""), 5.0)

func _on_motor_part_found() -> void:
	_set_status("MOTORTEIL GEFUNDEN · WEITER BIS ZUM ZIEL", 4.0)

func _test_profile_label() -> String:
	if not workshop_world_id.is_empty():
		return ""
	return "SERIENREIFEN TESTEN" if int(workshop_upgrades.get("tires", 0)) == 2 else "REIFEN II TESTEN"

func _toggle_test_profile() -> void:
	var tires := 0 if int(workshop_upgrades.get("tires", 0)) == 2 else 2
	workshop_upgrades["tires"] = tires
	_start_test_run()
	_set_status("UTRECHT · REIFEN II" if tires == 2 else "UTRECHT · SERIENREIFEN", 4.0)

func _finish_test_run(result: String = "ABSCHNITT FERTIG") -> void:
	if result == "ABSCHNITT FERTIG":
		result = "ZIEL ERREICHT · MOTORTEIL GEFUNDEN" if course.get("part_found") else "UTRECHT GESCHAFFT"
	super._finish_test_run(result)

func _physics_process(delta: float) -> void:
	camera.zoom /= _jump_zoom
	super._physics_process(delta)
	var framing := smoothstep(890.0, 938.0, distance_m) * (1.0 - smoothstep(992.0, 1038.0, distance_m))
	var ramp_lookahead := smoothstep(911.0, 931.0, distance_m) * (1.0 - smoothstep(942.0, 956.0, distance_m))
	var loading_view := smoothstep(580.0, 607.0, distance_m) * (1.0 - smoothstep(634.0, 660.0, distance_m))
	_jump_zoom = minf(lerpf(1.0, 0.73 - 0.20 * ramp_lookahead, framing), lerpf(1.0, 0.79, loading_view))
	camera.zoom *= _jump_zoom
	camera.offset = Vector2(178.0 + 112.0 * ramp_lookahead, clampf(390.0 - wagon.position.y, 0.0, 145.0)) * framing + Vector2(123.0, 55.0) * loading_view

func _start_test_run() -> void:
	_jump_zoom = 1.0
	if camera != null:
		camera.offset = Vector2.ZERO
	super._start_test_run()
	if _quick_start_m > 0.0:
		var offset := _quick_start_m * PIXELS_PER_METER
		wagon.reset_at(_start_x + offset, course)
		wagon.freeze = true
		distance_m = _quick_start_m
		camera.position = wagon.position + Vector2(278, -75)
		camera.reset_smoothing()
		camera.force_update_scroll()
		_set_status("UTRECHT · TESTSTART BEI %d M" % roundi(_quick_start_m), 3.0)

func _input(event: InputEvent) -> void:
	if workshop_world_id.is_empty() and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F10:
			_quick_profile = (_quick_profile + 1) % 3
			var presets := [{}, {"engine":2, "tank":1, "nitro":1, "tires":0}, {"engine":3, "tank":3, "nitro":3, "tires":3, "armor":3, "suspension":3, "brakes":3, "efficiency":3, "weapon":1}]
			workshop_upgrades = presets[_quick_profile].duplicate(true)
			_start_test_run()
			var names := ["SERIE", "FRÜHER AUSBAU", "VOLLAUSBAU MIT WAFFE"]
			_set_status("UTRECHT · " + names[_quick_profile], 3.5)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F4 or QUICK_STARTS.has(event.keycode):
			_quick_start_m = float(QUICK_STARTS.get(event.keycode, 0.0))
			_start_test_run()
			get_viewport().set_input_as_handled()
			return
	super._input(event)

func _update_hud(accelerate: bool, brake: bool, boost: bool) -> void:
	super._update_hud(accelerate, brake, boost)
	if _action_hint_label != null and not _finished and distance_m >= 215.0 and distance_m < 224.0:
		_action_hint_label.text = "FASSGRUPPE · EXPLOSION GREIFT AUF SPERRE ÜBER"
		_action_hint_label.visible = true
	elif _action_hint_label != null and not _finished and distance_m >= 1248.0 and distance_m < 1260.0:
		_action_hint_label.text = "SCHROTTHOF · FÄSSER VOR DER METALLSPERRE"
		_action_hint_label.visible = true
	elif _action_hint_label != null and not _finished and distance_m >= 350.0 and distance_m < 392.0:
		_action_hint_label.text = "BEHELFSBRÜCKE · AB 65 KM/H NITRO HALTEN"
		_action_hint_label.visible = true
	elif _action_hint_label != null and not _finished and distance_m >= 582.0 and distance_m < 608.0:
		_action_hint_label.text = "LADEKAI · LOSE BOHLEN · ANLAUF CA. 65–90 KM/H"
		_action_hint_label.visible = true
	elif _action_hint_label != null and not _finished and distance_m >= 670.0 and distance_m < 699.0:
		_action_hint_label.text = "BETONABSATZ · TEMPO KONTROLLIEREN"
		_action_hint_label.visible = true
	elif _action_hint_label != null and not _finished and distance_m >= 1188.0 and distance_m < 1211.0:
		_action_hint_label.text = "LOSE LADUNG · TROMMEL AUSROLLEN LASSEN"
		_action_hint_label.visible = true
	elif _action_hint_label != null and not _finished and distance_m >= 865.0 and distance_m < 890.0:
		_action_hint_label.text = "PROVISORISCHE ÜBERFAHRT · SCHWUNG HALTEN"
		_action_hint_label.visible = true
	elif _action_hint_label != null and not _finished and distance_m >= 910.0 and distance_m < 940.0:
		_action_hint_label.text = "SANDBERG · SCHWUNG HOLEN · STAHLPLATTFORM VORAUS"
		_action_hint_label.visible = true
	elif _action_hint_label != null and not _finished and distance_m >= 968.0 and distance_m < 986.0 and course.scaffold_load < 0.0:
		_action_hint_label.text = "GERÜST · OBEN SCHWUNG HALTEN · UNTEN BAUGRUBE"
		_action_hint_label.visible = true
	elif _action_hint_label != null and not _finished and distance_m >= 1107.0 and distance_m < 1144.0:
		_action_hint_label.text = "PUMPWERK · SCHWUNG HALTEN"
		_action_hint_label.visible = true

func _on_encounter_hit(kind: String, resistance: float, variant_id: int, group_size: int, world_x: float, ground_y: float, speed_before_mps: float) -> void:
	if _finished or _paused or _arrival_time_s >= 0:
		return
	if kind == "rolling_feedback":
		_set_status("KABELTROMMEL ANGESTOSSEN · -%.0f%% ZUSTAND" % resistance, 1.5)
		_blast_shake_s = maxf(_blast_shake_s, minf(0.12, resistance * 0.02))
		if _impact_player != null:
			_impact_player.play()
		return
	var health_before: float = wagon.durability
	super._on_encounter_hit(kind, resistance, variant_id, group_size, world_x, ground_y, speed_before_mps)
	var damage: float = health_before - wagon.durability
	if kind in ["scrap_wall", "oil_drums", "pallet_stack", "cable_spool"] and damage > 0.0:
		_blast_shake_s = maxf(_blast_shake_s, clampf(damage * 0.022, 0.04, 0.15))
	var label := ""
	match kind:
		"pallet_stack":
			if course.girder_bonus and world_x / PIXELS_PER_METER > course.GIRDER_DESCENT_M:
				_set_status("STAHLTRÄGER-KOMBO · +12 MÜNZEN", 2.0)
				return
			label = "PALETTEN ZERSPLITTERT"
		"oil_drums": label = "ÖLFÄSSER EXPLODIERT"
		"road_sign": label = "BAUSCHILD UMGEFAHREN"
		"cable_spool": label = "KABELTROMMEL WEGGERAMMT"
		"work_fence": label = "SCHALUNG STÜRZT EIN" if absf(world_x / PIXELS_PER_METER - course.FORMWORK_M) < 0.3 else "BAUZAUN DURCHBROCHEN"
		"drain_pipes": label = "ROHRLADUNG ROLLT WEG"
		"scrap_wall": label = "SCHROTTSPERRE ZERLEGT"
	if not label.is_empty():
		_set_status("%s · -%.0f KM/H · -%.0f%% ZUSTAND" % [label, _last_collision_loss_kmh, health_before - wagon.durability])








func _on_wagon_landed(impact_speed: float) -> void:
	super._on_wagon_landed(impact_speed)
	var meter := wagon.position.x / PIXELS_PER_METER
	if meter < course.TILT_START_M or meter >= course.TILT_EXIT_M:
		return
	if wagon.position.y < 510.0 or impact_speed < 155.0:
		return
	var damage := clampf((impact_speed - 155.0) / 44.0, 0.0, 3.0)
	wagon.record_damage_contact(wagon.global_position + Vector2(37, 25))
	wagon.durability = maxf(0.0, wagon.durability - damage)
	_blast_shake_s = maxf(_blast_shake_s, minf(0.13, damage * 0.045))
	course.spawn_impact_particles(wagon.position.x, course.height_at(wagon.position.x) + 12.0, 0.42, true)

func _on_bonus_coin_collected(amount: int) -> void:
	if amount == course.SCAFFOLD_BONUS:
		_preview_bonus_coins += amount
		_set_status("GERÜST GESCHAFFT · +%d MÜNZEN" % amount, 2.3)
		return
	if amount == course.PUMP_BONUS and course.pump_cleared:
		_preview_bonus_coins += amount
		_set_status("PUMPWERK GESCHAFFT · +%d MÜNZEN" % amount, 2.3)
		return
	if amount in [course.LOADING_BONUS, course.ROLL_BONUS]:
		_preview_bonus_coins += amount
		var label := "LADEKAI ERREICHT" if amount == course.LOADING_BONUS else "TROMMEL UMSPIELT"
		_set_status("%s · +%d MÜNZEN" % [label, amount], 2.3)
		return
	if amount == 25:
		_preview_bonus_coins += amount
		_set_status("ÜBERFAHRT GESCHAFFT · +25 MÜNZEN", 2.3)
		return
	super._on_bonus_coin_collected(amount)



func _on_loading_edge_broke() -> void:
	if _impact_player != null:
		_impact_player.play()
	_set_status("LADEKAI · BOHLEN BRECHEN WEG", 1.2)

func _on_oil_drums_shot() -> void:
	_on_structure_blast(0.13)
	_set_status("ÖLFÄSSER VORAUS GETROFFEN", 1.5)

func _on_worksite_event(message: String, impact: float) -> void:
	if impact > 0.0:
		_on_structure_blast(impact)
	_set_status(message, 1.6)
