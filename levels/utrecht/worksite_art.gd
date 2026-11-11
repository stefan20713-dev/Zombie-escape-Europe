extends RefCounted

const ART_DIR := "res://levels/utrecht/art/"
const SCALE_M := DrivingTestCourse.PIXELS_PER_METER
const PROPS := {
	"work_fence": [Rect2(60, 121, 662, 352), 44.0],
	"drain_pipes": [Rect2(824, 129, 656, 349), 46.0],
	"scrap_wall": [Rect2(60, 636, 650, 318), 66.0],
	"motor_crate": [Rect2(833, 651, 630, 303), 45.0],
}

const DEPOT_PROPS := {
	"load_chock": [Rect2(54, 106, 534, 416), 49.0],
	"pallet_stack": [Rect2(54, 106, 534, 416), 55.0],
	"oil_drums": [Rect2(696, 86, 484, 433), 57.0],
	"road_sign": [Rect2(38, 745, 556, 385), 49.0],
	"cable_spool": [Rect2(708, 669, 481, 478), 56.0],
}
const FIRE_SOURCE := Rect2(35, 98, 1198, 982)
const BREACH_BARREL := Rect2(179, 88, 527, 294)
const BREACH_BARREL_WRECK := Rect2(1052, 69, 575, 322)
const BREACH_FENCE := Rect2(107, 512, 671, 315)
const BREACH_FENCE_WRECK := Rect2(985, 636, 679, 189)
var _blast_fire := _load_texture("res://assets/effects/collapse_fire.png")
const STRUCT_BEARING := Rect2(54, 113, 554, 432)
const STRUCT_JOINT := Rect2(701, 49, 563, 494)
const STRUCT_PIPE := Rect2(79, 631, 503, 530)
const STRUCT_RUBBLE := Rect2(669, 789, 594, 246)
var _structural_details := _load_art("structural_details")
var _breach_props := _load_art("breach_props")
var _skyline := _load_art("skyline")
var _skyline_canalside := _load_art("skyline_canalside")
var _challenge_props := _load_art("challenge_props")
var _foreground := _load_art("quay_foreground")
var _wall := _load_art("retaining_wall")
var _depot := _load_art("maintenance_depot")
var _scrapyard := _load_art("scrapyard")
var _depot_props := _load_art("depot_props")
var _props := _load_art("props")
var _yard := _load_art("yard")
var _materials := _load_materials("materials")
var _girder_materials := _load_materials("girder_materials")
var _girder_yard := _load_art("girder_yard")
var _surface_meshes: Array[ArrayMesh] = []

func _load_art(name: String) -> Texture2D:
	return _load_texture(ART_DIR + name + ".png")

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path, "Texture2D"):
		return load(path) as Texture2D
	var source := Image.load_from_file(ProjectSettings.globalize_path(path))
	source.generate_mipmaps()
	return ImageTexture.create_from_image(source)

func _load_materials(atlas_name: String) -> Array[ImageTexture]:
	var atlas := _load_art(atlas_name).get_image()
	var result: Array[ImageTexture] = []
	var band := floori(atlas.get_height() / 4.0)
	for index in range(4):
		var image := atlas.get_region(Rect2i(0, index * band + 5, atlas.get_width(), band - 10))
		image.generate_mipmaps()
		result.append(ImageTexture.create_from_image(image))
	return result

func has_prop(kind: String) -> bool:
	return PROPS.has(kind) or DEPOT_PROPS.has(kind)

func prop_size(kind: String) -> Vector2:
	if kind == "oil_drums":
		return Vector2(57.0, 49.0)
	if kind == "work_fence":
		return Vector2(94.0, 44.0)
	var sprite: Array = DEPOT_PROPS[kind] if DEPOT_PROPS.has(kind) else PROPS[kind]
	var source: Rect2 = sprite[0]
	return source.size * (float(sprite[1]) / source.size.y)

func draw_prop(target: Node2D, kind: String, base: Vector2) -> void:
	if kind == "oil_drums":
		var variant := floori(base.x / SCALE_M) % 3
		for index in range(2):
			var length := 43.0 + float((index + variant) % 3) * 2.0
			var size := Vector2(length, length * BREACH_BARREL.size.y / BREACH_BARREL.size.x)
			var foot := base + Vector2(-13.0 if index == 0 else 13.0, 0.0)
			target.draw_set_transform(foot + Vector2(0.0, -length * 0.5), -PI * 0.5)
			target.draw_texture_rect_region(_breach_props, Rect2(-size * 0.5, size), BREACH_BARREL, Color8(189, 172, 151) if index == 0 else Color.WHITE)
		target.draw_set_transform(Vector2.ZERO)
		return
	if kind == "work_fence":
		var fence := prop_size(kind)
		target.draw_texture_rect_region(_breach_props, Rect2(base - Vector2(fence.x * 0.5, fence.y), fence), BREACH_FENCE)
		return
	var size := prop_size(kind)
	var depot := DEPOT_PROPS.has(kind)
	var source: Rect2 = DEPOT_PROPS[kind][0] if depot else PROPS[kind][0]
	target.draw_texture_rect_region(_depot_props if depot else _props, Rect2(base - Vector2(size.x * 0.5, size.y), size), source)

func draw_breach_wreck(target: Node2D, kind: String, base: Vector2) -> void:
	var source := BREACH_BARREL_WRECK if kind == "oil_drums" else BREACH_FENCE_WRECK
	var width := 52.0 if kind == "oil_drums" else 89.0
	var size := Vector2(width, width * source.size.y / source.size.x)
	var tint := Color8(156, 141, 126) if kind == "oil_drums" else Color8(205, 187, 152)
	target.draw_texture_rect_region(_breach_props, Rect2(base - Vector2(size.x * 0.5, size.y - 7.0), size), source, tint)


