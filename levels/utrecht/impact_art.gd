extends RefCounted
## Utrecht-only dust and breakaway fragments, attached to confirmed world contacts.
const WOOD := [Color8(106, 67, 38), Color8(170, 117, 66), Color8(205, 153, 92)]
const STEEL := [Color8(71, 79, 77), Color8(115, 125, 118), Color8(153, 104, 72)]

const CONCRETE := [Color8(83, 81, 71), Color8(132, 125, 108), Color8(171, 165, 148)]

var _fragments: Array[Dictionary] = []
var _dust: Array[Dictionary] = []
var _random := RandomNumberGenerator.new()
var _soft := _make_soft_texture()

func _make_soft_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	return texture

func reset() -> void:
	_fragments.clear()
	_dust.clear()
	_random.seed = 94216

func burst(at: Vector2, speed: float, weight: float, material: String) -> void:
	var palette := STEEL if material in ["scrap_wall", "oil_drums", "road_sign"] else WOOD
	if material in ["drain_pipes", "concrete"]:
		palette = CONCRETE
	var strength := clampf(speed / 30.0, 0.25, 1.25)
	for index in range(8 + roundi(weight * 12.0)):
		var sheet := palette == STEEL and index % 3 != 0
		var size := Vector2(_random.randf_range(5, 15), _random.randf_range(1.5, 3.8))
		if sheet:
			size.y *= 2.5
		_fragments.append({
			"position": at + Vector2(_random.randf_range(-20, 20), _random.randf_range(-30, 8)),
			"velocity": Vector2(_random.randf_range(60, 330) * strength, _random.randf_range(-220, -65)),
			"angle": _random.randf_range(-1.0, 1.0), "spin": _random.randf_range(-8, 8),
			"age": 0.0, "size": size, "color": palette[index % palette.size()], "sheet": sheet,
		})
	puff(at + Vector2(0, 12), strength, 7)

func puff(at: Vector2, strength: float, count: int) -> void:
	for index in range(count):
		_dust.append({
			"position": at + Vector2(_random.randf_range(-19, 19), _random.randf_range(-8, 3)),
			"velocity": Vector2(_random.randf_range(-42, 92), _random.randf_range(-43, -19)),
			"age": 0.0, "life": _random.randf_range(0.52, 1.08),
			"radius": _random.randf_range(9, 22) * (0.8 + strength),
		})

func tick(delta: float, floor_at: Callable) -> void:
	for index in range(_dust.size() - 1, -1, -1):
		var cloud := _dust[index]
		cloud.age += delta
		if cloud.age >= cloud.life:
			_dust.remove_at(index)
		else:
			cloud.position += cloud.velocity * delta
			cloud.velocity *= exp(-1.5 * delta)
	for index in range(_fragments.size() - 1, -1, -1):
		var fragment := _fragments[index]
		fragment.age += delta
		if fragment.age >= 2.1:
			_fragments.remove_at(index)
			continue
		fragment.velocity.y += 380.0 * delta
		fragment.position += fragment.velocity * delta
		var floor_y := float(floor_at.call(fragment.position.x)) - 2.0
		if fragment.position.y >= floor_y and fragment.velocity.y > 0.0:
			fragment.position.y = floor_y
			fragment.velocity.y *= -0.27
			fragment.velocity.x *= 0.65
			fragment.spin *= 0.5
		fragment.angle += fragment.spin * delta

func shadow(target: Node2D, at: Vector2, height: float) -> void:
	var fade := 1.0 - smoothstep(35.0, 240.0, height)
	var size := Vector2(192, 18) * lerpf(1.4, 1.0, fade)
	target.draw_texture_rect(_soft, Rect2(at - size * 0.5, size), false, Color(0.12, 0.10, 0.08, 0.56 * fade))

func render(target: Node2D, view: Vector2) -> void:
	for cloud in _dust:
		if cloud.position.x < view.x or cloud.position.x > view.y:
			continue
		var t := float(cloud.age) / float(cloud.life)
		var radius := float(cloud.radius) * lerpf(0.55, 1.75, t)
		var size := Vector2(radius * 2.8, radius * 1.55)
		target.draw_texture_rect(_soft, Rect2(cloud.position - size * 0.5, size), false, Color(0.70, 0.56, 0.39, (1.0 - t) * 0.42))
	for fragment in _fragments:
		if fragment.position.x < view.x or fragment.position.x > view.y:
			continue
		var size: Vector2 = fragment.size
		var ink: Color = fragment.color
		ink.a = 1.0 - smoothstep(1.25, 2.1, fragment.age)
		target.draw_set_transform(fragment.position, fragment.angle)
		target.draw_colored_polygon(PackedVector2Array([Vector2(-size.x, -size.y), Vector2(size.x * 0.65, -size.y * 0.7), Vector2(size.x, size.y * 0.35), Vector2(-size.x * 0.7, size.y)]), ink)
		target.draw_line(Vector2(-size.x * 0.8, -size.y * 0.7), Vector2(size.x * 0.6, -size.y * 0.45), ink.lightened(0.32), 1.0, true)
		if fragment.sheet:
			target.draw_line(Vector2(-size.x * 0.72, size.y * 0.1), Vector2(size.x * 0.75, size.y * 0.28), ink.darkened(0.38), 1.2, true)
	target.draw_set_transform(Vector2.ZERO)

