extends Node2D
var wagon: EscapeWagon
var active := false
func height_at(_x: float) -> float:
	return 500.0
func slope_at(_x: float) -> float:
	return 0.0
func _ready() -> void:
	call_deferred("_run")
func _physics_process(delta: float) -> void:
	if active:
		wagon.simulate(delta, false, false, false, 0.0, 0.0)
func _run() -> void:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(4000, 10)
	collision.shape = box
	body.position.y = 505.0
	body.add_child(collision)
	add_child(body)
	wagon = load("res://scenes/wagon.tscn").instantiate()
	add_child(wagon)
	await get_tree().physics_frame
	for tires in range(4):
		active = false
		wagon.freeze = true
		await get_tree().physics_frame
		wagon.configure({"tires": tires}, "kombi")
		wagon.reset_at(0.0, self)
		await get_tree().physics_frame
		wagon.freeze = false
		active = true
		for frame in range(180):
			await get_tree().physics_frame
		var visible_bottom_row: float = [1128.0, 1218.0, 1220.0, 1224.0][tires]
		var sprite_size: float = wagon.wheel_visual_radius() * (2.15 if tires == 0 else 2.0)
		var actual_tread_bottom: float = 25.0 + float(tires) * 1.15 + sprite_size * (visible_bottom_row - 627.0) / 1254.0
		var gap: float = 500.0 - wagon.position.y - actual_tread_bottom
		print("WHEEL_CONTACT tires=",tires," gap_px=",gap," angle=",wagon.rotation)
		assert(absf(gap) < 1.5, "Visible tires must reach the actual ground.")
	print("WHEEL_CONTACT_OK levels=4")
	get_tree().quit()