func draw_skyline(target: Node2D, view: Vector2, camera: Camera2D) -> void:
	var center := camera.get_screen_center_position() if camera != null else Vector2.ZERO
	var y := 112.0 + (center.y - 355.0) * 0.62
	var height := 405.0
	var width := height * _skyline.get_width() / _skyline.get_height()
	var shift := center.x * 0.962 - 370.0
	target.draw_rect(Rect2(view.x, y - 600.0, view.y - view.x, 600.0), Color8(38, 168, 224))
	var water_x := floorf((view.x - shift) / _materials[3].get_width()) * _materials[3].get_width() + shift
	target.draw_texture_rect(_materials[3], Rect2(water_x, y + height - 1.0, view.y - water_x, 950.0), true, Color(0.81, 0.91, 0.90))
	var overlap := 34.0
	var step := width - overlap
	var first := floori((view.x - shift - width) / step) + 1
	var last := ceili((view.y - shift) / step)
	for index in range(first, last):
		var x := shift + float(index) * step
		var skyline := _skyline if posmod(index, 2) == 0 else _skyline_canalside
		var blend := overlap / width
		var seam := PackedVector2Array([Vector2(x, y), Vector2(x + overlap, y), Vector2(x + overlap, y + height), Vector2(x, y + height)])
		var uv := PackedVector2Array([Vector2.ZERO, Vector2(blend, 0.0), Vector2(blend, 1.0), Vector2(0.0, 1.0)])
		target.draw_polygon(seam, PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)]), uv, skyline)
		var texture_size := skyline.get_size()
		var region := Rect2(texture_size.x * blend, 0.0, texture_size.x * (1.0 - blend), texture_size.y)
		target.draw_texture_rect_region(skyline, Rect2(x + overlap, y, step, height), region)
	var sky_band := PackedVector2Array([Vector2(view.x, y - 1.0), Vector2(view.y, y - 1.0), Vector2(view.y, y + 32.0), Vector2(view.x, y + 32.0)])
	var sky := Color8(38, 168, 224)
	var clear_sky := Color(sky, 0.0)
	target.draw_polygon(sky_band, PackedColorArray([sky, sky, clear_sky, clear_sky]))
	for row in range(9):
		var line_y := maxf(730.0, y + height) + float(row) * 15.0
		var phase := float(Time.get_ticks_msec() % 16000) * 0.012
		for column in range(floori(view.x / 190.0) - 1, ceili(view.y / 190.0) + 1):
			var x := float(column) * 190.0 + fposmod(phase + float(row * 61), 190.0)
			var glint := Color(0.51, 0.73, 0.75, 0.12 + 0.07 * sin(float(column + row * 4)))
			target.draw_line(Vector2(x, line_y), Vector2(x + 66.0 + float(row % 3) * 14.0, line_y), glint, 2.0)

func draw_yard(target: Node2D, x: float, ground: float, view: Vector2, depot: bool = false) -> void:
	var source := Rect2(0, 0, 2172, 700) if not depot else Rect2(1260, 0, 912, 700)
	var height := 210.0 if not depot else 187.0
	var size := source.size * (height / source.size.y)
	if x + size.x * 0.5 < view.x or x - size.x * 0.5 > view.y:
		return
	var base := Vector2(x - size.x * 0.5, ground - 8.0)
	target.draw_texture_rect_region(_yard, Rect2(base - Vector2(0, size.y), size), source)
	target.draw_texture_rect(_materials[1], Rect2(base, Vector2(size.x, 19.0)), true, Color(0.61, 0.60, 0.51))
	target.draw_line(base, base + Vector2(size.x, 0), Color8(131, 119, 89), 2.0)

func draw_quay(target, view: Vector2) -> void:
	var left := maxf(view.x, 0.0)
	var right := minf(view.y, target.road_end_m() * SCALE_M)
	var points := _site_edge(view, 0.0, target.road_end_m(), target._lower_height)
	if points.size() < 2:
		return
	var wall := PackedVector2Array()
	for point in points:
		wall.append(point + Vector2(0, 31))
	wall.append(Vector2(right, 735.0))
	wall.append(Vector2(left, 735.0))
	var uvs := PackedVector2Array()
	var wall_height := 435.0
	var wall_width := wall_height * _wall.get_width() / _wall.get_height()
	for point in wall:
		uvs.append(Vector2(point.x / wall_width, (point.y - 300.0) / wall_height))
	target.draw_colored_polygon(wall, Color.WHITE, uvs, _wall)
	_draw_strip(target, points, 0.0, 32.0, Color.WHITE, _materials[0])
	_draw_strip(target, points, 24.0, 32.0, Color(0.95, 0.91, 0.79), _girder_materials[3])
	_draw_strip(target, points, 30.0, 32.0, Color8(78, 70, 57))
	_draw_strip(target, points, 0.0, 2.0, Color8(129, 129, 115))
	for index in range(ceili(left / 42.0), floori(right / 42.0)):
		var x := float(index) * 42.0
		var meter := x / SCALE_M
		var y: float = target._lower_height(meter)
		target.draw_line(Vector2(x, y + 24), Vector2(x + 1.0, y + 30), Color8(82, 74, 60, 180), 1.2, true)
		if (meter > 213.0 and meter < 252.0 or meter > 1260.0 and meter < 1310.0) and index % 4 <= 1:
			var fracture := PackedVector2Array([Vector2(x + 4, y + 6), Vector2(x + 11, y + 11), Vector2(x + 9, y + 14), Vector2(x + 20, y + 19)])
			target.draw_polyline(fracture, Color8(45, 43, 36, 185), 1.25, true)
			target.draw_line(fracture[2], fracture[2] + Vector2(-6, 5), Color8(59, 56, 48, 160), 1.0, true)
		if meter > target.BRANCH_START_M + 3.0 and meter < target.BRANCH_END_M - 3.0:
			var end_y: float = target._lower_height((x + 42.0) / SCALE_M)
			var color := Color.WHITE if index % 2 == 0 else Color(0.86, 0.90, 0.88)
			_draw_strip(target, PackedVector2Array([Vector2(x, y), Vector2(x + 42, end_y)]), 0.0, 23.0, color, _materials[1])
			target.draw_line(Vector2(x, y + 1), Vector2(x, y + 22), Color8(47, 56, 56), 2.0)
			for bolt in [4.0, 19.0]:
				target.draw_circle(Vector2(x + 6.0, y + bolt), 1.6, Color8(193, 188, 163), true, -1.0, true)
		elif meter >= 837.5 and meter <= 874.5:
			var end_y: float = target._lower_height((x + 16.0) / SCALE_M)
			target.draw_line(Vector2(x, y + 20.0), Vector2(x + 16.0, end_y + 4.0), Color8(165, 127, 57, 192), 3.0, true)
		elif index % 3 == 0:
			var end_y: float = target._lower_height((x + 23.0) / SCALE_M)
			target.draw_line(Vector2(x, y + 12), Vector2(x + 23.0, end_y + 12), Color8(187, 181, 146, 180), 2.2, true)
		if meter >= 1162.0 and meter < 1250.0 and index % 5 < 2:
			target.draw_polyline(PackedVector2Array([Vector2(x, y + 3), Vector2(x + 5, y + 8), Vector2(x + 15, y + 10), Vector2(x + 18, y + 22)]), Color8(32, 37, 35), 1.5, true)

