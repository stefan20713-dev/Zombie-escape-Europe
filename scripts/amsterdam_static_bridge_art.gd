extends Node2D
var course: Node2D
var supports_only := false
var section := 0
func _ready() -> void:
	course = get_parent()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	queue_redraw()
func _draw() -> void:
	var starts: Array = [course.OPENING_RAMP_START_M, course.RAMP_START_M, course.UPPER_BRIDGE_END_M, course.HARBOR_RAMP_START_M]
	var ends: Array = [course.OPENING_RAMP_LIP_M, course.RAMP_LIP_M, course.RAMP_REJOIN_M, course.HARBOR_RAMP_LIP_M]
	if section == 4:
		if supports_only:
			_draw_upper_bridge_supports()
		else:
			_draw_upper_bridge()
	elif supports_only:
		_draw_timber_ramp_supports(float(starts[section]) * course.PIXELS_PER_METER, float(ends[section]) * course.PIXELS_PER_METER)
	else:
		_draw_timber_launch_ramp(float(starts[section]) * course.PIXELS_PER_METER, float(ends[section]) * course.PIXELS_PER_METER)
		if section == 1:
			_draw_launch_markers()

func _upper_route_height_at(x: float) -> float:
	return course._upper_route_height_at(x)
func _base_height_at(x: float) -> float:
	return course._base_height_at(x)

func _draw_upper_bridge_supports() -> void:
	# Two masonry piers visibly connect the separate raised deck to the canal
	# structure. Draw them behind the street so the lower route stays unobstructed.
	var pier_top: float = course.UPPER_BRIDGE_Y + 34.0
	for meter in [course.UPPER_BRIDGE_START_M + 3.0, course.UPPER_BRIDGE_END_M - 3.0]:
		var x: float = meter * course.PIXELS_PER_METER
		# Stop at the street edge. The piers are drawn behind the road and must
		# never cover the lower driving surface or read as obstacles in its lane.
		var pier_bottom: float = _base_height_at(x) + 4.0
		var pier_height: float = pier_bottom - pier_top
		if pier_height <= 16.0:
			continue
		draw_rect(Rect2(x - 15.0, pier_top, 30.0, pier_height), Color8(43, 46, 39))
		var face := Rect2(x - 11.0, pier_top + 3.0, 22.0, pier_height - 5.0)
		var atlas_scale: Vector2 = course.AMSTERDAM_BRICK_TILE.get_size() / 294.0
		draw_texture_rect_region(course.AMSTERDAM_BRICK_TILE, face, Rect2(Vector2(110.0, 30.0) * atlas_scale, face.size * atlas_scale), Color(0.78, 0.72, 0.65))
		var course_y: float = pier_top + 19.0
		while course_y < pier_bottom - 8.0:
			draw_line(Vector2(x - 11.0, course_y), Vector2(x + 11.0, course_y + 1.0), Color8(62, 57, 45, 225), 2.0, true)
			draw_line(Vector2(x - 7.0, course_y - 7.0), Vector2(x - 7.0, course_y + 8.0), Color8(173, 145, 102, 150), 1.0, true)
			course_y += 24.0

