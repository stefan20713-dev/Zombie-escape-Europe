extends Node

const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const QA_DIAGNOSTICS = preload("res://scripts/qa_diagnostics.gd")
const MUSIC_SILENCE_DB: float = -42.0
const MUSIC_CROSSFADE_SECONDS: float = 4.0

@onready var game = get_parent()
@onready var engine_player: AudioStreamPlayer = get_node("Engine")
@onready var boost_player: AudioStreamPlayer = get_node("Boost")
@onready var pickup_player: AudioStreamPlayer = get_node("Pickup")
@onready var impact_player: AudioStreamPlayer = get_node("Impact")
@onready var ui_player: AudioStreamPlayer = get_node("UI")
@onready var upgrade_player: AudioStreamPlayer = get_node("Upgrade")
@onready var music_player_a: AudioStreamPlayer = get_node("MusicA")
@onready var music_player_b: AudioStreamPlayer = get_node("MusicB")

var _boost_was_active: bool = false
var _music_active_slot: int = 0
var _music_crossfading: bool = false
var _music_crossfade_progress: float = 0.0
var _music_crossfade_duration_s: float = MUSIC_CROSSFADE_SECONDS
var _music_stream_length_s: float = 0.0
var _music_crossfade_old_start_db: float = MUSIC_SILENCE_DB

func _ready() -> void:
	var engine_stream: AudioStreamWAV = engine_player.stream as AudioStreamWAV
	if engine_stream != null:
		engine_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		engine_stream.loop_begin = 0
		engine_stream.loop_end = engine_stream.data.size() / 2
	engine_player.volume_db = -42.0
	boost_player.volume_db = -4.0
	impact_player.volume_db = 1.0
	var music_stream: AudioStreamWAV = music_player_a.stream as AudioStreamWAV
	if music_stream != null:
		music_stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	_music_stream_length_s = music_player_a.stream.get_length() if music_player_a.stream != null else 0.0
	if _music_stream_length_s > 0.0:
		_music_crossfade_duration_s = minf(MUSIC_CROSSFADE_SECONDS, _music_stream_length_s * 0.35)
	music_player_a.volume_db = MUSIC_SILENCE_DB
	music_player_b.volume_db = MUSIC_SILENCE_DB
	if music_player_a.stream != null:
		music_player_a.play()
	if QA_DIAGNOSTICS.enabled():
		print("[AUDIO_QA] music_started=%s duration_s=%.2f crossfade_s=%.2f" % [str(music_player_a.playing), _music_stream_length_s, _music_crossfade_duration_s])

func _process(delta: float) -> void:
	_update_music(delta)
	var driving: bool = game.screen_state == "RUN" and not game.paused
	var boosting: bool = driving and _boost_is_pressed() and game.wagon.nitro_level > 0 and game.wagon.nitro > 0.0 and game.wagon.fuel > 0.0
	if boosting and not _boost_was_active:
		boost_player.play()
	_boost_was_active = boosting
	if driving:
		if not engine_player.playing:
			engine_player.play()
		var speed_reference_mps: float = maxf(1.0, float(game.wagon.get("_max_speed_pixels_s")) / CAMPAIGN_DATA.PIXELS_PER_METER)
		var speed_fraction: float = clampf(absf(game.wagon.speed_mps) / speed_reference_mps, 0.0, 1.0)
		var throttle: bool = _throttle_is_pressed()
		engine_player.pitch_scale = clampf(0.78 + speed_fraction * 0.72 + (0.14 if throttle else 0.0), 0.72, 1.72)
		var load_fraction: float = clampf(speed_fraction * 0.72 + (0.28 if throttle else 0.0), 0.0, 1.0)
		var target_volume: float = lerpf(-29.0, -12.5, load_fraction)
		if boosting:
			target_volume = -9.5
		engine_player.volume_db = lerpf(engine_player.volume_db, target_volume, 1.0 - exp(-delta * 5.0))
	else:
		engine_player.volume_db = lerpf(engine_player.volume_db, -42.0, 1.0 - exp(-delta * 4.0))
		if engine_player.playing and engine_player.volume_db <= -41.5:
			engine_player.stop()

func _update_music(delta: float) -> void:
	if music_player_a.stream == null or _music_stream_length_s <= 0.0:
		return
	var target_db: float = _music_target_db()
	if not _music_crossfading:
		var active_player: AudioStreamPlayer = _music_player(_music_active_slot)
		if not active_player.playing:
			active_player.volume_db = MUSIC_SILENCE_DB
			active_player.play()
		active_player.volume_db = lerpf(active_player.volume_db, target_db, 1.0 - exp(-delta * 1.5))
		if _should_begin_music_crossfade(active_player.get_playback_position()):
			_begin_music_crossfade(active_player)
		return

	_music_crossfade_progress = minf(1.0, _music_crossfade_progress + delta / maxf(0.05, _music_crossfade_duration_s))
	var blend: float = _music_crossfade_progress * _music_crossfade_progress * (3.0 - 2.0 * _music_crossfade_progress)
	var old_player: AudioStreamPlayer = _music_player(_music_active_slot)
	var next_slot: int = 1 - _music_active_slot
	var next_player: AudioStreamPlayer = _music_player(next_slot)
	old_player.volume_db = lerpf(_music_crossfade_old_start_db, MUSIC_SILENCE_DB, blend)
	next_player.volume_db = lerpf(MUSIC_SILENCE_DB, target_db, blend)
	if _music_crossfade_progress >= 1.0:
		old_player.stop()
		next_player.volume_db = target_db
		_music_active_slot = next_slot
		_music_crossfading = false
		_music_crossfade_progress = 0.0

func _should_begin_music_crossfade(playback_position_s: float) -> bool:
	return playback_position_s >= _music_stream_length_s - _music_crossfade_duration_s

func _begin_music_crossfade(old_player: AudioStreamPlayer) -> void:
	var next_slot: int = 1 - _music_active_slot
	var next_player: AudioStreamPlayer = _music_player(next_slot)
	next_player.stop()
	next_player.volume_db = MUSIC_SILENCE_DB
	next_player.play()
	_music_crossfade_old_start_db = old_player.volume_db
	_music_crossfade_progress = 0.0
	_music_crossfading = true

func _music_target_db() -> float:
	var target_db: float = -23.0
	match String(game.screen_state):
		"GARAGE":
			target_db = -21.0
		"MAP":
			target_db = -24.0
		"ARCHIVE":
			target_db = -24.0
		"RUN":
			target_db = -26.0 if not game.paused else -21.0
		"RESULT":
			target_db = -22.0
		"LEVEL_COMPLETE", "WIN":
			target_db = -19.0
		"ENDING":
			target_db = -18.0
	if game.screen_state == "RUN" and _boost_is_pressed():
		target_db = minf(target_db, -29.0)
	var user_music_volume: float = clampf(float(game.music_volume), 0.0, 1.0)
	if user_music_volume <= 0.01:
		return MUSIC_SILENCE_DB
	return target_db + linear_to_db(user_music_volume)

func _music_player(slot: int) -> AudioStreamPlayer:
	return music_player_a if slot == 0 else music_player_b

func play_effect(effect: String) -> void:
	match effect:
		"boost":
			boost_player.play()
		"pickup":
			pickup_player.play()
		"impact":
			impact_player.play()
		"upgrade":
			upgrade_player.play()
		_:
			ui_player.play()

func _throttle_is_pressed() -> bool:
	return Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or bool(game.touch_actions.get("accelerate", false))

func _boost_is_pressed() -> bool:
	return Input.is_key_pressed(KEY_SPACE) or bool(game.touch_actions.get("boost", false))