func draw_bridge(target, view: Vector2) -> void:
	var left := maxf(view.x, target.BRANCH_START_M * SCALE_M)
	var right := minf(view.y, target.BRANCH_END_M * SCALE_M)
	if right <= left:
		return
	for index in range(ceili(left / 72.0), floori(right / 72.0)):
		var x := float(index) * 72.0
		var y: float = target._upper_height(x / SCALE_M)
		var base: float = target._lower_height(x / SCALE_M)
		if base - y > 24.0:
			var foot := Vector2(x, base + 24.0)
			target.draw_line(Vector2(x, y + 10.0), foot, Color8(58, 61, 57), 12.0)
			target.draw_line(Vector2(x - 2.0, y + 10.0), foot - Vector2(2, 0), Color8(146, 121, 86), 3.0)
			target.draw_line(foot - Vector2(15, 0), foot + Vector2(15, 0), Color8(80, 80, 71), 6.0)
			var brace_x := minf(x + 72.0, right)
			var brace_y: float = target._upper_height(brace_x / SCALE_M)
			target.draw_line(Vector2(x, base + 9.0), Vector2(brace_x, brace_y + 11.0), Color8(75, 75, 63), 5.0)
	var deck := _site_edge(view, target.BRANCH_START_M, target.BRANCH_END_M, target._upper_height)
	if deck.size() < 2:
		return
	_draw_strip(target, deck, 0.0, 17.0, Color8(61, 61, 55))
	_draw_strip(target, deck, 0.0, 10.0, Color.WHITE, _materials[2])
	_draw_strip(target, deck, 0.0, 2.5, Color8(224, 180, 106))
	for index in range(ceili(left / 22.0), floori(right / 22.0)):
		var x := float(index) * 22.0
		var y: float = target._upper_height(x / SCALE_M)
		target.draw_line(Vector2(x, y + 2.5), Vector2(x, y + 9.5), Color8(95, 68, 48), 1.4)
		if index % 3 == 0:
			target.draw_circle(Vector2(x + 5, y + 13.0), 1.5, Color8(189, 170, 133))

func begin_track_draw() -> void:
	_surface_meshes.clear()

func _draw_strip(target: Node2D, edge: PackedVector2Array, top: float, bottom: float, color: Color, texture: Texture2D = null) -> void:
	if edge.size() < 2:
		return
	var strip := PackedVector2Array()
	if texture == null:
		for point in edge:
			strip.append(point + Vector2(0, top))
		for index in range(edge.size() - 1, -1, -1):
			strip.append(edge[index] + Vector2(0, bottom))
		target.draw_colored_polygon(strip, color)
		return

	# Adjacent quads keep the texture attached to the local grade at sharp changes.
	var uv := PackedVector2Array()
	var triangles := PackedInt32Array()
	var tile_width := (bottom - top) * texture.get_width() / texture.get_height()
	for index in range(edge.size()):
		var point := edge[index]
		strip.append(point + Vector2(0, top))
		strip.append(point + Vector2(0, bottom))
		uv.append(Vector2(point.x / tile_width, 0.0))
		uv.append(Vector2(point.x / tile_width, 1.0))
		if index < edge.size() - 1:
			var v := index * 2
			triangles.append_array(PackedInt32Array([v, v + 2, v + 1, v + 2, v + 3, v + 1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = strip
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = triangles
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	_surface_meshes.append(mesh)
	target.draw_mesh(mesh, texture, Transform2D.IDENTITY, color)

func draw_rolling_pipe(target: Node2D, center: Vector2, angle: float) -> void:
	target.draw_circle(center, 13.0, Color8(55, 53, 46), true, -1.0, true)
	target.draw_circle(center, 11.5, Color8(158, 149, 123), true, -1.0, true)
	target.draw_circle(center + Vector2(0.5, 0.5), 7.3, Color8(67, 67, 58), true, -1.0, true)
	target.draw_arc(center, 9.6, angle, angle + 1.45, 8, Color8(201, 191, 158), 2.0, true)

func draw_supplies(target: Node2D, base: Vector2) -> void:
	target.draw_rect(Rect2(base + Vector2(-34, -23), Vector2(68, 23)), Color8(48, 50, 39))
	target.draw_rect(Rect2(base + Vector2(-31, -21), Vector2(62, 19)), Color8(93, 109, 73))
	target.draw_line(base + Vector2(-30, -16), base + Vector2(30, -16), Color8(157, 164, 121), 2.0)
	for x in [-22, 22]:
		target.draw_rect(Rect2(base + Vector2(x, -20), Vector2(5, 20)), Color8(65, 68, 52))
	target.draw_rect(Rect2(base + Vector2(-14, -40), Vector2(23, 18)), Color8(155, 64, 42))
	target.draw_rect(Rect2(base + Vector2(-10, -43), Vector2(11, 4)), Color8(80, 58, 45))
	target.draw_string(ThemeDB.fallback_font, base + Vector2(-37, -50), "VORRÄTE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color8(255, 221, 152))



func draw_street_details(target, view: Vector2) -> void:
	for meter in [12.0, 40.0, 98.0, 165.0, 285.0, 569.0, 693.0, 916.0, 973.0, 1260.0, 1376.0, 1406.0]:
		var x: float = meter * SCALE_M
		if x < view.x - 65.0 or x > view.y + 65.0:
			continue
		var base := Vector2(x, target._lower_height(meter) - 1.0)
		_draw_quay_lamp(target, base)
	for meter in [301.0, 319.0, 379.0, 398.0, 479.0, 487.0, 559.0, 585.0, 1171.0, 1245.0]:
		var x: float = meter * SCALE_M
		if x < view.x - 70.0 or x > view.y + 70.0:
			continue
		for offset in [-50.0, 0.0, 50.0]:
			var base := Vector2(x + offset, target._lower_height((x + offset) / SCALE_M))
			target.draw_rect(Rect2(base + Vector2(-9, -3), Vector2(18, 3)), Color8(51, 50, 43))
			target.draw_colored_polygon(PackedVector2Array([base + Vector2(-7, -3), base + Vector2(-2, -21), base + Vector2(2, -21), base + Vector2(7, -3)]), Color8(185, 80, 34))
			target.draw_line(base + Vector2(-4, -11), base + Vector2(4, -11), Color8(227, 218, 182), 3.0)

func _draw_quay_lamp(target: Node2D, base: Vector2) -> void:
	target.draw_rect(Rect2(base + Vector2(-7, -7), Vector2(14, 7)), Color8(40, 54, 48))
	target.draw_line(base, base + Vector2(0, -132), Color8(42, 59, 51), 5.0)
	target.draw_line(base + Vector2(-1, -8), base + Vector2(-1, -128), Color8(104, 119, 99), 1.2)
	var lamp := base + Vector2(0, -141)
	target.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-12, -10), lamp + Vector2(12, -10), lamp + Vector2(7, 10), lamp + Vector2(-7, 10)]), Color8(46, 62, 52))
	target.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-9, -7), lamp + Vector2(9, -7), lamp + Vector2(5, 7), lamp + Vector2(-5, 7)]), Color8(202, 190, 138))
	target.draw_line(lamp + Vector2(0, -8), lamp + Vector2(0, 9), Color8(59, 69, 55), 2.0)
	target.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-14, -10), lamp + Vector2(0, -20), lamp + Vector2(14, -10)]), Color8(43, 62, 52))


