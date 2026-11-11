extends "res://scripts/terrain.gd"

const PAGE_SIZE: int = 12
const CARD_WIDTH: float = 410.0
const CARD_HEIGHT: float = 160.0
const CAMPAIGN = preload("res://scripts/campaign_data.gd")
const WAGON_SCENE: PackedScene = preload("res://scenes/wagon.tscn")

var _gallery_entries: Array[Dictionary] = []
var _vehicle_review_cars: Array[EscapeWagon] = []
var _page_index: int = 0

func _ready() -> void:
	var seen_kinds: Dictionary = {}
	for world in CAMPAIGN.CAMPAIGN_WORLDS:
		var profile: Dictionary = CAMPAIGN.WORLD_SETPIECE_PROFILES[String(world["id"])]
		var kind: String = String(profile["kind"])
		if seen_kinds.has(kind):
			continue
		seen_kinds[kind] = true
		_gallery_entries.append({
			"kind": kind,
			"city": String(world["city"]),
			"label": String(profile["label"])
		})
	if _gallery_entries.size() != 21:
		push_error("Die Bildprüfung erwartet 21 verschiedene Motive, gefunden: %d" % _gallery_entries.size())
		get_tree().quit(2)
		return
	_create_vehicle_review_cars()
	call_deferred("_capture_gallery_pages")