func _draw_upper_bridge() -> void:
	var left_x: float = course.UPPER_BRIDGE_START_M * course.PIXELS_PER_METER
	var right_x: float = course.UPPER_BRIDGE_END_M * course.PIXELS_PER_METER
	var deck_y: float = course.UPPER_BRIDGE_Y
	draw_colored_polygon(PackedVector2Array([
		Vector2(left_x, deck_y), Vector2(right_x, deck_y), Vector2(right_x - 18.0, deck_y + 37.0),
		Vector2(left_x + 18.0, deck_y + 37.0)
	]), Color8(99, 81, 61))
	draw_colored_polygon(PackedVector2Array([
		Vector2(left_x + 5.0, deck_y + 9.0), Vector2(right_x - 5.0, deck_y + 9.0),
		Vector2(right_x - 22.0, deck_y + 33.0), Vector2(left_x + 22.0, deck_y + 33.0)
	]), Color8(120, 89, 63))
	draw_line(Vector2(left_x + 18.0, deck_y + 36.0), Vector2(right_x - 18.0, deck_y + 36.0), Color8(58, 54, 48), 5.0, true)
	draw_line(Vector2(left_x, deck_y), Vector2(right_x, deck_y), Color8(39, 44, 39), 11.0, true)
	draw_line(Vector2(left_x, deck_y - 1.0), Vector2(right_x, deck_y - 1.0), Color8(208, 176, 119), 5.5, true)
	# Stone block joints and chipped highlights give the deck a real masonry face.
	var block_x: float = left_x + 8.0
	var block_index: int = 0
	while block_x < right_x - 8.0:
		var joint_y: float = deck_y + 10.0 if block_index % 2 == 0 else deck_y + 22.0
		draw_line(Vector2(block_x, deck_y + 10.0), Vector2(block_x - 2.0, deck_y + 34.0), Color8(49, 49, 41, 225), 1.8, true)
		draw_line(Vector2(block_x + 3.0, joint_y), Vector2(minf(right_x - 14.0, block_x + 27.0), joint_y), Color8(175, 144, 102, 105), 1.0, true)
		block_x += 34.0
		block_index += 1
	# The raised deck now leaves a full vehicle-height opening above the lower
	# street. Its compact stone arches are decorative and never intrude into the
	# underpass lane.
	for arch_index in range(4):
		var arch_left: float = left_x + 5.0 + float(arch_index) * (right_x - left_x - 10.0) / 4.0
		var arch_width: float = (right_x - left_x - 10.0) / 4.0
		var arch_points := PackedVector2Array()
		var arch_bottom_offset: float = 68.0
		var arch_rise: float = 50.0
		for curve_index in range(17):
			var angle: float = PI + PI * float(curve_index) / 16.0
			var point := Vector2(
				arch_left + arch_width * 0.5 + cos(angle) * arch_width * 0.5,
				deck_y + arch_bottom_offset + sin(angle) * arch_rise
			)
			arch_points.append(point)
		var stone_face := PackedVector2Array([Vector2(arch_left, deck_y + 10.0), Vector2(arch_left + arch_width, deck_y + 10.0)])
		for point_index in range(arch_points.size() - 1, -1, -1):
			stone_face.append(arch_points[point_index])
		var stone_uv := PackedVector2Array()
		for point in stone_face:
			stone_uv.append(point / Vector2(294.0, 294.0))
		draw_colored_polygon(stone_face, Color(0.92, 0.88, 0.77), stone_uv, course.AMSTERDAM_BRICK_TILE)
		var arch_center := Vector2(arch_left + arch_width * 0.5, deck_y + arch_bottom_offset)
		for stone_index in range(arch_points.size() - 1):
			var a: Vector2 = arch_points[stone_index]
			var b: Vector2 = arch_points[stone_index + 1]
			var outer_a: Vector2 = a + (a - arch_center).normalized() * 13.0
			var outer_b: Vector2 = b + (b - arch_center).normalized() * 13.0
			var block := PackedVector2Array([a, b, outer_b, outer_a])
			var shade: float = 0.79 + float(stone_index % 4) * 0.05
			draw_colored_polygon(block, Color(0.76 * shade, 0.69 * shade, 0.55 * shade))
			draw_polyline(PackedVector2Array([a, b, outer_b]), Color8(72, 61, 48), 1.3, true)
			draw_line(outer_a, outer_b, Color8(201, 178, 133, 200), 1.4, true)
		var ivy_x: float = arch_left + 17.0
		for leaf_index in range(7):
			var leaf := Vector2(ivy_x + sin(float(leaf_index) * 2.2) * 5.0, deck_y + 13.0 + float(leaf_index) * 5.0)
			draw_circle(leaf, 3.5, Color8(102, 122, 57, 222))
	# Textured limestone cap and a low wrought-iron railing behind the lane.
	var cap := Rect2(left_x, deck_y, right_x - left_x, 11.0)
	var cap_points := PackedVector2Array([cap.position, Vector2(cap.end.x, cap.position.y), cap.end, Vector2(cap.position.x, cap.end.y)])
	var cap_uv := PackedVector2Array()
	for point in cap_points:
		cap_uv.append(Vector2(point.x / 336.0, (point.y - deck_y) / 76.0))
	draw_colored_polygon(cap_points, Color.WHITE, cap_uv, course.AMSTERDAM_COBBLE_TILE)
	draw_line(cap.position, Vector2(cap.end.x, cap.position.y), Color8(208, 192, 155), 2.0, true)
	var rail_sections: int = maxi(1, int(round((right_x - left_x) / 74.0)))
	var rail_spacing: float = (right_x - left_x - 26.0) / float(rail_sections)
	var iron := Color8(45, 59, 54)
	for rail_index in range(rail_sections):
		var rail_x: float = left_x + 13.0 + float(rail_index) * rail_spacing
		for height_offset in [13.0, 31.0]:
			draw_line(Vector2(rail_x, deck_y - height_offset), Vector2(rail_x + rail_spacing, deck_y - height_offset), iron, 3.0, true)
		for fraction in [0.25, 0.50, 0.75]:
			var spindle_x: float = rail_x + rail_spacing * fraction
			draw_line(Vector2(spindle_x, deck_y - 3.0), Vector2(spindle_x, deck_y - 29.0), iron, 1.6, true)
	for rail_index in range(rail_sections + 1):
		var rail_x: float = left_x + 13.0 + float(rail_index) * rail_spacing
		draw_line(Vector2(rail_x, deck_y), Vector2(rail_x, deck_y - 34.0), iron, 4.0, true)
		draw_circle(Vector2(rail_x, deck_y - 35.0), 3.4, iron)
		draw_circle(Vector2(rail_x - 0.8, deck_y - 36.1), 1.1, Color8(130, 141, 120))
		draw_line(Vector2(rail_x - 4.0, deck_y - 1.0), Vector2(rail_x + 4.0, deck_y - 1.0), Color8(88, 72, 49), 2.0, true)