func draw_depot(target: Node2D, x: float, ground: float, view: Vector2) -> void:
	var source := Rect2(44, 7, 2083, 671)
	var size := source.size * 0.64
	if x + size.x * 0.5 < view.x or x - size.x * 0.5 > view.y:
		return
	var base := Vector2(x - size.x * 0.5, ground + 7.0)
	target.draw_texture_rect_region(_depot, Rect2(base - Vector2(0, size.y), size), source)
	for offset in [385.0, 705.0, 997.0]:
		var lamp := base + Vector2(offset, -154.0)
		target.draw_colored_polygon(PackedVector2Array([lamp - Vector2(30, 0), lamp + Vector2(30, 0), lamp + Vector2(102, 145), lamp + Vector2(-100, 145)]), Color(1.0, 0.79, 0.43, 0.065))

func draw_barrel_burst(target: Node2D, center: Vector2, age: float) -> void:
	var fade := 1.0 - age
	if age < 0.34:
		var width := lerpf(54.0, 170.0, smoothstep(0.0, 0.24, age))
		var size := Vector2(width, width * FIRE_SOURCE.size.y / FIRE_SOURCE.size.x)
		var flame_alpha := 1.0 - smoothstep(0.10, 0.34, age)
		target.draw_texture_rect_region(_blast_fire, Rect2(center - Vector2(size.x * 0.5, size.y * 0.75), size), FIRE_SOURCE, Color(1.0, 1.0, 1.0, flame_alpha))
	for index in range(8):
		var drift := Vector2(cos(index * 2.4) * (20.0 + 83.0 * age), -14.0 - age * (64.0 + 11.0 * index))
		target.draw_circle(center + drift, 9.0 + age * 24.0, Color(0.20, 0.17, 0.15, fade * 0.43), true, -1.0, true)
	for index in range(13):
		var direction := Vector2.from_angle(-0.16 - index * 0.218 + sin(index * 17.3) * 0.15)
		var spark := center + direction * (12.0 + age * (89.0 + 6.0 * index + 41.0 * sin(index * 13.1))) + Vector2(0, 85.0 * age * age)
		target.draw_line(spark, spark + direction * ((6.0 + float(index % 4) * 2.5) * fade), Color(1.0, 0.65, 0.22, fade), 2.4, true)

func draw_scrapyard(target: Node2D, x: float, ground: float, view: Vector2) -> void:
	var source := Rect2(0, 27, 2172, 668)
	var size := source.size * 0.69
	if x + size.x * 0.5 < view.x or x - size.x * 0.5 > view.y:
		return
	target.draw_texture_rect_region(_scrapyard, Rect2(Vector2(x - size.x * 0.5, ground + 4.0 - size.y), size), source)

func draw_jump_yard(target: Node2D, view: Vector2, start_m: float) -> void:
	var center := (start_m - 3.0) * SCALE_M
	var source := Rect2(0, 136, 2172, 526)
	var size := source.size * 0.68
	if center + size.x * 0.5 < view.x or center - size.x * 0.5 > view.y:
		return
	target.draw_texture_rect_region(_girder_yard, Rect2(Vector2(center - size.x * 0.5, 522.0 - size.y), size), source)

func _site_edge(view: Vector2, from_m: float, to_m: float, height: Callable) -> PackedVector2Array:
	var edge := PackedVector2Array()
	var left := maxf(view.x, from_m * SCALE_M)
	var right := minf(view.y, to_m * SCALE_M)
	if right - left < 2.0:
		return edge
	var segments := ceili((right - left) / 12.0)
	for index in range(segments + 1):
		var x := lerpf(left, right, float(index) / float(segments))
		edge.append(Vector2(x, height.call(x / SCALE_M)))
	return edge

func draw_girder_site(target, view: Vector2) -> void:
	var site_start: float = target.SAND_START_M
	var lip: float = target.SAND_LIP_M
	var deck_start: float = target.GIRDER_START_M
	var end: float = target.GIRDER_END_M
	var plates := _site_edge(view, site_start - 12.0, site_start, target._lower_height)
	if plates.size() > 1:
		_draw_strip(target, plates, 0.0, 23.0, Color.WHITE, _girder_materials[2])
		for i in range(0, plates.size() - 1, 4):
			var p := plates[i]
			target.draw_line(p, p + Vector2(0, 23), Color8(52, 54, 51), 1.8)
			target.draw_circle(p + Vector2(5, 17), 1.7, Color8(188, 165, 123))

	var gravel := _site_edge(view, lip, end, target._lower_height)
	if gravel.size() > 1:
		_draw_strip(target, gravel, 0.0, 27.0, Color.WHITE, _girder_materials[1])

	var sand := _site_edge(view, site_start, lip, target._sand_height)
	if sand.size() > 1:
		var bank := sand.duplicate()
		var lip_visible := absf(sand[-1].x - lip * SCALE_M) < 0.5 and sand[-1].x - sand[0].x > 34.0
		if lip_visible:
			for offset in [Vector2(-4, 15), Vector2(-1, 23), Vector2(-9, 43), Vector2(-11, 68), Vector2(-24, 102)]:
				bank.append(sand[-1] + offset)
		bank.append(Vector2(sand[-1].x - (18.0 if lip_visible else 0.0), 522.0))
		bank.append(Vector2(sand[0].x, 522.0))
		var uv := PackedVector2Array()
		for point in bank:
			uv.append(Vector2(point.x / 930.0, (point.y - 374.0) / 160.0))
		target.draw_colored_polygon(bank, Color.WHITE, uv, _girder_materials[0])
		var track := PackedVector2Array()
		for offset in [2.0, 11.0, 19.0]:
			track.clear()
			for point in sand:
				track.append(point + Vector2(0, offset))
			var ink := Color8(202, 156, 89) if offset < 3.0 else Color8(115, 77, 46, 100)
			target.draw_polyline(track, ink, 2.8, true)
		if absf(sand[-1].x - lip * SCALE_M) < 0.5:
			target.draw_polyline(PackedVector2Array([sand[-1], sand[-1] + Vector2(-4, 28), sand[-1] + Vector2(-14, 75), Vector2(sand[-1].x - 28.0, 520.0)]), Color8(123, 81, 50), 2.5, true)
			for index in range(6):
				var stone := Vector2(sand[-1].x + 3.0 + index * 8.0, 519.0 - float(index % 3) * 2.0)
				target.draw_circle(stone, 2.5, Color8(146, 114, 75), true, -1.0, true)

	var deck := _site_edge(view, deck_start, end, target._girder_height)
	if deck.size() < 2:
		return
	var first := maxi(0, floori((view.x / SCALE_M - deck_start) / 5.0))
	var last := mini(ceili((end - deck_start) / 5.0), ceili((view.y / SCALE_M - deck_start) / 5.0))
	for index in range(first, last):
		var meter := deck_start + 5.0 * index + 1.0
		if meter >= target.SCAFFOLD_START_M and meter < target.SCAFFOLD_END_M:
			continue
		var x := meter * SCALE_M
		var y: float = target._girder_height(meter)
		var ground: float = target._lower_height(meter)
		if ground - y < 42.0:
			continue
		var foot := Vector2(x, ground + 19.0)
		var pier := Rect2(x - 13.0, y + 33.0, 26.0, foot.y - y - 33.0)
		target.draw_texture_rect(_girder_materials[3], pier, true, Color(0.65, 0.64, 0.58))
		target.draw_rect(pier, Color8(79, 76, 65), false, 2.0)
		_draw_structure(target, STRUCT_BEARING, foot, 43.0)
		_draw_structure(target, STRUCT_JOINT, Vector2(x + 8.0, y + 41.0), 32.0)
		var brace_x := minf(x + 155.0, end * SCALE_M)
		var brace_y: float = target._girder_height(brace_x / SCALE_M)
		target.draw_line(foot - Vector2(0, 14), Vector2(brace_x, brace_y + 23.0), Color8(59, 59, 51), 7.0, true)
		target.draw_line(foot - Vector2(0, 15), Vector2(brace_x, brace_y + 21.0), Color8(138, 104, 71), 1.5, true)
	for section in [[deck_start, target.SCAFFOLD_START_M], [target.SCAFFOLD_END_M, end]]:
		var edge := _site_edge(view, section[0], section[1], target._girder_height)
		if edge.size() > 1:
			_draw_steel_deck(target, edge)
	_draw_scaffold(target, view)