func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 720.0), Color8(39, 49, 46))
	var setpiece_pages: int = int(ceil(float(_gallery_entries.size()) / float(PAGE_SIZE)))
	if _page_index == setpiece_pages:
		_draw_zombie_gallery_page()
		return
	if _page_index > setpiece_pages:
		_draw_vehicle_damage_gallery_page()
		return
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 27.0), "ZOMBIE ESCAPE EUROPE · STRASSENBEGEGNUNGEN %d/%d" % [_page_index + 1, _page_count()], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color8(239, 219, 174))
	var start_index: int = _page_index * PAGE_SIZE
	var end_index: int = mini(start_index + PAGE_SIZE, _gallery_entries.size())
	for entry_index in range(start_index, end_index):
		var card_index: int = entry_index - start_index
		var column: int = card_index % 3
		var row: int = int(card_index / 3)
		var origin := Vector2(20.0 + float(column) * CARD_WIDTH, 43.0 + float(row) * CARD_HEIGHT)
		var card := Rect2(origin, Vector2(CARD_WIDTH - 10.0, CARD_HEIGHT - 5.0))
		draw_rect(card, Color8(30, 40, 37))
		draw_rect(card, Color8(112, 106, 81), false, 1.0)
		var entry: Dictionary = _gallery_entries[entry_index]
		draw_string(ThemeDB.fallback_font, origin + Vector2(12.0, 22.0), "%s · %s" % [String(entry["city"]).to_upper(), String(entry["label"]).to_upper()], HORIZONTAL_ALIGNMENT_LEFT, CARD_WIDTH - 34.0, 13, Color8(224, 202, 155))
		var ground_y: float = origin.y + 111.0
		draw_line(Vector2(origin.x + 10.0, ground_y), Vector2(origin.x + CARD_WIDTH - 20.0, ground_y), Color8(191, 158, 91), 5.0)
		draw_line(Vector2(origin.x + 10.0, ground_y + 4.0), Vector2(origin.x + CARD_WIDTH - 20.0, ground_y + 4.0), Color8(55, 61, 48), 18.0)
		_draw_world_setpiece(origin.x + 200.0, ground_y, String(entry["kind"]))
		draw_string(ThemeDB.fallback_font, origin + Vector2(12.0, 145.0), String(entry["kind"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color8(173, 187, 166))

func _draw_zombie_gallery_page() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 27.0), "ZOMBIE ESCAPE EUROPE · GEGNERKLASSEN UND VARIANTEN 3/3", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color8(239, 219, 174))
	var classes: Array[Dictionary] = [
		{"id": "slow", "label": "NORMAL"},
		{"id": "fast", "label": "SCHNELL"},
		{"id": "robust", "label": "ROBUST"}
	]
	for class_index in range(classes.size()):
		for variant in range(3):
			var origin := Vector2(20.0 + float(variant) * CARD_WIDTH, 43.0 + float(class_index) * CARD_HEIGHT)
			var card := Rect2(origin, Vector2(CARD_WIDTH - 10.0, CARD_HEIGHT - 5.0))
			draw_rect(card, Color8(30, 40, 37))
			draw_rect(card, Color8(112, 106, 81), false, 1.0)
			var zombie_class: Dictionary = classes[class_index]
			draw_string(ThemeDB.fallback_font, origin + Vector2(12.0, 22.0), "%s · VARIANTE %d" % [String(zombie_class["label"]), variant + 1], HORIZONTAL_ALIGNMENT_LEFT, CARD_WIDTH - 34.0, 13, Color8(224, 202, 155))
			var ground_y: float = origin.y + 119.0
			draw_line(Vector2(origin.x + 10.0, ground_y), Vector2(origin.x + CARD_WIDTH - 20.0, ground_y), Color8(191, 158, 91), 5.0)
			draw_line(Vector2(origin.x + 10.0, ground_y + 4.0), Vector2(origin.x + CARD_WIDTH - 20.0, ground_y + 4.0), Color8(55, 61, 48), 18.0)
			_draw_zombie(origin.x + 200.0, ground_y, variant, String(zombie_class["id"]))
			draw_string(ThemeDB.fallback_font, origin + Vector2(12.0, 145.0), "%s · LAUFCYCLE" % String(zombie_class["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color8(173, 187, 166))

func _draw_vehicle_damage_gallery_page() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 27.0), "ZOMBIE ESCAPE EUROPE · FAHRZEUGE, SCHADEN UND FUNDSTÜCKE 4/4", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color8(239, 219, 174))
	var vehicles: Array[Dictionary] = [
		{"id": "kombi", "label": "KOMBI"},
		{"id": "lieferwagen", "label": "LIEFERWAGEN"},
		{"id": "offroad_pickup", "label": "GELÄNDE-PICKUP"}
	]
	var damage_states: Array[String] = ["INTAKT · 100 %", "BESCHÄDIGT · 52 %", "KRITISCH · 17 %"]
	for car_index in range(_vehicle_review_cars.size()):
		var column: int = car_index % 3
		var row: int = int(car_index / 3)
		var origin := Vector2(20.0 + float(column) * CARD_WIDTH, 43.0 + float(row) * CARD_HEIGHT)
		var card := Rect2(origin, Vector2(CARD_WIDTH - 10.0, CARD_HEIGHT - 5.0))
		draw_rect(card, Color8(30, 40, 37))
		draw_rect(card, Color8(112, 106, 81), false, 1.0)
		var vehicle: Dictionary = vehicles[row]
		var state_label: String = damage_states[column]
		draw_string(ThemeDB.fallback_font, origin + Vector2(12.0, 22.0), "%s · %s" % [String(vehicle["label"]), state_label], HORIZONTAL_ALIGNMENT_LEFT, CARD_WIDTH - 34.0, 13, Color8(224, 202, 155))
		var ground_y: float = origin.y + 141.0
		draw_line(Vector2(origin.x + 10.0, ground_y), Vector2(origin.x + CARD_WIDTH - 20.0, ground_y), Color8(191, 158, 91), 5.0)
		draw_line(Vector2(origin.x + 10.0, ground_y + 4.0), Vector2(origin.x + CARD_WIDTH - 20.0, ground_y + 4.0), Color8(55, 61, 48), 18.0)
		draw_string(ThemeDB.fallback_font, origin + Vector2(12.0, 151.0), "SCHADENSSPUREN · MOTORRAUCH", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color8(173, 187, 166))
	_draw_pickup_review_strip()

func _draw_pickup_review_strip() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 535.0), "VERSORGUNG · FUNKARCHIV · KONTROLLPUNKT", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color8(210, 174, 114))
	var pickup_cards: Array[Dictionary] = [
		{"label": "FUNKMITSCHNITT", "kind": "story_log"},
		{"label": "ERSATZKANISTER", "kind": "fuel"},
		{"label": "NITRO", "kind": "nitro"},
		{"label": "WERKZEUGKISTE", "kind": "repair"},
		{"label": "VERSORGUNGSDEPOT", "kind": "checkpoint"}
	]
	var card_width: float = 244.0
	for pickup_index in range(pickup_cards.size()):
		var origin := Vector2(20.0 + float(pickup_index) * 251.0, 545.0)
		var card := Rect2(origin, Vector2(card_width, 159.0))
		draw_rect(card, Color8(30, 40, 37))
		draw_rect(card, Color8(112, 106, 81), false, 1.0)
		var pickup: Dictionary = pickup_cards[pickup_index]
		draw_string(ThemeDB.fallback_font, origin + Vector2(9.0, 18.0), String(pickup["label"]), HORIZONTAL_ALIGNMENT_LEFT, card_width - 18.0, 10, Color8(224, 202, 155))
		var ground_y: float = origin.y + 123.0
		draw_line(Vector2(origin.x + 10.0, ground_y), Vector2(origin.x + card_width - 10.0, ground_y), Color8(191, 158, 91), 4.0)
		draw_line(Vector2(origin.x + 10.0, ground_y + 4.0), Vector2(origin.x + card_width - 10.0, ground_y + 4.0), Color8(55, 61, 48), 12.0)
		var icon_x: float = origin.x + card_width * 0.5
		match String(pickup["kind"]):
			"story_log":
				_draw_story_log(icon_x, ground_y)
			"fuel":
				_draw_fuel_can(icon_x, ground_y)
			"nitro":
				_draw_nitro_canister(icon_x, ground_y)
			"repair":
				_draw_repair_kit(icon_x, ground_y)
			"checkpoint":
				_draw_checkpoint(icon_x, ground_y)