func _draw_timber_launch_ramp(start_x: float, lip_x: float) -> void:
	var top := PackedVector2Array()
	var underside := PackedVector2Array()
	var plank_count: int = maxi(2, ceili(absf(lip_x - start_x) / 44.0))
	for plank_index in range(plank_count + 1):
		var x: float = lerpf(start_x, lip_x, float(plank_index) / float(plank_count))
		top.append(Vector2(x, _upper_route_height_at(x) - 1.0))
		underside.append(Vector2(x, _upper_route_height_at(x) + 28.0))
	var ramp_body := PackedVector2Array(top)
	for point_index in range(underside.size() - 1, -1, -1):
		ramp_body.append(underside[point_index])
	var timber_size: Vector2 = course.VISUALS.material_size(course.VISUALS.TIMBER, 270.0)
	for index in range(plank_count):
		var quad := PackedVector2Array([top[index], top[index + 1], underside[index + 1], underside[index]])
		var uv := PackedVector2Array([Vector2(top[index].x / timber_size.x, 0.0), Vector2(top[index + 1].x / timber_size.x, 0.0), Vector2(top[index + 1].x / timber_size.x, 29.0 / timber_size.y), Vector2(top[index].x / timber_size.x, 29.0 / timber_size.y)])
		draw_colored_polygon(quad, Color8(205, 196, 178), uv, course.VISUALS.TIMBER)
	for grain_index in range(3):
		var grain := PackedVector2Array()
		for sample_index in range(plank_count + 1):
			var x: float = top[sample_index].x
			var grain_y: float = top[sample_index].y + 9.0 + float(grain_index) * 6.0 + sin(x * 0.027 + float(grain_index)) * 1.2
			grain.append(Vector2(x, grain_y))
		draw_polyline(grain, Color8(161, 116, 76, 140), 1.4, true)
	draw_polyline(PackedVector2Array([ramp_body[0], ramp_body[plank_count], ramp_body[plank_count + 1]]), Color8(43, 44, 39), 4.0, true)
	draw_polyline(top, Color8(41, 43, 38), 5.0, true)
	draw_polyline(top, Color8(211, 159, 93), 2.2, true)
	if is_equal_approx(start_x, course.RAMP_START_M * course.PIXELS_PER_METER):
		var edge_y: float = _upper_route_height_at(lip_x)
		draw_line(Vector2(lip_x - 30.0, _upper_route_height_at(lip_x - 30.0)), Vector2(lip_x, edge_y), Color8(239, 204, 150), 3.0, true)
		draw_line(Vector2(lip_x, edge_y), Vector2(lip_x, edge_y + 26.0), Color8(189, 140, 90), 3.0, true)
		for rail_height in [26.0, 47.0]:
			var rail := PackedVector2Array()
			for index in range(plank_count + 1):
				var x: float = lerpf(start_x, lip_x, float(index) / float(plank_count))
				var surface_y: float = _upper_route_height_at(x)
				rail.append(Vector2(x, surface_y - rail_height))
				if rail_height == 47.0 and index % 2 == 0:
					draw_line(Vector2(x, surface_y), Vector2(x, surface_y - 53.0), Color8(71, 54, 38), 5.0, true)
			draw_polyline(rail, Color8(71, 54, 38), 5.0, true)
			draw_polyline(rail, Color8(170, 128, 81), 2.0, true)
	for plank_index in range(plank_count):
		var x: float = lerpf(start_x, lip_x, float(plank_index) / float(plank_count))
		var next_x: float = lerpf(start_x, lip_x, float(plank_index + 1) / float(plank_count))
		var y: float = _upper_route_height_at(x) + 3.0
		var next_y: float = _upper_route_height_at(next_x) + 3.0
		draw_line(Vector2(x, y), Vector2(next_x, next_y), Color8(184, 132, 75), 3.0, true)
		for bolt_x in [x + 4.0, next_x - 4.0]:
			draw_circle(Vector2(bolt_x, _upper_route_height_at(bolt_x) + 22.0), 1.7, Color8(42, 39, 34))
	# Thick side stringers, diagonal braces and amber edge reflectors give the
	# kicker a clear timber-ramp silhouette while its top follows real collision.
	for side_y_offset in [7.0, 23.0]:
		var side := PackedVector2Array()
		for plank_index in range(plank_count + 1):
			var x: float = lerpf(start_x, lip_x, float(plank_index) / float(plank_count))
			side.append(Vector2(x, _upper_route_height_at(x) + side_y_offset))
		draw_polyline(side, Color8(62, 46, 35), 5.0, true)
	for marker_index in range(8):
		var marker_x: float = lerpf(start_x + 10.0, lip_x - 5.0, float(marker_index) / 7.0)
		var marker_y: float = _upper_route_height_at(marker_x) + 15.0
		if marker_index % 2 == 0:
			draw_line(Vector2(marker_x, marker_y), Vector2(marker_x + 8.0, marker_y - 2.0), Color8(216, 154, 76, 230), 3.0, true)