func _draw_steel_deck(target, deck: PackedVector2Array) -> void:
	_draw_strip(target, deck, 8.0, 38.0, Color(0.56, 0.54, 0.52), _girder_materials[2])
	_draw_strip(target, deck, 28.0, 37.0, Color8(117, 77, 51))
	_draw_strip(target, deck, 14.0, 24.0, Color8(157, 104, 65))
	_draw_strip(target, deck, 24.0, 27.0, Color8(57, 48, 43))
	_draw_strip(target, deck, 0.0, 13.0, Color.WHITE, _girder_materials[2])
	for index in range(0, deck.size() - 1, 3):
		var p := deck[index]
		target.draw_line(p, p + Vector2(0, 12), Color8(54, 64, 64), 1.3, true)
		for offset in [16.0, 30.0]:
			target.draw_circle(p + Vector2(5, offset), 2.2, Color8(68, 52, 43), true, -1.0, true)
			target.draw_circle(p + Vector2(4.5, offset - 0.6), 1.3, Color8(193, 155, 105), true, -1.0, true)
	if absf(deck[0].x - target.GIRDER_START_M * SCALE_M) < 0.5:
		var p := deck[0]
		target.draw_rect(Rect2(p, Vector2(24, 39)), Color8(47, 49, 43))
		for offset in [5.0, 15.0, 25.0]:
			target.draw_line(p + Vector2(1, offset), p + Vector2(23, offset - 4), Color8(233, 175, 63), 4.0, true)





func draw_quay_foreground(target: Node2D, view: Vector2, camera: Camera2D) -> void:
	var camera_x := camera.get_screen_center_position().x if camera != null else 0.0
	var sources := [Rect2(64, 112, 512, 605), Rect2(719, 91, 705, 626), Rect2(1470, 203, 696, 510)]
	for anchor in [842.0, 854.0, 868.0, 921.0, 939.0, 966.0, 981.0, 996.0, 1016.0, 1276.0, 1288.0, 1300.0, 1404.0]:
		var index := floori(anchor) % sources.size()
		var world_x: float = anchor * SCALE_M
		var x := world_x + (world_x - camera_x) * 0.09
		if x < view.x - 120.0 or x > view.y + 120.0:
			continue
		var source: Rect2 = sources[index]
		var height := [102.0, 118.0, 60.0][index] as float
		var size := source.size * (height / source.size.y)
		target.draw_texture_rect_region(_foreground, Rect2(Vector2(x - size.x * 0.5, 735.0 - size.y), size), source, Color(0.81, 0.78, 0.66))

func draw_tilting_crossing(target, crossing, view: Vector2) -> void:
	var pit := _site_edge(view, target.TILT_START_M, target.TILT_EXIT_M, target._lower_height)
	if pit.size() > 1:
		var earth := pit.duplicate()
		earth.append(Vector2(pit[-1].x, 518.0))
		earth.append(Vector2(pit[0].x, 518.0))
		var uv := PackedVector2Array()
		for point in earth:
			uv.append(Vector2(point.x / 1180.0, (point.y - 518.0) / (target.TILT_DEPTH + 6.0)))
		target.draw_colored_polygon(earth, Color(0.60, 0.56, 0.46), uv, _girder_materials[1])
		_draw_strip(target, pit, 0.0, 25.0, Color.WHITE, _girder_materials[1])
	var pivot: Vector2 = crossing.position
	var toe: Vector2 = pivot + crossing.TIP.rotated(crossing.rotation)
	_draw_structure(target, STRUCT_BEARING, pivot + Vector2(0, 49), 68.0)
	var foot := Vector2(pivot.x + crossing.LENGTH - 19.0, 520.0 + target.TILT_DEPTH - 1.0)
	var split: bool = crossing.elapsed >= crossing.WARNING_S
	var wobble := sin(crossing.elapsed * 85.0) * 3.0 if crossing.elapsed >= 0.0 and not split else 0.0
	var lower_tip := foot + (Vector2(-49, -3) if split else Vector2(wobble, crossing.TIP.y - target.TILT_DEPTH))
	var brace_top := foot - Vector2(wobble, 100)
	target.draw_line(foot, lower_tip, Color8(72, 44, 29), 7.0 if split else 18.0, true)
	target.draw_line(foot - Vector2(4, 1), lower_tip - Vector2(4, 1), Color8(153, 101, 57), 3.0, true)
	if not split:
		target.draw_line(foot - Vector2(48, 2), brace_top, Color8(113, 73, 43), 10.0, true)
		target.draw_polyline(PackedVector2Array([foot - Vector2(7, 65), foot - Vector2(2, 57), foot - Vector2(5, 49)]), Color8(53, 37, 27), 2.0, true)
	var span := pivot.distance_to(toe)
	target.draw_set_transform(pivot, (toe - pivot).angle())
	target.draw_texture_rect(_girder_materials[2], Rect2(0, 7, span, 19), true, Color(0.61, 0.57, 0.49))
	target.draw_rect(Rect2(0, 23, span, 3), Color8(88, 56, 39))
	target.draw_texture_rect(_materials[2], Rect2(0, 0, span, 9), true)
	target.draw_line(Vector2.ZERO, Vector2(span, 0), Color8(198, 155, 100), 2.0, true)
	for index in range(1, floori(span / 20.0)):
		var x := index * 20.0
		target.draw_line(Vector2(x, 0), Vector2(x, 8), Color8(56, 40, 28), 1.5)
		target.draw_circle(Vector2(x + 5, 16), 2.0, Color8(170, 137, 101))
	for stripe in range(4):
		var stripe_x := span - 45.0 + stripe * 9.0
		target.draw_line(Vector2(stripe_x, 21.0), Vector2(stripe_x + 7.0, 10.0), Color8(220, 158, 62), 3.0, true)
	target.draw_circle(Vector2(10, 15), 6.0, Color8(41, 44, 41))
	target.draw_circle(Vector2(10, 15), 3.5, Color8(169, 145, 106))
	target.draw_set_transform(Vector2.ZERO)






