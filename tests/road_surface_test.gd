extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")

func _ready() -> void:
	call_deferred("_run_road_surface_smoke")

func _run_road_surface_smoke() -> void:
	var game: Node2D = MAIN_SCENE.instantiate() as Node2D
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var backdrop: Control = game.get_node("Backdrop/BackdropView") as Control
	var terrain: EscapeTerrain = game.get_node("Terrain") as EscapeTerrain
	assert(backdrop != null and terrain != null, "The production scene must connect both the backdrop and road renderer.")
	assert(backdrop.get("_sky_gradient_texture") != null, "The production backdrop must build its smooth regional sky texture.")
	var gradient_texture: Texture2D = backdrop.get("_sky_gradient_texture") as Texture2D
	assert(gradient_texture.get_width() == 1 and gradient_texture.get_height() == 256, "The sky gradient should stay a small vertical texture.")
	for world_index in range(CAMPAIGN_DATA.CAMPAIGN_WORLDS.size()):
		terrain.configure_world(world_index)
		backdrop.configure_world(world_index)
		var palette: Dictionary = terrain._world_surface_palette()
		for required_color in ["ground", "road_face", "road_shadow", "road_wear", "lane_marking", "road_edge", "verge"]:
			assert(palette.has(required_color) and palette[required_color] is Color, "World %d is missing road palette entry %s." % [world_index + 1, required_color])
		assert(Color(palette["road_face"]) != Color(palette["ground"]), "World %d must visibly distinguish pavement from surrounding terrain." % (world_index + 1))
		if world_index == 0:
			var opening_entity_kinds: Dictionary = {}
			for entity in terrain.entities:
				opening_entity_kinds[String(entity.get("kind", ""))] = true
			for required_kind in ["zombie", "fuel", "nitro", "repair", "coins", "setpiece", "story_log", "checkpoint"]:
				assert(opening_entity_kinds.has(required_kind), "The road render pass must preserve the opening-route %s gameplay entity." % required_kind)
	var rescue_length: float = 950.0
	terrain.configure_final_rescue(rescue_length)
	backdrop.configure_final_rescue(rescue_length)
	assert(backdrop.get("_sky_gradient_texture") != null, "The rescue route must rebuild its background gradient.")
	var rescue_ship_present: bool = false
	for entity in terrain.entities:
		if String(entity.get("kind", "")) == "rescue_ship":
			rescue_ship_present = true
			break
	assert(rescue_ship_present, "The final route must keep its rescue-ship landmark.")
	print("ROAD_SURFACE_SYSTEM_OK worlds=%d gradient=%dx%d rescue=true" % [CAMPAIGN_DATA.CAMPAIGN_WORLDS.size(), gradient_texture.get_width(), gradient_texture.get_height()])
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit()
