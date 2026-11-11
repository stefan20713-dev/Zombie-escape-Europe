extends Node2D

const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const BACKDROP_SCENE: PackedScene = preload("res://scenes/backdrop.tscn")
const SUPPORTED_KINDS: Array[String] = ["clear", "mist", "rain", "dust", "sea_haze", "heat", "smoke", "storm"]
const SAMPLE_CITY_IDS: Array[String] = ["amsterdam"]
const CELL_SIZE: Vector2i = Vector2i(640, 360)

var _backdrop_view: Control
var _title: String = ""

func _ready() -> void:
	var validation_error: String = _validate_profiles()
	if not validation_error.is_empty():
		_fail(validation_error)
		return

	var backdrop_root: Node = BACKDROP_SCENE.instantiate()
	if backdrop_root == null:
		_fail("Die produktive Backdrop-Szene konnte nicht instanziiert werden.")
		return
	add_child(backdrop_root)
	await get_tree().process_frame
	_backdrop_view = backdrop_root.get_node_or_null("BackdropView") as Control
	if _backdrop_view == null:
		_fail("Die produktive Backdrop-Szene enthält keine BackdropView-Steuerung.")
		return

	var gallery_image: Image = Image.create(CELL_SIZE.x * 4, CELL_SIZE.y * 2, false, Image.FORMAT_RGBA8)
	for sample_index in range(SAMPLE_CITY_IDS.size()):
		var city_id: String = SAMPLE_CITY_IDS[sample_index]
		var world_index: int = _world_index_for(city_id)
		if world_index < 0:
			_fail("Die Bildprobe verweist auf eine unbekannte Stadt: %s." % city_id)
			return
		var atmosphere: Dictionary = CAMPAIGN_DATA.WORLD_ATMOSPHERE_PROFILES[city_id]
		var expected_kind: String = String(atmosphere["kind"])
		var expected_intensity: float = float(atmosphere["intensity"])
		_backdrop_view.call("configure_world", world_index)
		_title = "%s · %s · %.2f" % [String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[world_index]["city"]).to_upper(), expected_kind.to_upper(), expected_intensity]
		var active_profile: Dictionary = _backdrop_view.get("_world_profile")
		if String(active_profile.get("atmosphere", "")) != expected_kind:
			_fail("Die aktive Atmosphäre stimmt für %s nicht mit dem Profil überein." % city_id)
			return
		if not is_equal_approx(float(active_profile.get("atmosphere_intensity", -1.0)), expected_intensity):
			_fail("Die aktive Atmosphärenstärke stimmt für %s nicht mit dem Profil überein." % city_id)
			return
		_backdrop_view.set("_atmosphere_time_s", 2.75)
		_backdrop_view.queue_redraw()
		queue_redraw()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var frame_image: Image = get_viewport().get_texture().get_image()
		if frame_image == null or frame_image.is_empty():
			_fail("Godot hat für %s kein gerendertes Atmosphärenbild geliefert." % city_id)
			return
		frame_image.resize(CELL_SIZE.x, CELL_SIZE.y, Image.INTERPOLATE_BILINEAR)
		var destination: Vector2i = Vector2i((sample_index % 4) * CELL_SIZE.x, int(sample_index / 4) * CELL_SIZE.y)
		gallery_image.blit_rect(frame_image, Rect2i(Vector2i.ZERO, CELL_SIZE), destination)

	var output_directory: String = ProjectSettings.globalize_path("res://build/atmosphere_visual_review_0.5.40_%d" % Time.get_ticks_msec())
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(output_directory)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		_fail("Konnte den Atmosphären-Bildordner nicht anlegen: %s" % output_directory)
		return
	var output_path: String = output_directory.path_join("atmosphere_gallery.png")
	var image_error: Error = gallery_image.save_png(output_path)
	if image_error != OK:
		_fail("Konnte das Atmosphärenbild nicht speichern: %s" % output_path)
		return
	print("ATMOSPHERE_SYSTEM_OK worlds=%d profiles=%d supported_kinds=%d panels=%d size=%dx%d gallery=%s" % [CAMPAIGN_DATA.CAMPAIGN_WORLDS.size(), CAMPAIGN_DATA.WORLD_ATMOSPHERE_PROFILES.size(), SUPPORTED_KINDS.size(), SAMPLE_CITY_IDS.size(), gallery_image.get_width(), gallery_image.get_height(), output_path])
	get_tree().quit(0)

func _validate_profiles() -> String:
	var worlds: Array = CAMPAIGN_DATA.CAMPAIGN_WORLDS
	var profiles: Dictionary = CAMPAIGN_DATA.WORLD_ATMOSPHERE_PROFILES
	if worlds.size() != CAMPAIGN_DATA.PLAYABLE_WORLD_COUNT or worlds.is_empty():
		return "Die Amsterdam-Prüfung erwartet genau eine aktive Kampagnenstadt, gefunden: %d." % worlds.size()
	if profiles.size() != worlds.size():
		return "Jede Kampagnenstadt braucht genau ein Atmosphärenprofil."
	var world_ids: Dictionary = {}
	for world in worlds:
		var world_id: String = String(world.get("id", ""))
		if world_id.is_empty() or world_ids.has(world_id):
			return "Die Kampagnenstadt hat eine leere oder doppelte ID: %s." % world_id
		world_ids[world_id] = true
		if not profiles.has(world_id):
			return "Für %s fehlt ein Atmosphärenprofil." % world_id
		var atmosphere: Dictionary = profiles[world_id]
		var kind: String = String(atmosphere.get("kind", ""))
		var intensity: float = float(atmosphere.get("intensity", -1.0))
		if kind not in SUPPORTED_KINDS:
			return "Die Atmosphäre '%s' von %s wird nicht gezeichnet." % [kind, world_id]
		if intensity < 0.0 or intensity > 1.0:
			return "Die Atmosphärenstärke von %s liegt außerhalb 0–1." % world_id
	for profile_id in profiles.keys():
		if not world_ids.has(String(profile_id)):
			return "Das Atmosphärenprofil %s gehört zu keiner Kampagnenstadt." % String(profile_id)
	return ""

func _world_index_for(world_id: String) -> int:
	for world_index in range(CAMPAIGN_DATA.CAMPAIGN_WORLDS.size()):
		if String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[world_index].get("id", "")) == world_id:
			return world_index
	return -1

func _draw() -> void:
	if _title.is_empty():
		return
	draw_rect(Rect2(18.0, 16.0, 610.0, 54.0), Color(0.04, 0.07, 0.07, 0.86))
	draw_rect(Rect2(18.0, 16.0, 610.0, 54.0), Color8(190, 158, 96, 220), false, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 50.0), _title, HORIZONTAL_ALIGNMENT_LEFT, 580.0, 21, Color8(239, 219, 174))

func _fail(message: String) -> void:
	push_error("Atmosphären-Meilenstein fehlgeschlagen: %s" % message)
	get_tree().quit(2)