func draw_new_challenges(target, view: Vector2) -> void:
	var gravel := _site_edge(view, target.LOADING_LIP_M, target.LOADING_END_M, target._lower_height)
	if gravel.size() > 1:
		_draw_strip(target, gravel, 0.0, 24.0, Color.WHITE, _girder_materials[1])
		for offset in [7.0, 14.0]:
			var tracks := PackedVector2Array()
			for p in gravel:
				tracks.append(p + Vector2(0, offset))
			target.draw_polyline(tracks, Color8(80, 70, 52, 105), 2.2, true)
	var approach := _site_edge(view, target.LOADING_START_M, target.LOADING_EDGE_M if target.loading_broken else target.LOADING_LIP_M, target.loading_ramp_height)
	var kai := _site_edge(view, target.LOADING_KAI_M, target.LOADING_END_M, target.loading_kai_height)
	if approach.size() > 1:
		for index in range(0, approach.size(), 10):
			var p := approach[index]
			var foot := Vector2(p.x, target._lower_height(p.x / SCALE_M) + 22.0)
			if foot.y - p.y < 34.0:
				continue
			target.draw_line(p + Vector2(0, 8), foot, Color8(72, 58, 42), 10.0)
			target.draw_line(p + Vector2(2, 10), foot + Vector2(2, 0), Color8(142, 108, 71), 2.0)
			target.draw_line(p + Vector2(6, 9), foot + Vector2(-46, 0), Color8(97, 72, 48), 5.0)
		_draw_strip(target, approach, 0.0, 16.0, Color.WHITE, _materials[2])
		for index in range(0, approach.size(), 2):
			var p := approach[index]
			var brittle: bool = p.x >= target.LOADING_EDGE_M * SCALE_M
			target.draw_line(p, p + Vector2(0, 14), Color8(62, 46, 32), 1.4)
			target.draw_circle(p + Vector2(4, 11), 1.6, Color8(206, 158, 70) if brittle else Color8(143, 132, 115))
	if kai.size() > 1:
		var retaining := kai.duplicate()
		retaining.append(Vector2(kai[-1].x, target._lower_height(kai[-1].x / SCALE_M) + 22.0))
		retaining.append(Vector2(kai[0].x, target._lower_height(kai[0].x / SCALE_M) + 22.0))
		var uv := PackedVector2Array()
		for p in retaining:
			uv.append(Vector2(p.x / 900.0, p.y / 300.0))
		target.draw_colored_polygon(retaining, Color(0.72, 0.70, 0.65), uv, _wall)
		_draw_strip(target, kai, 0.0, 13.0, Color.WHITE, _girder_materials[3])
		if absf(kai[0].x - target.LOADING_KAI_M * SCALE_M) < 0.5:
			target.draw_rect(Rect2(kai[0], Vector2(23, 11)), Color8(222, 170, 66))
	var first := _site_edge(view, target.PLATE_START_M, target.PLATE_JOIN_M, target._lower_height)
	var second := _site_edge(view, target.PLATE_JOIN_M, target.PLATE_CREST_M, target._lower_height)
	for panel in [first, second]:
		if panel.size() < 2:
			continue
		_draw_strip(target, panel, 0.0, 23.0, Color(0.77, 0.76, 0.66) if panel == first else Color(0.91, 0.89, 0.79), _girder_materials[3])
		for index in range(0, panel.size(), 4):
			var p: Vector2 = panel[index]
			target.draw_line(p + Vector2(1, 1), p + Vector2(-3, 20), Color8(86, 84, 75), 2.0, true)
			target.draw_line(p + Vector2(3, 5), p + Vector2(23, 5), Color8(139, 127, 106, 180), 1.2)
	var join_x: float = target.PLATE_JOIN_M * SCALE_M
	if join_x >= view.x and join_x <= view.y:
		var p := Vector2(join_x, target._lower_height(target.PLATE_JOIN_M))
		target.draw_polyline(PackedVector2Array([p, p + Vector2(5, 6), p + Vector2(-1, 13), p + Vector2(2, 23)]), Color8(60, 55, 49), 3.5, true)
	_draw_worksite_sign(target, view, target.LOADING_START_M - 7.0, "LADEKAI")
	_draw_worksite_sign(target, view, target.PLATE_START_M - 4.0, "ABSATZ")
	_draw_worksite_sign(target, view, target.LOAD_GATE_M - 8.0, "LOSE LADUNG")
	_draw_rolling_load(target, view)

func _draw_worksite_sign(target, view: Vector2, meter: float, caption: String) -> void:
	var x := meter * SCALE_M
	if x < view.x - 65.0 or x > view.y + 65.0:
		return
	var y: float = target._lower_height(meter)
	target.draw_line(Vector2(x, y), Vector2(x, y - 78), Color8(77, 70, 56), 4.0)
	target.draw_rect(Rect2(x - 51, y - 91, 102, 26), Color8(67, 57, 38))
	target.draw_rect(Rect2(x - 49, y - 89, 98, 22), Color8(205, 171, 94))
	target.draw_string(ThemeDB.fallback_font, Vector2(x - 49, y - 73), caption, HORIZONTAL_ALIGNMENT_CENTER, 98, 12, Color8(45, 42, 33))

