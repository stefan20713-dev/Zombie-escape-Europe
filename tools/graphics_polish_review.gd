extends Node
var game:Node
var hud:Control
func _ready() -> void:
	call_deferred("_run")
func shot(label:String) -> void:
	hud.queue_redraw()
	for i in range(10):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://build/grafikpolitur-"+label+".png")
func click(id:String,touch:bool=false) -> void:
	for i in range(2):await get_tree().process_frame
	var matches:Array=hud.buttons.filter(func(b:Dictionary):return String(b.id)==id)
	assert(matches.size()==1,"Expected one button "+id)
	var point:Vector2=Rect2(matches[0].rect).get_center()
	for pressed in [true,false]:
		if touch:
			var e:=InputEventScreenTouch.new();e.position=point;e.index=42;e.pressed=pressed
			get_viewport().push_input(e,true)
		else:
			var e:=InputEventMouseButton.new();e.position=point;e.global_position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed
			get_viewport().push_input(e,true)
		await get_tree().process_frame
	for i in range(15):await get_tree().process_frame
func _run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.first_drive_tutorial_completed=true
	game.to_garage();hud=game.get_node("HUDLayer/HUD")
	game.money=500
	await shot("werkstatt")
	await click("journey_open")
	assert(hud._journey_open)
	assert(hud.buttons.all(func(b:Dictionary):return String(b.id) in ["map_open","journey_close"]),"Poster overlay must block purchases underneath.")
	await shot("reiseplan")
	await click("journey_close",true)
	assert(not hud._journey_open)
	for part in ["engine","tank","tires","armor","nitro","weapon"]:
		await click("garage_part:"+part)
		assert(hud._garage_selected_part==part)
		await shot(part)
	await click("garage_part:engine")
	var before:Dictionary=game.upgrades.duplicate(true)
	var coins:int=game.money
	var price:int=game.upgrade_price("engine")
	await click("upgrade")
	assert(game.money==coins-price and game.upgrade_level("engine")==int(before.get("engine",0))+1)
	for part in ["tank","tires","armor","nitro","weapon"]:assert(game.upgrade_level(part)==int(before.get(part,0)))
	await shot("gekauft")
	get_tree().root.size=Vector2i(1920,864)
	await shot("breit")
	await click("journey_open",true)
	await shot("reiseplan-breit")
	assert(hud.handle_system_back() and not hud._journey_open)
	game.world_completed_flags[0]=true
	game.backdrop.queue_redraw()
	hud.queue_redraw()
	await click("journey_open")
	await shot("reiseplan-abgeschlossen")
	await click("journey_close")
	for part in ["engine","tank","tires","armor","nitro","weapon"]:game.upgrades[part]=game.upgrade_limit(part)
	game.vehicle_upgrades["kombi"]=game.upgrades.duplicate(true)
	game.to_garage()
	await click("garage_part:nitro")
	var maximum_coins:int=game.money
	await click("upgrade")
	assert(game.money==maximum_coins)
	await shot("maximum")
	print("GRAPHICS_POLISH_UI_OK poster_mouse_touch=true purchase_once=true independent_parts=true wide=true")
	get_tree().quit()
