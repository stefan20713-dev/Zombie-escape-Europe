extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")

func _ready() -> void:
	call_deferred("_run_campaign_map_layout_test")

func _run_campaign_map_layout_test() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.screen_state = "MAP"
	var hud: Variant = game.get_node("HUDLayer/HUD")
	hud.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame

	var safe_rect: Rect2 = hud._safe_bounds(hud.get_size())
	var map_rect := Rect2(safe_rect.position.x + 18.0, safe_rect.position.y + 60.0, safe_rect.size.x * 0.42, safe_rect.size.y - 78.0)
	var map_area := Rect2(map_rect.position.x + 20.0, map_rect.position.y + 40.0, map_rect.size.x - 40.0, map_rect.size.y - 72.0)
	assert(CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() == 1, "The campaign map should contain only the active Amsterdam route.")
	var amsterdam_position: Vector2 = hud._campaign_map_point(Vector2(CAMPAIGN_DATA.CAMPAIGN_WORLDS[0]["map"]), map_area)
	assert(map_area.has_point(amsterdam_position), "The Amsterdam marker should remain inside the visible map area.")
	assert(game.is_world_unlocked(0) and not game.is_world_unlocked(1), "Only Amsterdam should be selectable while later routes are not authored.")
	print("CAMPAIGN_MAP_LAYOUT_OK worlds=1 amsterdam_marker_visible=true")
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)