func _draw_rolling_load(target, view: Vector2) -> void:
	var state: Dictionary = target.rolling_load
	var x: float = target.LOAD_GATE_M * SCALE_M + target.LOAD_OFFSET if state.is_empty() else state.x
	if x < view.x - 40.0 or x > view.y + 40.0:
		return
	var depth := 0.0 if state.is_empty() else smoothstep(3.12, target.LOAD_CLEAR_TIME, float(state.age))
	var radius := lerpf(24.0, 17.0, depth)
	var center := Vector2(x, target._lower_height(x / SCALE_M) - radius - depth * 25.0)
	var angle := 0.0 if state.is_empty() else float(state.angle)
	target.draw_set_transform(center, angle)
	target.draw_texture_rect_region(_challenge_props, Rect2(-radius * 0.965, -radius, radius * 1.93, radius * 2.0), Rect2(1552, 88, 536, 556))
	target.draw_set_transform(Vector2.ZERO)

func draw_challenge_backdrop(target, view: Vector2) -> void:
	_draw_challenge_prop(target, view, 601.0, Rect2(39, 225, 631, 397), 109.0)
	_draw_challenge_prop(target, view, 637.0, Rect2(39, 225, 631, 397), 81.0, true)
	_draw_challenge_prop(target, view, 700.0, Rect2(737, 231, 700, 373), 86.0)
	_draw_challenge_prop(target, view, 976.0, Rect2(737, 231, 700, 373), 70.0)
	_draw_challenge_prop(target, view, 1026.0, Rect2(39, 225, 631, 397), 86.0)
	_draw_challenge_prop(target, view, 1220.0, Rect2(737, 231, 700, 373), 72.0)

func _draw_challenge_prop(target, view: Vector2, meter: float, source: Rect2, height: float, on_kai: bool = false) -> void:
	var x := meter * SCALE_M
	var size := source.size * (height / source.size.y)
	if x + size.x * 0.5 < view.x or x - size.x * 0.5 > view.y:
		return
	var y: float = target.loading_kai_height(meter) if on_kai else target._lower_height(meter)
	target.draw_texture_rect_region(_challenge_props, Rect2(Vector2(x - size.x * 0.5, y + 4.0 - size.y), size), source, Color(0.94, 0.91, 0.84))

func draw_pumpworks_route(target, view: Vector2, canvas: Node2D) -> void:
	var approach := _site_edge(view, target.PUMP_ENTRY_M, target.PUMP_DECK_M, target.pump_ramp_height)
	var deck := _site_edge(view, target.PUMP_DECK_M, target.PUMP_DROP_M, target.pump_upper_height)
	var exit := _site_edge(view, target.PUMP_DROP_M, target.PUMP_EXIT_M, target.pump_upper_height)
	if not target.pump_fell and deck.size() > 1:
		var left: float = (target.PUMP_DECK_M + 0.65) * SCALE_M
		var width: float = (target.PUMP_DROP_M - target.PUMP_DECK_M - 1.35) * SCALE_M
		var floor_y: float = target.PUMP_DECK_Y
		var opening := Rect2(left, floor_y - 71.0, width, 71.0)
		canvas.draw_rect(opening.grow(4.0), Color8(116, 77, 59))
		canvas.draw_rect(opening, Color8(42, 36, 32))
		var bay := Rect2(left + 8.0, floor_y - 66.0, width - 16.0, 60.0)
		canvas.draw_texture_rect_region(_wall, bay, Rect2(120, 165, bay.size.x * 4.0, bay.size.y * 4.0), Color8(93, 79, 68))
		var shade := PackedVector2Array([bay.position, Vector2(bay.end.x, bay.position.y), bay.end, Vector2(bay.position.x, bay.end.y)])
		canvas.draw_polygon(shade, PackedColorArray([Color(0.08, 0.06, 0.05, 0.72), Color(0.08, 0.06, 0.05, 0.72), Color(0.08, 0.06, 0.05, 0.15), Color(0.08, 0.06, 0.05, 0.15)]))
		canvas.draw_line(opening.position, opening.position + Vector2(width, 0), Color8(154, 123, 94), 4.0)
		for offset in [7.0, width - 7.0]:
			var point := Vector2(left + offset, floor_y)
			canvas.draw_line(point, point - Vector2(0, 66), Color8(80, 66, 54), 5.0)
			canvas.draw_circle(point - Vector2(0, 59), 2.5, Color8(234, 166, 79))
	for edge in [approach, deck, exit]:
		if edge.size() < 2 or (target.pump_fell and edge != approach):
			continue
		for index in range(0, edge.size(), 8):
			var p: Vector2 = edge[index]
			var foot := Vector2(p.x, target._lower_height(p.x / SCALE_M))
			if edge != deck and foot.y - p.y > 24.0:
				canvas.draw_line(p + Vector2(0, 10), foot, Color8(68, 65, 56), 8.0)
				canvas.draw_line(p + Vector2(2, 12), foot + Vector2(2, 0), Color8(139, 110, 79), 2.0)
				_draw_structure(canvas, STRUCT_BEARING, foot + Vector2(0, 7), 24.0)
		_draw_strip(canvas, edge, 0.0, 15.0, Color.WHITE, _girder_materials[2])
		_draw_strip(canvas, edge, 11.0, 18.0, Color8(103, 72, 53))
		for index in range(0, edge.size(), 3):
			var p: Vector2 = edge[index]
			var fragile: bool = edge == deck
			canvas.draw_line(p, p + Vector2(0, 11), Color8(157, 120, 65) if fragile else Color8(64, 64, 55), 2.0)
			canvas.draw_circle(p + Vector2(5, 14), 1.5, Color8(185, 151, 110))

	if target.pump_fell and target.collapse_site.elapsed < 0.65 and deck.size() > 1:
		var progress := clampf(float(target.collapse_site.elapsed) / 0.65, 0.0, 1.0)
		var first: Vector2 = deck[0]
		var last: Vector2 = deck[-1]
		var center := (first + last) * 0.5
		var fall := Vector2(-11.0 * progress, 77.0 * progress * progress)
		var falling := PackedVector2Array()
		for point: Vector2 in deck:
			falling.append(center + (point - center).rotated(progress * 0.28) + fall)
		_draw_strip(canvas, falling, 0.0, 15.0, Color8(163, 146, 122), _girder_materials[2])
		_draw_strip(canvas, falling, 11.0, 18.0, Color8(103, 72, 53))
