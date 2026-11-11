extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const AMSTERDAM_OPENING_SETPIECE_METER: float = 531.0
const EXPECTED_KINDS: Array[String] = ["canal_debris"]

func _ready() -> void:
	call_deferred("_run_campaign_setpiece_smoke")

func _run_campaign_setpiece_smoke() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	if not _expect(CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() == 1 and String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[0].get("id", "")) == "amsterdam", "Amsterdam must be the only active campaign city."):
		return
	if not _expect(CAMPAIGN_DATA.WORLD_SETPIECE_PROFILES.size() == CAMPAIGN_DATA.CAMPAIGN_WORLDS.size(), "Every active route needs exactly one authored profile."):
		return
	var seen_city_ids: Dictionary = {}
	var seen_visual_kinds: Dictionary = {}
	for world_index in range(CAMPAIGN_DATA.CAMPAIGN_WORLDS.size()):
		var world: Dictionary = CAMPAIGN_DATA.CAMPAIGN_WORLDS[world_index]
		var world_id: String = String(world.get("id", ""))
		if not _expect(not world_id.is_empty() and not seen_city_ids.has(world_id), "Campaign city IDs must be present and unique."):
			return
		seen_city_ids[world_id] = true
		if not _expect(CAMPAIGN_DATA.WORLD_SETPIECE_PROFILES.has(world_id), "%s needs a route encounter profile." % world_id):
			return
		var profile: Dictionary = CAMPAIGN_DATA.WORLD_SETPIECE_PROFILES[world_id]
		var kind: String = String(profile.get("kind", ""))
		if not _expect(EXPECTED_KINDS.has(kind), "%s uses an unregistered visual setpiece kind: %s" % [world_id, kind]):
			return
		if not _expect(not String(profile.get("label", "")).is_empty(), "%s needs a warning label." % world_id):
			return
		if not _expect(float(profile.get("speed_retention", 0.0)) >= 0.55 and float(profile.get("speed_retention", 1.0)) <= 1.0, "%s has an unsafe speed-retention value." % world_id):
			return
		if not _expect(float(profile.get("damage", -1.0)) >= 0.0 and float(profile.get("damage", 101.0)) <= 20.0, "%s has invalid hazard damage." % world_id):
			return
		seen_visual_kinds[kind] = true
		game.selected_world_index = world_index
		game._configure_selected_world()
		var setpieces: Array[Dictionary] = []
		for entity in game.terrain.entities:
			if String(entity.get("kind", "")) == "setpiece":
				setpieces.append(entity)
		if not _expect(setpieces.size() == 1, "%s must keep exactly one setpiece so clean-hazard challenges stay readable." % world_id):
			return
		var setpiece: Dictionary = setpieces[0]
		if not _expect(String(setpiece.get("hazard_kind", "")) == kind, "%s runtime visual kind must match its authored data." % world_id):
			return
		if not _expect(String(setpiece.get("hazard_label", "")) == String(profile["label"]), "%s HUD warning must match its authored label." % world_id):
			return
		var expected_meter: float = AMSTERDAM_OPENING_SETPIECE_METER
		if not _expect(absf(float(setpiece["meter"]) - expected_meter) < 0.1, "%s setpiece route position was %.1f m; expected %.1f m." % [world_id, float(setpiece["meter"]), expected_meter]):
			return
		var warning: Dictionary = game.next_road_hazard_warning(expected_meter - 120.0, 140.0)
		if not _expect(not warning.is_empty() and String(warning.get("hazard_label", "")) == String(profile["label"]), "%s warning preview must announce the upcoming encounter." % world_id):
			return
		if not _expect(absf(float(warning.get("distance_m", 0.0)) - 120.0) < 0.1, "%s warning preview must keep the correct approach distance." % world_id):
			return
	if not _expect(seen_visual_kinds.size() == 1, "The active Amsterdam route should use its authored canal encounter."):
		return
	print("CAMPAIGN_SETPIECE_SYSTEM_OK worlds=%d authored_kinds=%d one_encounter_per_world=true warning_integration=true" % [seen_city_ids.size(), seen_visual_kinds.size()])
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("CAMPAIGN_SETPIECE_ASSERTION: " + message)
	get_tree().quit(1)
	return false
