extends Node2D
## Spatially matched swinging crane hazards.
const P := 36.0
var course: Node2D
var time := 0.0
var cranes: Array[Dictionary] = []
signal message(text: String)
signal hazard_hit

func _ready() -> void:
	course = get_parent()
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	reset()

func reset() -> void:
	time = 0.0
	cranes = [{"meter": 1412.0, "warned": false, "hit": false}, {"meter": 1660.0, "warned": false, "hit": false}]
	queue_redraw()

func update_action(delta: float, wagon: EscapeWagon, _brake: bool) -> void:
	if wagon == null or wagon.freeze:
		return
	time += delta
	for crane in cranes:
		var x: float = float(crane.meter) * P
		if not crane.warned and wagon.position.x > x - 75.0 * P and wagon.position.x < x:
			crane.warned = true
			message.emit("ACHTUNG KRANLAST · WARNBEREICH BEACHTEN · BREMSEN ODER DURCHFAHREN")
		if crane.warned and not crane.hit:
			var rect := load_rect(crane)
			if wagon.chassis_overlaps_world_rect(rect):
				crane.hit = true
				wagon.hit_weighted_obstacle(0.55, true)
				course.spawn_impact_particles(rect.get_center().x, rect.end.y, 1.0)
				hazard_hit.emit()
				message.emit("KRANLAST GETROFFEN · KOMBO UNTERBROCHEN")
	queue_redraw()

func pivot(crane: Dictionary) -> Vector2:
	var x: float = float(crane.meter) * P
	return Vector2(x + 92.0, course._quay_height_at(x) - 141.0)

func load_rect(crane: Dictionary) -> Rect2:
	var angle: float = sin(time * 1.65 + float(crane.meter)) * 0.95
	var center := pivot(crane) + Vector2(sin(angle), cos(angle)) * 105.0
	return Rect2(center - Vector2(24.0, 14.5), Vector2(48.0, 29.0))

func _draw() -> void:
	if course == null:
		return
	var bounds: Vector2 = course._visible_world_x_bounds(220.0)
	for crane in cranes:
		var x: float = float(crane.meter) * P
		if x < bounds.x or x > bounds.y:
			continue
		var rect := load_rect(crane)
		var top := pivot(crane)
		draw_line(top, rect.get_center(), Color8(37, 34, 27), 3.5, true)
		draw_line(top + Vector2(2, 0), rect.get_center() + Vector2(2, 0), Color8(172, 148, 97), 1.0, true)
		draw_texture_rect_region(course.AMSTERDAM_OBSTACLE_ATLAS, rect, Rect2(986.0, 55.0, 320.0, 194.0), Color8(215, 201, 176))
		for offset in [-14.0, 14.0]:
			draw_line(rect.position + Vector2(offset + 24.0, 2.0), top, Color8(108, 91, 59), 1.2, true)
		if crane.warned and not crane.hit:
			var ground: float = course._quay_height_at(x)
			var warn_color := Color8(246, 174, 54, 170 if sin(time * 7.0) > 0.0 else 65)
			draw_line(Vector2(x + 2.0, ground - 2.0), Vector2(x + 180.0, ground - 2.0), warn_color, 4.0, true)
			draw_circle(top + Vector2(-85.0, -14.0), 5.0, warn_color)

func active_hint(wagon: EscapeWagon) -> String:
	if wagon == null:
		return ""
	var meter: float = wagon.position.x / P
	for crane in cranes:
		if crane.warned and not crane.hit and meter >= float(crane.meter) - 75.0 and meter < float(crane.meter) + 8.0:
			return "ACHTUNG · SCHWINGENDE KRANLAST VORAUS"
	return ""