func _draw_scaffold(target, view: Vector2) -> void:
	var left: float = target.SCAFFOLD_START_M * SCALE_M
	var right: float = target.SCAFFOLD_END_M * SCALE_M
	if left > view.y or right < view.x:
		return
	var y: float = target.GIRDER_DECK_Y + target.scaffold_sag
	for index in range(3):
		var x := lerpf(left + 12.0, right - 12.0, index * 0.5)
		var ground: float = target._lower_height(x / SCALE_M)
		var post_top := y + (18.0 if target.scaffold_fall < 0.0 else 105.0 + index * 7.0)
		target.draw_line(Vector2(x, post_top), Vector2(x, ground + 4.0), Color8(58, 50, 41), 9.0)
		target.draw_line(Vector2(x - 2.0, post_top), Vector2(x - 2.0, ground), Color8(154, 118, 83), 2.0)
		if index < 2 and target.scaffold_fall < 0.0:
			target.draw_line(Vector2(x, ground - 9.0), Vector2(x + (right - left - 24.0) * 0.5, y + 22.0), Color8(99, 74, 53), 6.0)
			target.draw_line(Vector2(x, y + 22.0), Vector2(x + (right - left - 24.0) * 0.5, ground - 9.0), Color8(154, 116, 75), 4.0)
	for index in range(9):
		var width := (right - left) / 9.0
		var x := left + width * (index + 0.5)
		var fall: float = clampf(target.scaffold_fall - index * 0.025, 0.0, 0.72)
		var drop := minf(fall * fall * 310.0, float(target._lower_height(x / SCALE_M)) - y - 14.0)
		target.draw_set_transform(Vector2(x, y + drop), fall * (0.7 if index % 2 == 0 else -0.85))
		var plank := Rect2(-width * 0.5, 0.0, width - 1.0, 16.0)
		target.draw_texture_rect(_girder_materials[2], plank, true, Color8(184, 139, 96))
		target.draw_rect(plank, Color8(69, 48, 37), false, 1.2)
		target.draw_line(plank.position + Vector2(0, 1), Vector2(plank.end.x, 1), Color8(223, 178, 113), 1.7)
		target.draw_circle(Vector2(-width * 0.32, 10.0), 1.8, Color8(78, 71, 65))
		if target.scaffold_load >= 0.0 and target.scaffold_fall < 0.0 and not target.scaffold_crossed and index % 2 == 0:
			var stress: float = clampf(target.scaffold_load / target.SCAFFOLD_LOAD_TIME, 0.0, 1.0)
			target.draw_polyline(PackedVector2Array([Vector2(-4, 2), Vector2(0, 4), Vector2(-1, 7), Vector2(4, 8)]), Color(0.18, 0.12, 0.08, stress), 1.4, true)
	target.draw_set_transform(Vector2.ZERO)

func draw_excavation_details(target, view: Vector2) -> void:
	var pipe_x := 1021.0 * SCALE_M
	if pipe_x >= view.x - 100.0 and pipe_x <= view.y + 100.0:
		_draw_structure(target, STRUCT_PIPE, Vector2(pipe_x, target._lower_height(1021.0) + 60.0), 61.0)
	var x: float = target.FORMWORK_M * SCALE_M
	if x < view.x - 245.0 or x > view.y + 225.0:
		return
	var progress: float = smoothstep(0.0, 0.72, target.formwork_fall)
	for index in range(3):
		var base_x := x - 65.0 - index * 83.0
		var base_y: float = target._lower_height(base_x / SCALE_M)
		var origin := Vector2(base_x - progress * index * 9.0, base_y - 6.0)
		target.draw_set_transform(origin, -progress * (1.22 + index * 0.09))
		var panel := Rect2(-26.0, -157.0 + index * 8.0, 52.0, 153.0 - index * 8.0)
		target.draw_texture_rect(_girder_materials[2], panel, true, Color8(181, 138, 96))
		target.draw_rect(panel, Color8(63, 52, 45), false, 2.0)
		for offset in [-18.0, 18.0]:
			target.draw_line(Vector2(offset, panel.position.y), Vector2(offset, -4), Color8(73, 70, 59), 4.0)
		for beam_y in [-125.0, -90.0, -47.0]:
			target.draw_line(Vector2(-29, beam_y), Vector2(29, beam_y), Color8(101, 77, 54), 7.0)
			target.draw_circle(Vector2(-17, beam_y), 2.0, Color8(200, 167, 116))
			target.draw_circle(Vector2(17, beam_y), 2.0, Color8(200, 167, 116))
		target.draw_line(Vector2(-32, -10), Vector2(28, -114), Color8(146, 111, 74), 6.0)
	target.draw_set_transform(Vector2.ZERO)
	if progress > 0.58:
		var rubble_x := x - 280.0
		_draw_structure(target, STRUCT_RUBBLE, Vector2(rubble_x, target._lower_height(rubble_x / SCALE_M) + 7.0), 55.0)

func draw_spool(target: Node2D, center: Vector2, angle: float, radius: float) -> void:
	target.draw_set_transform(center, angle)
	var face := Rect2(Vector2(-radius, -radius), Vector2.ONE * radius * 2.0)
	target.draw_texture_rect_region(_challenge_props, face, Rect2(1552, 88, 536, 556))
	target.draw_set_transform(Vector2.ZERO)

func draw_action_signals(target, view: Vector2) -> void:
	for marker in [[221.0, "FÄSSER"], [571.0, "LADEKAI"], [978.0, "GERÜST"], [1258.0, "SCHROTTHOF"]]:
		var x: float = marker[0] * SCALE_M
		if x < view.x or x > view.y:
			continue
		var y: float = target._lower_height(marker[0])
		var post := Vector2(x, y - 73.0)
		target.draw_line(post, Vector2(x, y), Color8(52, 52, 46), 5.0)
		var plate := Rect2(post - Vector2(43, 9), Vector2(86, 21))
		target.draw_rect(plate, Color8(48, 46, 41))
		target.draw_rect(plate.grow(-1.0), Color8(186, 143, 75), false, 1.0)
		target.draw_string(ThemeDB.fallback_font, plate.position + Vector2(7, 15), marker[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(246, 213, 150))
		for side in [-1, 1]:
			target.draw_circle(post + Vector2(side * 39, 1), 1.4, Color8(194, 182, 150))

func draw_finish(target, x: float, y: float) -> void:
	for row in range(4):
		for column in range(3):
			var tint := Color8(224, 215, 189) if (row + column) % 2 == 0 else Color8(49, 52, 46)
			target.draw_rect(Rect2(x + column * 8.0 - 12.0, y + row * 6.0, 8.0, 6.0), tint)
	var sign := Rect2(x - 57, y - 81, 114, 28)
	target.draw_line(Vector2(x + 47, y), Vector2(x + 47, sign.end.y), Color8(59, 61, 53), 7.0)
	target.draw_rect(sign, Color8(36, 47, 43))
	target.draw_rect(sign.grow(-2.0), Color8(181, 159, 115), false, 1.5)
	target.draw_string(ThemeDB.fallback_font, sign.position + Vector2(10, 19), "UTRECHT · ZIEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color8(244, 218, 163))
func _draw_structure(target: Node2D, source: Rect2, base: Vector2, width: float) -> void:
	var size := Vector2(width, width * source.size.y / source.size.x)
	target.draw_texture_rect_region(_structural_details, Rect2(base - Vector2(size.x * 0.5, size.y), size), source)