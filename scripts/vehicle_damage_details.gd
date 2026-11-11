extends Node2D
## Damage-only overlays and discarded sheet metal; never selects purchased parts.
const ATLAS = preload("res://assets/kombi_damage_details_v1.png")
const SOURCES: Array[Rect2] = [Rect2(116, 93, 580, 305), Rect2(943, 146, 718, 184), Rect2(128, 525, 550, 279), Rect2(795, 593, 905, 212)]
var wagon: EscapeWagon
var previous := 0
var previous_health := 100.0
var rear_was_torn := false
var contact_marks: Array[Vector2] = []
var debris: Array[Dictionary] = []

func _ready() -> void:
	wagon = get_parent()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	previous = wagon.visual_damage_stage()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform float metal = 0.0; varying vec4 vertex_color; void vertex(){ vertex_color = COLOR; } void fragment(){ vec4 c = texture(TEXTURE, UV) * vertex_color; float grey = dot(c.rgb, vec3(0.299, 0.587, 0.114)); c.rgb = mix(c.rgb, vec3(grey * 0.92, grey, grey * 0.94), metal); COLOR = c; }"
	var surface := ShaderMaterial.new()
	surface.shader = shader
	material = surface

func _process(delta: float) -> void:
	if wagon == null or wagon.vehicle_id != "kombi":
		return
	(material as ShaderMaterial).set_shader_parameter("metal", 1.0 if wagon.armor_level >= 3 else 0.0)
	var stage: int = wagon.visual_damage_stage()
	var torn := wagon.kombi_rear_torn()
	if torn and not rear_was_torn and not wagon.freeze:
		var texture: Texture2D = wagon.kombi_armor_body_texture()
		if texture == null:
			texture = wagon.KOMBI_BODY_TEXTURE
		debris.append({"position": wagon.to_global(Vector2(-94, 5)), "velocity": wagon.linear_velocity * 0.44 + Vector2(-82, -100), "age": 0.0, "angle": wagon.rotation, "spin": -3.1, "tail_texture": texture})
	rear_was_torn = torn
	if wagon.durability > previous_health:
		contact_marks.clear()
	if previous_health - wagon.durability > 0.3 and not wagon.freeze:
		var point: Vector2 = wagon.last_damage_local
		if contact_marks.all(func(mark: Vector2): return mark.distance_to(point) > 8.0):
			contact_marks.append(point)
			if contact_marks.size() > 5:
				contact_marks.pop_front()
	previous_health = wagon.durability
	if stage < previous:
		debris.clear()
	if stage > previous and not wagon.freeze:
		for threshold in range(previous + 1, stage + 1):
			if threshold in [2, 3, 4, 5]:
				var hood: bool = threshold == 4
				debris.append({"position": wagon.to_global(Vector2(78, 1) if hood else Vector2(89, 16)), "velocity": wagon.linear_velocity * 0.4 + Vector2(-65, -80.0 - float(threshold) * 12.0), "age": 0.0, "angle": wagon.rotation, "spin": -2.4, "source": 3 if hood else 0, "width": 45.0 if hood else 15.0})
	previous = stage
	if not get_tree().paused:
		for i in range(debris.size() - 1, -1, -1):
			var piece: Dictionary = debris[i]
			piece.age += delta
			piece.velocity += Vector2(0, 320) * delta
			piece.position += piece.velocity * delta
			if piece.has("tail_texture") and is_instance_valid(wagon._ground_surface):
				var ground := float(wagon._ground_surface.height_at(piece.position.x)) - 12.0
				if piece.position.y > ground and piece.velocity.y > 0.0:
					piece.position.y = ground
					piece.velocity *= Vector2(0.58, -0.30)
					piece.spin *= 0.58
			piece.angle += float(piece.spin) * delta
			if float(piece.age) > 2.4:
				debris.remove_at(i)
	queue_redraw()

func _decal(index: int, center: Vector2, width: float, alpha: float = 1.0) -> void:
	var source: Rect2 = SOURCES[index]
	var size := Vector2(width, width * source.size.y / source.size.x)
	draw_texture_rect_region(ATLAS, Rect2(center - size * 0.5, size), source, Color(1, 1, 1, alpha))

func _draw() -> void:
	if wagon == null or wagon.vehicle_id != "kombi":
		return
	var stage: int = wagon.visual_damage_stage()
	if stage == 0:
		return
	# Attached paint remains the original body texture; only glass and fine contact creases overlay it.
	if stage >= 3:
		_decal(2, Vector2(15, -10), 27.0)
	if stage >= 4:
		_decal(2, Vector2(-30, -12), 31.0)
	for mark in contact_marks:
		var crease := PackedVector2Array([mark + Vector2(-6, 1), mark + Vector2(-2, -1), mark + Vector2(3, 0), mark + Vector2(7, -2)])
		draw_polyline(crease, Color8(67, 47, 34, 150), 0.8, true)
	for piece in debris:
		var local_position: Vector2 = to_local(piece.position)
		draw_set_transform(local_position, float(piece.angle) - wagon.rotation)
		var alpha := 1.0 - smoothstep(1.6, 2.4, float(piece.age))
		if piece.has("tail_texture"):
			var texture: Texture2D = piece.tail_texture
			var source := Rect2(Vector2(0.0, texture.get_height() * wagon.KOMBI_REAR_TEAR_TOP_V), texture.get_size() * Vector2(wagon.KOMBI_REAR_TEAR_U, 1.0 - wagon.KOMBI_REAR_TEAR_TOP_V))
			var size := source.size * (wagon.KOMBI_BODY_DRAW_WIDTH / texture.get_width())
			draw_texture_rect_region(texture, Rect2(-size * 0.5, size), source, Color(0.85, 0.80, 0.74, alpha))
		else:
			_decal(int(piece.source), Vector2.ZERO, float(piece.width), alpha)
	draw_set_transform(Vector2.ZERO)


