extends Node
func _ready() -> void:
	call_deferred("_run")
func shot(label: String) -> void:
	for frame in range(6):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/werkstatt-review-"+label+".png")
func _run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.first_drive_tutorial_completed=true
	game.to_garage()
	await shot("normal")
	var hud=game.get_node("HUDLayer/HUD")
	hud._garage_selected_part="nitro";hud.queue_redraw()
	await shot("nitro")
	get_tree().root.size=Vector2i(1920,864)
	hud.queue_redraw()
	await shot("breit")
	print("WORKSHOP_REVIEW_OK normal_nitro_wide=true")
	get_tree().quit()
