extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const EXPECTED_MUSIC_DURATION_S: float = 75.0

func _ready() -> void:
	call_deferred("_run_audio_system_smoke")

func _run_audio_system_smoke() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var audio: Node = game.get_node("AudioManager")
	var music_a: AudioStreamPlayer = audio.get_node("MusicA") as AudioStreamPlayer
	var music_b: AudioStreamPlayer = audio.get_node("MusicB") as AudioStreamPlayer
	assert(music_a != null and music_b != null, "The music crossfade requires both playback decks.")
	assert(music_a.stream != null and music_a.stream == music_b.stream, "Both decks must use the authored road score.")
	assert(music_a.stream.get_length() >= EXPECTED_MUSIC_DURATION_S, "The score should contain a long-form musical loop.")
	assert(music_a.playing and not music_b.playing, "The first music deck should start with the production scene.")
	assert((music_a.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED, "The crossfade system controls looping; the stream must not hard-loop.")

	game.screen_state = "GARAGE"
	assert(is_equal_approx(float(audio.call("_music_target_db")), -21.0), "Garage music should be clear and restrained.")
	game.screen_state = "MAP"
	assert(is_equal_approx(float(audio.call("_music_target_db")), -24.0), "The world map should use a quieter music level.")
	game.screen_state = "ARCHIVE"
	assert(is_equal_approx(float(audio.call("_music_target_db")), -24.0), "The story archive should keep a quiet reading mix.")
	game.screen_state = "RUN"
	game.paused = false
	assert(is_equal_approx(float(audio.call("_music_target_db")), -26.0), "Driving music should sit under the engine.")
	game.paused = true
	assert(is_equal_approx(float(audio.call("_music_target_db")), -21.0), "Pausing should lift the music above the engine bed.")
	game.paused = false
	game.screen_state = "RESULT"
	assert(is_equal_approx(float(audio.call("_music_target_db")), -22.0), "A level result should use its own music level.")
	game.screen_state = "LEVEL_COMPLETE"
	assert(is_equal_approx(float(audio.call("_music_target_db")), -19.0), "A completed level should lift the score.")
	game.screen_state = "WIN"
	assert(is_equal_approx(float(audio.call("_music_target_db")), -19.0), "A campaign win should lift the score.")
	game.screen_state = "ENDING"
	assert(is_equal_approx(float(audio.call("_music_target_db")), -18.0), "The rescue finale should receive the score's strongest state mix.")
	game.radio_time = 3.0
	assert(float(audio.call("_music_target_db")) <= -31.0, "Radio dialogue should duck the score.")
	game.radio_time = 0.0
	game.screen_state = "RUN"
	game.touch_actions["boost"] = true
	assert(float(audio.call("_music_target_db")) <= -29.0, "Boost should duck the score under its sound effect.")
	game.touch_actions["boost"] = false
	game.screen_state = "GARAGE"

	var length_s: float = music_a.stream.get_length()
	var crossfade_duration_s: float = float(audio.get("_music_crossfade_duration_s"))
	var crossfade_threshold_s: float = length_s - crossfade_duration_s
	assert(not bool(audio.call("_should_begin_music_crossfade", crossfade_threshold_s - 0.01)), "The next deck should not start before the crossfade window.")
	assert(bool(audio.call("_should_begin_music_crossfade", crossfade_threshold_s + 0.01)), "The next deck should start inside the crossfade window.")
	audio.call("_begin_music_crossfade", music_a)
	assert(bool(audio.get("_music_crossfading")) and music_b.playing, "A second deck should start before the current score ends.")
	audio.call("_update_music", float(audio.get("_music_crossfade_duration_s")))
	assert(int(audio.get("_music_active_slot")) == 1 and music_b.playing and not music_a.playing, "The crossfade should promote the new deck and stop the old one.")
	audio.call("_begin_music_crossfade", music_b)
	assert(bool(audio.get("_music_crossfading")) and music_a.playing, "The crossfade must alternate decks on later loops.")
	audio.call("_update_music", float(audio.get("_music_crossfade_duration_s")))
	assert(int(audio.get("_music_active_slot")) == 0 and music_a.playing and not music_b.playing, "The original deck should be reusable after the second crossfade.")

	var hud: Control = game.get_node("HUDLayer/HUD") as Control
	var original_music_volume: float = float(game.music_volume)
	game.screen_state = "GARAGE"
	game.set_music_volume(1.0, false)
	var full_volume_db: float = float(audio.call("_music_target_db"))
	game.set_music_volume(0.5, false)
	var half_volume_db: float = float(audio.call("_music_target_db"))
	assert(is_equal_approx(half_volume_db, full_volume_db - 6.0206), "Half slider travel should apply half the linear signal amplitude.")
	game.set_music_volume(0.0, false)
	assert(is_equal_approx(float(audio.call("_music_target_db")), -42.0), "A zero music volume should mute the score.")
	game.set_music_volume(original_music_volume, false)

	game.set_music_volume(0.37, true)
	var saved_settings := ConfigFile.new()
	assert(saved_settings.load("user://progress.cfg") == OK, "Music settings should be written to the normal game save file.")
	assert(is_equal_approx(float(saved_settings.get_value("settings", "music_volume", -1.0)), 0.37), "The saved music volume should match the player setting.")
	game._load_progress()
	assert(is_equal_approx(float(game.music_volume), 0.37), "The saved music volume should reload into the game.")

	game.first_drive_tutorial_completed = true
	game.screen_state = "RUN"
	game.paused = true
	hud.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	var music_slider_rect: Rect2 = Rect2()
	var has_music_mute_button: bool = false
	var hud_buttons: Array = hud.get("buttons")
	for button in hud_buttons:
		var button_data: Dictionary = button
		if String(button_data.get("id", "")) == "music_volume_slider":
			music_slider_rect = button_data.get("rect", Rect2())
		elif String(button_data.get("id", "")) == "music_volume_mute":
			has_music_mute_button = true
	assert(music_slider_rect.size.x > 0.0 and has_music_mute_button, "The pause screen should draw separate music slider and mute controls.")
	hud.call("_press_at", music_slider_rect.get_center(), 41)
	hud.call("_process", 0.016)
	var active_touches: Dictionary = hud.get("active_touches")
	assert(String(active_touches.get(41, "")) == "music_volume_slider", "A touch should capture the music slider.")
	var slider_drag_position := Vector2(hud.get_size().x * 0.5 - 182.0 + 254.0 * 0.25, music_slider_rect.get_center().y)
	hud.call("_drag_at", slider_drag_position, 41)
	assert(is_equal_approx(float(game.music_volume), 0.25), "Dragging the music slider should change the live music gain.")
	hud.call("_release_touch", 41)
	var persisted_settings := ConfigFile.new()
	assert(persisted_settings.load("user://progress.cfg") == OK and is_equal_approx(float(persisted_settings.get_value("settings", "music_volume", -1.0)), 0.25), "Releasing the music slider should persist its final value.")
	active_touches[73] = "accelerate"
	game.touch_actions["accelerate"] = true
	hud.call("_process", 0.016)
	assert(not active_touches.has(73) and not bool(game.touch_actions["accelerate"]), "Pausing should still clear held vehicle controls.")
	hud.call("_handle_button", "music_volume_mute")
	assert(is_equal_approx(float(game.music_volume), 0.0), "The music mute button should switch the score off.")
	hud.call("_handle_button", "music_volume_mute")
	assert(is_equal_approx(float(game.music_volume), 1.0), "The music mute button should restore the default score level.")
	game.set_music_volume(original_music_volume, true)
	game.paused = false

	print("AUDIO_SYSTEM_OK duration_s=%.1f state_mix_9=true archive_reading_mix=true radio_boost_duck=true alternating_crossfade=true independent_volume=true settings_persist=true pause_touch=true" % length_s)
	get_tree().quit(0)