func _draw_timber_ramp_supports(start_x: float, lip_x: float) -> void:
	# Draw structural legs before the road so the lower sections disappear behind
	# the asphalt instead of looking like planks stuck into the driving surface.
	for brace_index in range(1, 7):
		var x: float = lerpf(start_x, lip_x, float(brace_index) / 7.0)
		var deck_y: float = _upper_route_height_at(x)
		var ground_y: float = _base_height_at(x)
		if ground_y - deck_y < 35.0:
			continue
		var foot_y: float = ground_y + 44.0
		var near_x: float = x - 11.0
		var far_x: float = x + 15.0
		draw_line(Vector2(x, deck_y + 25.0), Vector2(near_x, foot_y), Color8(45, 39, 32), 7.0, true)
		draw_line(Vector2(x, deck_y + 25.0), Vector2(near_x, foot_y), Color8(136, 91, 52), 4.2, true)
		draw_line(Vector2(x + 5.0, deck_y + 27.0), Vector2(far_x, foot_y), Color8(51, 43, 34), 6.0, true)
		draw_line(Vector2(x + 5.0, deck_y + 27.0), Vector2(far_x, foot_y), Color8(166, 117, 68), 3.2, true)
		var brace_bottom: float = minf(ground_y - 4.0, deck_y + 79.0)
		if brace_bottom > deck_y + 40.0:
			for direction in [-1.0, 1.0]:
				var brace_top := Vector2(x - direction * 25.0, deck_y + 27.0)
				var brace_end := Vector2(x + direction * 15.0, brace_bottom)
				draw_line(brace_top, brace_end, Color8(49, 37, 28), 6.0, true)
				draw_line(brace_top, brace_end, Color8(145, 101, 61), 3.0, true)
		draw_line(Vector2(near_x - 4.0, foot_y), Vector2(far_x + 5.0, foot_y), Color8(83, 60, 40), 5.0, true)
		draw_circle(Vector2(x, deck_y + 16.0), 2.3, Color8(222, 177, 111))



func _draw_launch_markers() -> void:
	# Painted chevrons lead the eye to the elevated bridge route without adding a road sign.
	for arrow_meter in [398.0, 406.0, 414.0, 422.0, 430.0]:
		var arrow_x: float = arrow_meter * course.PIXELS_PER_METER
		var arrow_y: float = _upper_route_height_at(arrow_x) + 24.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(arrow_x - 8.0, arrow_y + 4.0), Vector2(arrow_x + 2.0, arrow_y - 6.0),
			Vector2(arrow_x + 12.0, arrow_y + 4.0), Vector2(arrow_x + 6.0, arrow_y + 2.0),
			Vector2(arrow_x + 2.0, arrow_y - 2.0), Vector2(arrow_x - 3.0, arrow_y + 2.0)
		]), Color8(231, 168, 89, 215))
	var ramp_end_x: float = course.RAMP_LIP_M * course.PIXELS_PER_METER
	draw_line(Vector2(ramp_end_x - 10.0, _upper_route_height_at(ramp_end_x) - 2.0), Vector2(ramp_end_x + 20.0, _upper_route_height_at(ramp_end_x) + 15.0), Color8(235, 164, 81), 4.0, true)