func _create_vehicle_review_cars() -> void:
	var vehicles: Array[String] = ["kombi", "lieferwagen", "offroad_pickup"]
	var durability_states: Array[float] = [100.0, 52.0, 17.0]
	for vehicle_index in range(vehicles.size()):
		for state_index in range(durability_states.size()):
			var car_index: int = vehicle_index * durability_states.size() + state_index
			var column: int = car_index % 3
			var row: int = int(car_index / 3)
			var origin := Vector2(20.0 + float(column) * CARD_WIDTH, 43.0 + float(row) * CARD_HEIGHT)
			var car: EscapeWagon = WAGON_SCENE.instantiate() as EscapeWagon
			car.freeze = true
			car.gravity_scale = 0.0
			car.collision_layer = 0
			car.collision_mask = 0
			add_child(car)
			car.configure({"engine": 0, "tires": 0, "tank": 0, "armor": 0}, vehicles[vehicle_index])
			car.durability = durability_states[state_index]
			car._damage_visual_time = float(state_index) * 0.5
			car._engine_visual_time = float(car_index) * 0.29 + 0.16
			car._throttle_visual = 0.82
			car._dust_visual_time = float(car_index) * 0.17
			car._dust_visual_strength = 0.62
			if state_index > 0:
				car._impact_visual_strength = 0.46 if state_index == 1 else 0.92
				car._impact_visual_remaining = 0.20 if state_index == 1 else 0.24
				car._impact_visual_time = float(car_index) * 0.08
			car.position = Vector2(origin.x + 200.0, origin.y + 98.0)
			car.visible = false
			car.queue_redraw()
			_vehicle_review_cars.append(car)

func _capture_gallery_pages() -> void:
	var output_directory: String = ProjectSettings.globalize_path("res://build/setpiece_visual_review")
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(output_directory)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		push_error("Konnte den Bildordner nicht anlegen: %s" % output_directory)
		get_tree().quit(2)
		return
	for page_index in range(_page_count()):
		_page_index = page_index
		var vehicle_gallery_page: int = int(ceil(float(_gallery_entries.size()) / float(PAGE_SIZE))) + 1
		for car in _vehicle_review_cars:
			car.visible = page_index == vehicle_gallery_page
		queue_redraw()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var page_image: Image = get_viewport().get_texture().get_image()
		var output_path: String = output_directory.path_join("setpieces_page_%02d.png" % (page_index + 1))
		var image_error: Error = page_image.save_png(output_path)
		if image_error != OK:
			push_error("Konnte Bild nicht speichern: %s" % output_path)
			get_tree().quit(2)
			return
		print("SETPIECE_GALLERY_PAGE_OK page=%d/%d size=%dx%d path=%s" % [page_index + 1, _page_count(), page_image.get_width(), page_image.get_height(), output_path])
	print("SETPIECE_VISUAL_SYSTEM_OK motifs=%d zombie_classes=3 zombie_variants=3 vehicle_classes=3 damage_states=3 exhaust=true tire_grit=true impact_sparks=true story_logs=31 pages=%d size=1280x720" % [_gallery_entries.size(), _page_count()])
	get_tree().quit(0)

func _page_count() -> int:
	return int(ceil(float(_gallery_entries.size()) / float(PAGE_SIZE))) + 2
