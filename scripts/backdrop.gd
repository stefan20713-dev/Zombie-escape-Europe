extends Control

const VISUALS = preload("res://scripts/visual_materials.gd")
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const QA_DIAGNOSTICS = preload("res://scripts/qa_diagnostics.gd")
const PIXELS_PER_METER: float = CAMPAIGN_DATA.PIXELS_PER_METER
const REDRAW_INTERVAL_S: float = 1.0 / 30.0
const AMSTERDAM_CANAL_ART: Texture2D = preload("res://assets/amsterdam_gameplay_panorama_0.5.56.png")
const AMSTERDAM_WORKSHOP_ART: Texture2D = preload("res://assets/amsterdam_workshop_background_1.0.0.png")
const AMSTERDAM_QUAY_BRICK_TILE: Texture2D = preload("res://assets/amsterdam_masonry_illustrated.png")
const AMSTERDAM_PANORAMA_FADE_HEIGHT: float = 124.0
const AMSTERDAM_PANORAMA_BOTTOM_OFFSET: float = 70.0
const AMSTERDAM_PANORAMA_TOP_COVER: float = -80.0

var active_world_index: int = 0
var active_world: Dictionary = {}
var _world_profile: Dictionary = {}
var _menu_art: Texture2D
var _workshop_view: Texture2D
var _sky_gradient_texture: ImageTexture
var _amsterdam_panorama_fade_texture: ImageTexture
var route_length_m: float = 1800.0
var final_rescue_mode: bool = false
var _redraw_elapsed: float = 0.0
var _atmosphere_time_s: float = 0.0
var _last_draw_camera_x: float = -INF
var _last_draw_camera_y: float = -INF
var _last_draw_zoom_y: float = -INF
var _last_screen_state: String = ""
var _first_draw_reported: bool = false
var _route_surface_override: Node
var _wagon_override: Node2D
var _quay_gap_screen: Vector2 = Vector2(INF, INF)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_build_amsterdam_panorama_fade()
	configure_world(0)

func _build_amsterdam_panorama_fade() -> void:
	# A one-column transparent-to-canal gradient hides the panorama's hard lower
	# edge without changing the artwork's aspect ratio.
	var fade_image: Image = Image.create(1, 128, false, Image.FORMAT_RGBA8)
	var canal_color := Color8(27, 75, 80)
	for row in range(128):
		var progress: float = float(row) / 127.0
		var alpha: float = smoothstep(0.02, 1.0, progress)
		fade_image.set_pixel(0, row, Color(canal_color.r, canal_color.g, canal_color.b, alpha))
	_amsterdam_panorama_fade_texture = ImageTexture.create_from_image(fade_image)

func configure_world(world_index: int) -> void:
	active_world_index = clampi(world_index, 0, CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() - 1)
	active_world = CAMPAIGN_DATA.CAMPAIGN_WORLDS[active_world_index]
	_menu_art = _city_texture("menu_art")
	_workshop_view = _city_texture("workshop_view")
	route_length_m = float(active_world.get("length_m", 1800.0))
	final_rescue_mode = false
	_atmosphere_time_s = 0.0
	_last_draw_camera_x = -INF
	_last_draw_camera_y = -INF
	_last_draw_zoom_y = -INF
	_world_profile = _profile_for_world()
	_rebuild_sky_gradient()
	queue_redraw()

func _city_texture(key: String) -> Texture2D:
	var path: String = String(active_world.get(key, ""))
	if path.is_empty():
		return null
	if ResourceLoader.exists(path, "Texture2D"):
		return load(path) as Texture2D
	if not FileAccess.file_exists(path):
		return null
	var source := Image.load_from_file(path)
	return ImageTexture.create_from_image(source) if not source.is_empty() else null

func configure_preview_world(world_index: int, preview_length_m: float) -> void:
	configure_world(world_index)
	route_length_m = maxf(1.0, preview_length_m)
	_last_draw_camera_x = -INF
	_last_draw_camera_y = -INF
	_last_draw_zoom_y = -INF
	queue_redraw()

func bind_route_surface(route_surface: Node, wagon: Node2D) -> void:
	# Test and gameplay preview scenes can be nested under a launcher node. Keep
	# the parallax road edge bound to the exact route and vehicle being rendered.
	_route_surface_override = route_surface
	_wagon_override = wagon
	_last_draw_camera_x = -INF
	_last_draw_camera_y = -INF
	queue_redraw()

func configure_final_rescue(length: float) -> void:
	active_world_index = CAMPAIGN_DATA.CAMPAIGN_WORLDS.size() - 1
	active_world = CAMPAIGN_DATA.CAMPAIGN_WORLDS[active_world_index]
	route_length_m = maxf(300.0, length)
	final_rescue_mode = true
	_atmosphere_time_s = 0.0
	_last_draw_camera_x = -INF
	_last_draw_camera_y = -INF
	_last_draw_zoom_y = -INF
	_world_profile = _profile_for_world()
	_rebuild_sky_gradient()
	queue_redraw()

func _rebuild_sky_gradient() -> void:
	# A single tiny texture replaces the old twelve wide color bands. It avoids
	# visible stripes while keeping the backdrop to one inexpensive draw call.
	var image: Image = Image.create(1, 256, false, Image.FORMAT_RGBA8)
	var top: Color = Color(_world_profile.get("sky_top", Color8(72, 101, 110)))
	var bottom: Color = Color(_world_profile.get("sky_bottom", Color8(190, 166, 132)))
	for row in range(256):
		image.set_pixel(0, row, top.lerp(bottom, float(row) / 255.0))
	_sky_gradient_texture = ImageTexture.create_from_image(image)

func _process(delta: float) -> void:
	_redraw_elapsed += delta
	var screen_state: String = _current_screen_state()
	var state_changed: bool = screen_state != _last_screen_state
	# The preview's quay touches the camera-transformed road. Refresh that
	# seam on each rendered frame so it cannot lag behind during a landing.
	if not state_changed and not is_instance_valid(_route_surface_override) and _redraw_elapsed < REDRAW_INTERVAL_S:
		return
	var elapsed_for_redraw: float = _redraw_elapsed
	_redraw_elapsed = 0.0
	var camera := get_viewport().get_camera_2d()
	var camera_x: float = camera.global_position.x if camera != null else 0.0
	var camera_y: float = camera.global_position.y if camera != null else 0.0
	var zoom_y: float = camera.zoom.y if camera != null else 1.0
	if state_changed:
		_last_screen_state = screen_state
	# Redraw on vertical camera motion too: jumps move the road through the
	# viewport even when horizontal travel is momentarily slow.
	if state_changed or absf(camera_x - _last_draw_camera_x) >= 1.0 or absf(camera_y - _last_draw_camera_y) >= 1.0 or absf(zoom_y - _last_draw_zoom_y) >= 0.002:
		_atmosphere_time_s += elapsed_for_redraw
		_last_draw_camera_x = camera_x
		_last_draw_camera_y = camera_y
		_last_draw_zoom_y = zoom_y
		queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _current_screen_state() -> String:
	var scene_root: Node = get_parent().get_parent()
	if scene_root == null:
		return ""
	var state_value: Variant = scene_root.get("screen_state")
	return state_value if state_value is String else ""

func _draw() -> void:
	if not _first_draw_reported:
		_first_draw_reported = true
		if QA_DIAGNOSTICS.enabled():
			print("[PERF] backdrop_first_draw_ms=%d" % Time.get_ticks_msec())
	var size: Vector2 = get_size()
	var width: float = size.x
	var height: float = size.y
	var camera := get_viewport().get_camera_2d()
	var camera_x: float = camera.global_position.x if camera != null else 0.0
	var screen_state: String = _current_screen_state()
	if screen_state == "MENU":
		_draw_main_menu_background(width, height)
		return
	if screen_state == "GARAGE":
		_draw_workshop_background(width, height)
		return
	_quay_gap_screen = Vector2(INF, INF)
	if _route_surface_override is AmsterdamPreviewCourse:
		var course: AmsterdamPreviewCourse = _route_surface_override as AmsterdamPreviewCourse
		var gap: Vector2 = course.quay_visible_gap_world_bounds(camera_x)
		var canvas: Transform2D = course.get_global_transform_with_canvas()
		_quay_gap_screen = Vector2((canvas * Vector2(gap.x, 0.0)).x, (canvas * Vector2(gap.y, 0.0)).x)
	var scroll: float = camera_x * 0.16
	var route_meter: float = maxf(0.0, (camera_x - 340.0) / PIXELS_PER_METER - 22.0)
	var route_progress: float = clampf(route_meter / maxf(1.0, route_length_m), 0.0, 1.0)
	var profile: Dictionary = _world_profile
	var sky_top: Color = Color(profile["sky_top"])
	if _sky_gradient_texture != null:
		draw_texture_rect(_sky_gradient_texture, Rect2(0.0, 0.0, width, height), false)
	else:
		draw_rect(Rect2(0.0, 0.0, width, height), sky_top)
	draw_circle(Vector2(width * 0.78, height * 0.20), 42.0, Color8(255, 218, 142, 224))
	_draw_cloud(Vector2(width * 0.16 - fposmod(scroll * 0.35, width + 160.0), height * 0.20), 1.0)
	_draw_cloud(Vector2(width * 0.61 - fposmod(scroll * 0.23 + 280.0, width + 180.0), height * 0.31), 0.74)
	if not final_rescue_mode:
		_draw_route_water_underlay(width, height)
	_draw_atmosphere(width, height, scroll)
	_draw_amsterdam_art_layers(width, height, route_progress)
	if not final_rescue_mode:
		_draw_amsterdam_quay_wall(width, height)
	else:
		_draw_region_landmarks(width, height, camera_x)

func _draw_cloud(center: Vector2, scale: float) -> void:
	var cloud_color := Color(0.87, 0.93, 0.94, 0.34)
	draw_circle(center + Vector2(-18.0, 2.0) * scale, 11.0 * scale, cloud_color)
	draw_circle(center + Vector2(-4.0, -4.0) * scale, 15.0 * scale, cloud_color)
	draw_circle(center + Vector2(12.0, 1.0) * scale, 11.5 * scale, cloud_color)
	draw_rect(Rect2(center + Vector2(-20.0, 1.0) * scale, Vector2(35.0, 12.0) * scale), cloud_color)

func _draw_amsterdam_quay_wall(width: float, height: float) -> void:
	# Screen-space foundation follows the actual road line. Keeping this continuous
	# under the camera's visible rectangle prevents the old world-window estimate
	# from exposing a plain teal gap at the side of the track.
	var road_points: PackedVector2Array = _road_screen_samples(width)
	if road_points.size() < 2:
		return
	var wall_start: float = 29.0 if _route_surface_override is AmsterdamPreviewCourse else 46.0
	var wall_top := PackedVector2Array()
	var lock_course: AmsterdamPreviewCourse = _route_surface_override as AmsterdamPreviewCourse
	var lock_canvas: Transform2D = lock_course.get_global_transform_with_canvas() if lock_course != null else Transform2D.IDENTITY
	var lock_inverse: Transform2D = lock_canvas.affine_inverse()
	for point in road_points:
		# Keep the screen-space wall profile above its bottom edge even while the
		# camera follows a high jump. Without this clamp, the polygon can cross
		# itself below the viewport and fail triangulation during a steep dip.
		var offset: float = wall_start
		if lock_course != null:
			var world_x: float = (lock_inverse * point).x
			var foundation_offset: float = lock_course.lock_foundation_offset(world_x)
			if foundation_offset >= 0.0:
				offset = foundation_offset * lock_canvas.y.length()
		wall_top.append(Vector2(point.x, minf(point.y + offset, height + 1.0)))
	# The wall is clipped in screen space, but its texture uses world positions.
	var surface: CanvasItem = _route_surface_override as CanvasItem if is_instance_valid(_route_surface_override) else _get_route_surface(get_tree().current_scene) as CanvasItem
	if surface == null:
		return
	var screen_to_world: Transform2D = surface.get_global_transform_with_canvas().affine_inverse()
	var world_to_screen: Transform2D = screen_to_world.affine_inverse()
	var cap_runs: Array[PackedVector2Array] = []
	var cap := PackedVector2Array()
	for segment_index in range(wall_top.size() - 1):
		var midpoint: float = (wall_top[segment_index].x + wall_top[segment_index + 1].x) * 0.5
		if midpoint > _quay_gap_screen.x and midpoint < _quay_gap_screen.y:
			if cap.size() >= 2:
				cap_runs.append(cap)
			cap = PackedVector2Array()
			continue
		if cap.is_empty():
			cap.append(wall_top[segment_index])
		cap.append(wall_top[segment_index + 1])
		var wall_quad := PackedVector2Array([
			wall_top[segment_index], wall_top[segment_index + 1],
			Vector2(wall_top[segment_index + 1].x, height + 2.0),
			Vector2(wall_top[segment_index].x, height + 2.0)
		])
		var uv := PackedVector2Array()
		for point in wall_quad:
			uv.append((screen_to_world * point) / 294.0)
		draw_colored_polygon(wall_quad, Color.WHITE, uv, AMSTERDAM_QUAY_BRICK_TILE)
	# One worn stone coping visually joins the cobbled roadway to the wall.
	if cap.size() >= 2:
		cap_runs.append(cap)
	for run in cap_runs:
		draw_polyline(run, Color8(71, 64, 53, 255), 13.0, true)
		draw_polyline(run, Color8(151, 139, 112, 255), 8.0, true)
		draw_polyline(run, Color8(196, 177, 139, 210), 1.7, true)
	# Mooring rings, ivy and drainage holes are fixed to the masonry.
	const DETAIL_SPACING: float = 188.0
	var first_detail: int = floori((screen_to_world * Vector2.ZERO).x / DETAIL_SPACING)
	var last_detail: int = ceili((screen_to_world * Vector2(width, 0.0)).x / DETAIL_SPACING)
	var scale: float = world_to_screen.x.length()
	for detail_index in range(first_detail, last_detail + 1):
		var x: float = (world_to_screen * Vector2(float(detail_index) * DETAIL_SPACING, 0.0)).x
		if x > _quay_gap_screen.x and x < _quay_gap_screen.y:
			continue
		if x < 0.0 or x > width:
			continue
		var detail_offset: float = wall_start
		if lock_course != null:
			var foundation_offset: float = lock_course.lock_foundation_offset((screen_to_world * Vector2(x, 0.0)).x)
			if foundation_offset >= 0.0:
				detail_offset = foundation_offset * scale
		var y: float = _road_screen_y_at_screen_x(x, width, road_points, height) + detail_offset
		var origin := Vector2(x, y + 14.0 * scale)
		if origin.y >= height:
			continue
		match posmod(detail_index, 3):
			0:
				draw_circle(origin, 6.5 * scale, Color8(74, 57, 42, 150))
				draw_circle(origin, 2.0 * scale, Color8(161, 133, 94))
				var ring_center := origin + Vector2(0.0, 6.0 * scale)
				draw_arc(ring_center, 4.8 * scale, 0.0, TAU, 12, Color8(43, 43, 33), 2.4 * scale, true)
				draw_arc(ring_center, 4.1 * scale, 2.8, 4.8, 6, Color8(175, 143, 96), scale, true)
			1:
				var stem := PackedVector2Array()
				for leaf_index in range(7):
					var leaf := origin + Vector2(sin(float(leaf_index) * 2.1 + detail_index) * 4.5, float(leaf_index) * 6.0) * scale
					stem.append(leaf)
					draw_circle(leaf + Vector2(-2.0, 0.0) * scale, 2.7 * scale, Color8(59, 78, 37))
					draw_circle(leaf + Vector2(2.0, -1.0) * scale, 2.0 * scale, Color8(113, 128, 60))
				draw_polyline(stem, Color8(65, 85, 40), 1.2 * scale, true)
			2:
				var drain := origin + Vector2(0.0, 17.0 * scale)
				draw_line(drain, drain + Vector2(-3.0, 19.0) * scale, Color8(48, 58, 47, 135), 6.0 * scale, true)
				draw_circle(drain, 4.3 * scale, Color8(103, 100, 78))
				draw_circle(drain, 2.9 * scale, Color8(36, 44, 37))

func _cover_source(source_size: Vector2, width: float, height: float) -> Rect2:
	var view_aspect: float = width / maxf(1.0, height)
	var source_aspect: float = source_size.x / maxf(1.0, source_size.y)
	var source := Rect2(Vector2.ZERO, source_size)
	if source_aspect > view_aspect:
		source.size.x = source_size.y * view_aspect
		source.position.x = (source_size.x - source.size.x) * 0.5
	else:
		source.size.y = source_size.x / view_aspect
		source.position.y = (source_size.y - source.size.y) * 0.5
	return source

func _draw_main_menu_background(width: float, height: float) -> void:
	var screen := Rect2(0.0, 0.0, width, height)
	if _menu_art == null:
		draw_texture_rect(_sky_gradient_texture, screen, false, Color8(115, 125, 125))
		return
	draw_texture_rect_region(_menu_art, screen, _cover_source(_menu_art.get_size(), width, height), Color.WHITE)
	for band in range(18):
		var band_width: float = width * 0.39 / 18.0
		draw_rect(Rect2(float(band) * band_width, 0.0, band_width + 1.0, height), Color(0.04, 0.025, 0.02, 0.52 * (1.0 - float(band) / 18.0)))

func _draw_workshop_background(width: float, height: float) -> void:
	var source_size: Vector2 = AMSTERDAM_WORKSHOP_ART.get_size()
	var source: Rect2 = _cover_source(source_size, width, height)
	draw_texture_rect_region(AMSTERDAM_WORKSHOP_ART, Rect2(0.0, 0.0, width, height), source, Color.WHITE)
	var art_scale: float = width / source.size.x
	_draw_workshop_atmosphere(source, source_size, art_scale)
	# Match the four edges of the open bay in the source illustration.
	# Applying the same crop as the workshop keeps the masonry and jambs fixed.
	var bay_outline := PackedVector2Array([
		Vector2(0.521, 0.273), Vector2(0.859, 0.228),
		Vector2(0.859, 0.686), Vector2(0.521, 0.664)
	])
	var bay_points := PackedVector2Array()
	for point in bay_outline:
		bay_points.append((point * source_size - source.position) * art_scale)
	if _workshop_view != null:
		var bay_uv := PackedVector2Array([
			Vector2(0.30, 0.03), Vector2(0.94, 0.03),
			Vector2(0.94, 0.96), Vector2(0.30, 0.96)
		])
		draw_polygon(bay_points, PackedColorArray([Color(0.72, 0.79, 0.89)]), bay_uv, _workshop_view)
		_draw_workshop_window(source, source_size, art_scale, _workshop_view)
	var progress=get_node_or_null("../..")
	var completed:Array[String]=[]
	var current:String=String(active_world.get("id","amsterdam"))
	if is_instance_valid(progress) and progress.has_method("is_world_completed"):
		for index in range(CAMPAIGN_DATA.CAMPAIGN_WORLDS.size()):
			if progress.is_world_completed(index):completed.append(String(CAMPAIGN_DATA.CAMPAIGN_WORLDS[index].id))
	preload("res://scripts/journey_poster.gd").draw(self,workshop_poster_rect(Vector2(width,height)),current,completed)
	# A restrained cool tint keeps the high-detail art readable beneath the car
	# and the workshop controls without flattening its harbor lighting.
	draw_rect(Rect2(0.0, 0.0, width, height), Color(0.025, 0.055, 0.065, 0.12))

func workshop_poster_rect(view_size:Vector2) -> Rect2:
	var source_size:Vector2=AMSTERDAM_WORKSHOP_ART.get_size()
	var source:Rect2=_cover_source(source_size,view_size.x,view_size.y)
	var scale_factor:float=view_size.x/source.size.x
	return Rect2((source_size*Vector2(.421,.267)-source.position)*scale_factor,source_size*Vector2(.052,.136)*scale_factor)

func _draw_workshop_window(source: Rect2, source_size: Vector2, art_scale: float, exterior: Texture2D) -> void:
	# Glass panes in pixels of the 1672 × 941 illustration.
	# Leave the mullions and the ivy on the outer edge in the original painting.
	var columns := PackedFloat32Array([551.0, 585.0, 618.0, 644.0, 666.0])
	var rows := PackedFloat32Array([288.0, 344.0, 403.0, 483.0])
	var image_scale: Vector2 = source_size / Vector2(1672.0, 941.0)
	var arch_top := PackedFloat32Array([236.0, 232.0, 240.0, 255.0, 278.0])
	for column in range(columns.size() - 1):
		var left: float = columns[column] + 3.0
		var right: float = columns[column + 1] - 3.0
		_draw_workshop_pane(PackedVector2Array([
			Vector2(left, arch_top[column]), Vector2(right, arch_top[column + 1]),
			Vector2(right, 285.0), Vector2(left, 285.0)
		]), source, image_scale, art_scale, exterior)
	for row in range(rows.size() - 1):
		for column in range(columns.size() - 1):
			var left: float = columns[column] + 3.0
			var right: float = columns[column + 1] - 3.0
			var top: float = rows[row] + 3.0
			var bottom: float = rows[row + 1] - 3.0
			_draw_workshop_pane(PackedVector2Array([
				Vector2(left, top), Vector2(right, top), Vector2(right, bottom), Vector2(left, bottom)
			]), source, image_scale, art_scale, exterior)

func _draw_workshop_pane(outline: PackedVector2Array, source: Rect2, image_scale: Vector2, art_scale: float, exterior: Texture2D) -> void:
	var pane := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in outline:
		pane.append((point * image_scale - source.position) * art_scale)
		uv.append(Vector2(0.42, 0.05) + (point - Vector2(551.0, 230.0)) * Vector2(0.00155, 0.0033))
	draw_polygon(pane, PackedColorArray([Color(0.39, 0.47, 0.58)]), uv, exterior)

func _draw_amsterdam_art_layers(width: float, height: float, route_progress: float) -> void:
	if active_world_index != 0 or final_rescue_mode:
		return
	var road_screen_y: float = _road_screen_y(height)
	var progress: float = clampf(route_progress, 0.0, 1.0)
	# Let the new wide daytime canal art drift enough to reveal more of the
	# houses and bridge during this short route without repeating or stretching it.
	var art_ratio: float = float(AMSTERDAM_CANAL_ART.get_width()) / float(AMSTERDAM_CANAL_ART.get_height())
	var city_width: float = maxf(maxf(width * 1.35, 1728.0), (height + AMSTERDAM_PANORAMA_BOTTOM_OFFSET - AMSTERDAM_PANORAMA_TOP_COVER) * art_ratio)
	var parallax_travel: float = maxf(0.0, city_width - width)
	var city_x: float = -progress * parallax_travel
	# Keep one continuous Amsterdam panorama for the complete route. Swapping to
	# a second full image mid-run made the city look like a floating, repeated
	# picture layer; road, quay and foreground structures provide the variation.
	# Preserve the panorama's aspect ratio. Hold its top edge outside the screen
	# during a jump; the canal fill below it expands down to the moving road line.
	# This gives the camera room without stretching or exposing the image border.
	var panorama_height: float = city_width / art_ratio
	var panorama_top: float = minf(road_screen_y + AMSTERDAM_PANORAMA_BOTTOM_OFFSET - panorama_height, AMSTERDAM_PANORAMA_TOP_COVER)
	var panorama_bottom: float = panorama_top + panorama_height
	draw_texture_rect(AMSTERDAM_CANAL_ART, Rect2(city_x, panorama_top, city_width, panorama_height), false)
	var barge_visible: bool = _quay_gap_screen.x < width and _quay_gap_screen.y > 0.0
	if barge_visible:
		_draw_barge_water_extension(width, height, city_x, city_width, panorama_height, panorama_bottom)
		return
	if _amsterdam_panorama_fade_texture != null:
		var fade_height: float = minf(AMSTERDAM_PANORAMA_FADE_HEIGHT, panorama_height)
		draw_texture_rect(_amsterdam_panorama_fade_texture, Rect2(city_x, panorama_bottom - fade_height, city_width, fade_height), false)
	_draw_canal_atmosphere(width, height, panorama_top, panorama_height, road_screen_y)
	_draw_amsterdam_water_gap(width, height, panorama_bottom)

func _draw_barge_water_extension(width: float, height: float, city_x: float, city_width: float, panorama_height: float, bottom: float) -> void:
	# Reflect only the panorama's water strip vertically, keeping its natural
	# scale and horizontal alignment. This fills the open canal under the boat.
	var strip_height: float = panorama_height * 0.17
	var y: float = bottom
	var reverse: bool = true
	while y < height + 1.0:
		var uv_top: float = 1.0 if reverse else 0.83
		var uv_bottom: float = 0.83 if reverse else 1.0
		var points := PackedVector2Array([
			Vector2(0.0, y - 0.5), Vector2(width, y - 0.5),
			Vector2(width, y + strip_height), Vector2(0.0, y + strip_height)
		])
		var uv := PackedVector2Array([
			Vector2(-city_x / city_width, uv_top), Vector2((width - city_x) / city_width, uv_top),
			Vector2((width - city_x) / city_width, uv_bottom), Vector2(-city_x / city_width, uv_bottom)
		])
		draw_polygon(points, PackedColorArray([Color.WHITE]), uv, AMSTERDAM_CANAL_ART)
		y += strip_height
		reverse = not reverse

func _draw_amsterdam_water_gap(width: float, height: float, panorama_bottom_y: float) -> void:
	var road_points: PackedVector2Array = _road_screen_samples(width)
	if road_points.size() < 2:
		return
	var wall_start: float = 29.0 if _route_surface_override is AmsterdamPreviewCourse else 46.0
	var fill_color: Color = Color8(27, 75, 80)
	var highlight_color: Color = Color8(128, 171, 158, 118)
	var warm_reflection: Color = Color8(206, 143, 78, 92)
	for segment_index in range(road_points.size() - 1):
		var point_a: Vector2 = road_points[segment_index]
		var point_b: Vector2 = road_points[segment_index + 1]
		var top_y: float = clampf(panorama_bottom_y, 0.0, height + 1.0)
		var bottom_a: float = clampf(point_a.y + wall_start, top_y, height + 1.0)
		var bottom_b: float = clampf(point_b.y + wall_start, top_y, height + 1.0)
		var gap_a: float = bottom_a - top_y
		var gap_b: float = bottom_b - top_y
		if maxf(gap_a, gap_b) < 1.0:
			continue
		var gap_polygon := PackedVector2Array()
		if gap_a < 1.0:
			gap_polygon = PackedVector2Array([
				Vector2(point_a.x, top_y), Vector2(point_b.x, top_y), Vector2(point_b.x, bottom_b)
			])
		elif gap_b < 1.0:
			gap_polygon = PackedVector2Array([
				Vector2(point_a.x, top_y), Vector2(point_b.x, top_y), Vector2(point_a.x, bottom_a)
			])
		else:
			gap_polygon = PackedVector2Array([
				Vector2(point_a.x, top_y), Vector2(point_b.x, top_y),
				Vector2(point_b.x, bottom_b), Vector2(point_a.x, bottom_a)
			])
		draw_colored_polygon(gap_polygon, fill_color)
		# Short irregular glints echo the reflective canal in the reference image
		# without introducing another repeated panorama or a straight colored band.
		var ripple_x: float = point_a.x + (point_b.x - point_a.x) * 0.28
		var ripple_y: float = top_y + 7.0 + float(segment_index % 4) * 5.0
		if ripple_y + 2.0 < minf(bottom_a, bottom_b):
			var ripple_end: float = minf(point_b.x - 2.0, ripple_x + 10.0 + float(segment_index % 3) * 5.0)
			draw_line(Vector2(ripple_x, ripple_y), Vector2(ripple_end, ripple_y + 1.0), highlight_color, 1.4, true)
		if segment_index % 5 == 1 and ripple_y + 10.0 < minf(bottom_a, bottom_b):
			draw_line(Vector2(ripple_x + 4.0, ripple_y + 8.0), Vector2(minf(point_b.x - 2.0, ripple_x + 18.0), ripple_y + 9.0), warm_reflection, 1.8, true)

func _draw_route_water_underlay(width: float, height: float) -> void:
	# Extend the canal beneath the panorama down to the real road profile across
	# the whole screen. The previous flat rectangle exposed a hard teal slab when
	# a hill descended away from the car. Terrain is drawn later and masks the
	# lower edge, so these water reflections remain behind the road itself.
	var road_points: PackedVector2Array = _road_screen_samples(width)
	var waterline: float = clampf(_road_screen_y(height) - 14.0, 0.0, height)
	var base_color: Color = Color8(20, 49, 52)
	if road_points.size() >= 2:
		# Convex pieces cannot self-intersect as steep hills cross the waterline.
		for i in range(road_points.size() - 1):
			var left: Vector2 = road_points[i]
			var right: Vector2 = road_points[i + 1]
			var bottom_left: float = maxf(waterline, left.y + 5.0)
			var bottom_right: float = maxf(waterline, right.y + 5.0)
			if right.x - left.x < 0.01 or maxf(bottom_left, bottom_right) - waterline < 0.01:
				continue
			var piece := PackedVector2Array([Vector2(left.x, waterline), Vector2(right.x, waterline)])
			if bottom_right > waterline + 0.01:
				piece.append(Vector2(right.x, bottom_right))
			if bottom_left > waterline + 0.01:
				piece.append(Vector2(left.x, bottom_left))
			draw_colored_polygon(piece, base_color)
	else:
		draw_rect(Rect2(0.0, waterline, width, height - waterline), base_color)
	# Warm reflections and staggered ripples continue the light pattern from the
	# canal artwork, replacing the single-color gap with readable water depth.
	var ripple_colors: Array[Color] = [Color(0.55, 0.70, 0.67, 0.24), Color(0.90, 0.57, 0.30, 0.20), Color(0.39, 0.60, 0.60, 0.18)]
	for ripple_index in range(34):
		var ripple_x: float = fposmod(float(ripple_index) * 91.0 + _atmosphere_time_s * (15.0 + float(ripple_index % 5) * 4.0), width + 150.0) - 75.0
		var ripple_y: float = waterline + 18.0 + fposmod(float(ripple_index * 47), maxf(30.0, height - waterline - 8.0))
		var road_y_at_ripple: float = _road_screen_y_at_screen_x(ripple_x, width, road_points, height)
		if ripple_y + 8.0 < road_y_at_ripple:
			var ripple_width: float = 24.0 + float((ripple_index * 29) % 73)
			var color: Color = ripple_colors[ripple_index % ripple_colors.size()]
			draw_line(Vector2(ripple_x, ripple_y), Vector2(minf(width, ripple_x + ripple_width), ripple_y + 1.0), color, 1.2, true)
	# Broken vertical glints read as distant lamps reflected in the water.
	for reflection_index in range(8):
		var reflection_x: float = fposmod(float(reflection_index) * 173.0 + _atmosphere_time_s * 9.0, width + 80.0) - 40.0
		var reflection_y: float = waterline + 10.0
		var reflection_bottom: float = minf(_road_screen_y_at_screen_x(reflection_x, width, road_points, height) - 10.0, reflection_y + 80.0)
		if reflection_bottom > reflection_y:
			draw_line(Vector2(reflection_x, reflection_y), Vector2(reflection_x + 2.0, reflection_bottom), Color(1.0, 0.61, 0.30, 0.10), 2.0, true)

var _road_samples_frame := -1
var _road_samples_width := 0.0
var _road_samples_cache := PackedVector2Array()

func _road_screen_samples(width: float) -> PackedVector2Array:
	var render_frame: int = Engine.get_process_frames()
	if render_frame == _road_samples_frame and is_equal_approx(width, _road_samples_width):
		return _road_samples_cache
	var points := PackedVector2Array()
	var scene_root: Node = get_tree().current_scene
	var terrain: Node = _route_surface_override if is_instance_valid(_route_surface_override) else _get_route_surface(scene_root)
	var terrain_canvas_item: CanvasItem = terrain as CanvasItem
	if terrain == null or terrain_canvas_item == null or not terrain.has_method("height_at"):
		return points
	var canvas_transform: Transform2D = terrain_canvas_item.get_global_transform_with_canvas()
	var inverse_transform: Transform2D = canvas_transform.affine_inverse()
	const SAMPLE_COUNT: int = 40
	var sample_xs: Array[float] = []
	for sample_index in range(SAMPLE_COUNT + 1):
		sample_xs.append(width * float(sample_index) / float(SAMPLE_COUNT))
	for edge in [_quay_gap_screen.x, _quay_gap_screen.y]:
		if edge > 0.0 and edge < width:
			sample_xs.append(edge)
	if terrain is AmsterdamPreviewCourse:
		for world_x in terrain.lock_foundation_breaks():
			var edge: float = (canvas_transform * Vector2(world_x, 0.0)).x
			if edge > 0.0 and edge < width:
				sample_xs.append(edge - 0.01)
				sample_xs.append(edge + 0.01)
	sample_xs.sort()
	for screen_x in sample_xs:
		var world_at_screen_edge: Vector2 = inverse_transform * Vector2(screen_x, 0.0)
		var road_world_y: float = terrain._base_height_at(world_at_screen_edge.x) if terrain is AmsterdamPreviewCourse else float(terrain.call("height_at", world_at_screen_edge.x))
		points.append(canvas_transform * Vector2(world_at_screen_edge.x, road_world_y))
	_road_samples_frame = render_frame
	_road_samples_width = width
	_road_samples_cache = points
	return points

func _road_screen_y_at_screen_x(screen_x: float, _width: float, road_points: PackedVector2Array, fallback_y: float) -> float:
	if road_points.size() < 2:
		return _road_screen_y(fallback_y)
	for index in range(road_points.size() - 1):
		var a: Vector2 = road_points[index]
		var b: Vector2 = road_points[index + 1]
		if screen_x <= b.x and b.x > a.x:
			return lerpf(a.y, b.y, clampf((screen_x - a.x) / (b.x - a.x), 0.0, 1.0))
	return road_points[-1].y

func _road_screen_y(height: float) -> float:
	var scene_root: Node = get_tree().current_scene
	var wagon: Node2D = _wagon_override if is_instance_valid(_wagon_override) else null
	if wagon == null and scene_root != null:
		wagon = scene_root.get_node_or_null("Wagon") as Node2D
	if wagon == null and scene_root != null:
		wagon = scene_root.find_child("Wagon", true, false) as Node2D
	var terrain: Node = _route_surface_override if is_instance_valid(_route_surface_override) else _get_route_surface(scene_root)
	if wagon != null and terrain != null and terrain.has_method("height_at"):
		var road_world_y: float = terrain.panorama_anchor_height_at(wagon.global_position.x) if terrain is AmsterdamPreviewCourse else float(terrain.call("height_at", wagon.global_position.x))
		# The background is a fixed CanvasLayer; mapping the road through the
		# terrain's canvas transform accounts for camera zoom, viewport scaling,
		# and any camera offset exactly as the visible road is transformed.
		var terrain_canvas_item: CanvasItem = terrain as CanvasItem
		if terrain_canvas_item != null:
			return (terrain_canvas_item.get_global_transform_with_canvas() * Vector2(wagon.global_position.x, road_world_y)).y
	var camera := get_viewport().get_camera_2d()
	var camera_y: float = camera.global_position.y if camera != null else 405.0
	var zoom_y: float = camera.zoom.y if camera != null else 1.0
	var road_world_y: float = 526.0
	return height * 0.5 + (road_world_y - camera_y) * zoom_y

func _get_route_surface(scene_root: Node) -> Node:
	if scene_root == null:
		return null
	var surface: Node = scene_root.get_node_or_null("Terrain")
	if surface == null:
		surface = scene_root.get_node_or_null("Course")
	# PC preview and QA scenes may wrap the actual game scene one level down.
	# Find that same real route surface instead of falling back to a fixed screen
	# height, which detached the panorama and quay wall from the driving track.
	if surface == null:
		surface = scene_root.find_child("Terrain", true, false)
	if surface == null:
		surface = scene_root.find_child("Course", true, false)
	return surface

func _draw_route_panorama(texture: Texture2D, x: float, width: float, road_screen_y: float, opacity: float, top_fraction: float = 0.18, bottom_fraction: float = 0.845, bottom_offset: float = 0.0, fill_viewport_top: bool = false) -> void:
	if opacity <= 0.005:
		return
	# Use the complete authored image region, then align its water/ground edge
	# with the actual road line so none of the lower environment is cut away.
	var source_top: float = float(texture.get_height()) * top_fraction
	var source_height: float = float(texture.get_height()) * (bottom_fraction - top_fraction)
	var source := Rect2(0.0, source_top, float(texture.get_width()), source_height)
	var destination_height: float = width * source_height / float(texture.get_width())
	var destination_top: float = road_screen_y + bottom_offset - destination_height
	if fill_viewport_top:
		# Stretch only the panorama's vertical span to the top of the viewport. The
		# earlier aspect-preserving strip left a hard horizontal seam in the sky.
		destination_top = 0.0
		destination_height = maxf(1.0, road_screen_y + bottom_offset)
	var destination := Rect2(x, destination_top, width, destination_height)
	draw_texture_rect_region(texture, destination, source, Color(1.0, 1.0, 1.0, opacity))

func _profile_for_world() -> Dictionary:
	var sky_top: Color = Color8(73, 157, 218)
	var sky_bottom: Color = Color8(169, 207, 225)
	var far_hills: Color = Color8(100, 135, 142)
	var near_hills: Color = Color8(79, 110, 105)
	var world_id: String = String(active_world.get("id", ""))
	var atmosphere: Dictionary = CAMPAIGN_DATA.WORLD_ATMOSPHERE_PROFILES.get(world_id, {"kind": "clear", "intensity": 0.0})
	if final_rescue_mode:
		atmosphere = {"kind": "storm", "intensity": 0.72}
	var atmosphere_kind: String = String(atmosphere.get("kind", "clear"))
	var atmosphere_intensity: float = clampf(float(atmosphere.get("intensity", 0.0)), 0.0, 1.0)
	match atmosphere_kind:
		"mist":
			sky_top = sky_top.lerp(Color8(155, 179, 177), 0.16 + atmosphere_intensity * 0.18)
			sky_bottom = sky_bottom.lerp(Color8(203, 196, 171), 0.12 + atmosphere_intensity * 0.14)
			far_hills = far_hills.lerp(Color8(131, 151, 142), 0.12 + atmosphere_intensity * 0.14)
		"rain":
			sky_top = sky_top.lerp(Color8(66, 89, 103), 0.15 + atmosphere_intensity * 0.18)
			sky_bottom = sky_bottom.lerp(Color8(142, 155, 156), 0.15 + atmosphere_intensity * 0.14)
			far_hills = far_hills.darkened(0.08 + atmosphere_intensity * 0.12)
		"dust":
			sky_top = sky_top.lerp(Color8(132, 112, 83), 0.08 + atmosphere_intensity * 0.12)
			sky_bottom = sky_bottom.lerp(Color8(235, 172, 101), 0.14 + atmosphere_intensity * 0.20)
			far_hills = far_hills.lerp(Color8(173, 136, 82), 0.12 + atmosphere_intensity * 0.18)
		"sea_haze":
			sky_top = sky_top.lerp(Color8(90, 143, 151), 0.14 + atmosphere_intensity * 0.20)
			sky_bottom = sky_bottom.lerp(Color8(202, 197, 170), 0.12 + atmosphere_intensity * 0.16)
			far_hills = far_hills.lerp(Color8(105, 139, 139), 0.14 + atmosphere_intensity * 0.18)
		"heat":
			sky_top = sky_top.lerp(Color8(132, 111, 79), 0.06 + atmosphere_intensity * 0.10)
			sky_bottom = sky_bottom.lerp(Color8(240, 172, 96), 0.15 + atmosphere_intensity * 0.22)
			far_hills = far_hills.lerp(Color8(176, 132, 77), 0.12 + atmosphere_intensity * 0.16)
		"smoke":
			sky_top = sky_top.lerp(Color8(98, 111, 110), 0.14 + atmosphere_intensity * 0.20)
			sky_bottom = sky_bottom.lerp(Color8(161, 156, 143), 0.14 + atmosphere_intensity * 0.18)
			far_hills = far_hills.lerp(Color8(106, 115, 104), 0.12 + atmosphere_intensity * 0.18)
		"storm":
			sky_top = sky_top.lerp(Color8(51, 74, 90), 0.24 + atmosphere_intensity * 0.24)
			sky_bottom = sky_bottom.lerp(Color8(122, 139, 147), 0.18 + atmosphere_intensity * 0.18)
			far_hills = far_hills.lerp(Color8(84, 105, 111), 0.18 + atmosphere_intensity * 0.18)
	return {
		"scenery": "amsterdam_canal",
		"sky_top": sky_top,
		"sky_bottom": sky_bottom,
		"far_hills": far_hills,
		"near_hills": near_hills,
		"atmosphere": atmosphere_kind,
		"atmosphere_intensity": atmosphere_intensity
	}

func _draw_atmosphere(width: float, height: float, scroll: float) -> void:
	var atmosphere_kind: String = String(_world_profile.get("atmosphere", "clear"))
	var intensity: float = float(_world_profile.get("atmosphere_intensity", 0.0))
	if intensity <= 0.01 or atmosphere_kind == "clear":
		return
	match atmosphere_kind:
		"mist":
			_draw_horizon_mist(width, height, intensity, scroll, Color8(190, 205, 189))
		"rain":
			_draw_rain(width, height, intensity, scroll)
		"dust":
			_draw_dust(width, height, intensity, scroll)
		"sea_haze":
			_draw_sea_haze(width, height, intensity, scroll)
		"heat":
			_draw_heat_haze(width, height, intensity, scroll)
		"smoke":
			_draw_smoke_haze(width, height, intensity, scroll)
		"storm":
			draw_rect(Rect2(0.0, 0.0, width, height * 0.82), Color(0.08, 0.13, 0.17, 0.12 * intensity))
			_draw_horizon_mist(width, height, intensity, scroll, Color8(157, 181, 187))
			_draw_rain(width, height, intensity, scroll)

func _draw_horizon_mist(width: float, height: float, intensity: float, scroll: float, color: Color) -> void:
	for band in range(3):
		var band_width: float = width * (0.74 + float(band) * 0.09)
		var drift: float = fposmod(scroll * (0.035 + float(band) * 0.012) + _atmosphere_time_s * (5.0 + float(band)), width + band_width) - band_width
		var y: float = height * (0.57 + float(band) * 0.055)
		var band_color: Color = color
		band_color.a = 0.16 * intensity * (1.0 - float(band) * 0.16)
		draw_rect(Rect2(drift, y, band_width, height * 0.045), band_color)

func _draw_rain(width: float, height: float, intensity: float, scroll: float) -> void:
	var drop_count: int = 48 + int(round(intensity * 84.0))
	for drop_index in range(drop_count):
		var seed: float = float(drop_index)
		var x: float = fposmod(seed * 83.0 + _atmosphere_time_s * 148.0 + scroll * 0.10, width + 80.0) - 40.0
		var y: float = fposmod(seed * 137.0 + _atmosphere_time_s * 224.0, height * 0.84 + 80.0) - 40.0
		var alpha: float = 0.18 + intensity * 0.34 + float(drop_index % 3) * 0.018
		draw_line(Vector2(x, y), Vector2(x - 8.0, y + 20.0), Color(0.72, 0.81, 0.82, alpha), 1.3)

func _draw_dust(width: float, height: float, intensity: float, scroll: float) -> void:
	var veil_color: Color = Color(0.73, 0.55, 0.34, 0.16 * intensity)
	draw_rect(Rect2(0.0, height * 0.55, width, height * 0.22), veil_color)
	var mote_count: int = 16 + int(round(intensity * 52.0))
	for mote_index in range(mote_count):
		var seed: float = float(mote_index)
		var x: float = fposmod(seed * 127.0 + scroll * 0.08 + _atmosphere_time_s * 18.0, width + 32.0) - 16.0
		var y: float = height * (0.56 + fposmod(seed * 0.137 + _atmosphere_time_s * 0.006, 0.20))
		var radius: float = 1.5 + float(mote_index % 3) * 0.65
		draw_circle(Vector2(x, y), radius, Color(0.90, 0.73, 0.49, 0.20 + intensity * 0.18))

func _draw_sea_haze(width: float, height: float, intensity: float, scroll: float) -> void:
	var haze_color: Color = Color(0.56, 0.73, 0.76, 0.18 * intensity)
	draw_rect(Rect2(0.0, height * 0.55, width, height * 0.19), haze_color)
	_draw_horizon_mist(width, height, intensity * 0.82, scroll, Color8(156, 194, 194))

func _draw_heat_haze(width: float, height: float, intensity: float, scroll: float) -> void:
	var shimmer_color: Color = Color(0.91, 0.70, 0.43, 0.34 * intensity)
	draw_rect(Rect2(0.0, height * 0.60, width, height * 0.12), Color(0.83, 0.51, 0.30, 0.12 * intensity))
	for band in range(5):
		var y: float = height * (0.60 + float(band) * 0.029)
		var drift: float = fposmod(scroll * 0.05 + float(band) * 127.0 + _atmosphere_time_s * 10.0, width + 180.0) - 90.0
		var span: float = width * 0.44
		draw_line(Vector2(drift, y), Vector2(drift + span, y + sin(_atmosphere_time_s + float(band)) * 1.5), shimmer_color, 2.0)
		draw_line(Vector2(drift + span, y + sin(_atmosphere_time_s + float(band)) * 1.5), Vector2(drift + span * 2.0, y), shimmer_color, 2.0)

func _draw_smoke_haze(width: float, height: float, intensity: float, scroll: float) -> void:
	_draw_horizon_mist(width, height, intensity, scroll, Color8(166, 163, 147))
	var plume_count: int = 8 + int(round(intensity * 12.0))
	for plume_index in range(plume_count):
		var seed: float = float(plume_index)
		var x: float = fposmod(seed * 181.0 + scroll * 0.04, width + 80.0) - 40.0
		var rise: float = fposmod(seed * 0.19 + _atmosphere_time_s * 0.025, 1.0)
		var y: float = height * (0.72 - rise * 0.19)
		var radius: float = 4.0 + fposmod(seed * 1.7, 8.0)
		var plume_alpha: float = 0.055 + intensity * 0.11
		for puff in range(3):
			var puff_progress: float = float(puff) / 2.0
			var puff_radius: float = radius * (0.74 + puff_progress * 0.52)
			var puff_x: float = x + sin(seed + float(puff)) * radius * 0.8
			var puff_y: float = y - puff_progress * radius * 1.8
			draw_circle(Vector2(puff_x, puff_y), puff_radius, Color(0.62, 0.61, 0.54, plume_alpha * (1.0 - puff_progress * 0.18)))

func _draw_region_landmarks(width: float, height: float, camera_x: float) -> void:
	if not final_rescue_mode:
		return
	var rescue_meter: float = route_length_m * 0.84
	var rescue_world_x: float = (rescue_meter + CAMPAIGN_DATA.WORLD_START_OFFSET_M) * PIXELS_PER_METER
	var rescue_screen_x: float = width * 0.5 + (rescue_world_x - camera_x) * 0.12
	if rescue_screen_x < -280.0 or rescue_screen_x > width + 280.0:
		return
	draw_set_transform(Vector2(rescue_screen_x, height * 0.68), 0.0, Vector2(0.66, 0.66))
	var rescue_stone := Color8(62, 79, 83)
	var rescue_roof := Color8(81, 85, 72)
	_draw_port_crane(0.0, 0.0, rescue_stone, rescue_roof)
	_draw_rescue_ship(125.0, -12.0, Color8(178, 175, 148))
	draw_set_transform(Vector2.ZERO)
func _draw_port_crane(x: float, ground: float, stone: Color, roof: Color) -> void:
	draw_line(Vector2(x - 62.0, ground), Vector2(x - 50.0, ground - 145.0), stone, 7.0)
	draw_line(Vector2(x + 56.0, ground), Vector2(x + 44.0, ground - 145.0), stone, 7.0)
	draw_line(Vector2(x - 51.0, ground - 142.0), Vector2(x + 93.0, ground - 142.0), stone, 8.0)
	draw_line(Vector2(x + 83.0, ground - 140.0), Vector2(x + 108.0, ground - 91.0), stone, 5.0)
	draw_line(Vector2(x + 108.0, ground - 91.0), Vector2(x + 108.0, ground - 35.0), stone, 3.0)
	draw_rect(Rect2(x - 123.0, ground - 43.0, 68.0, 37.0), roof.darkened(0.12))
	draw_line(Vector2(x - 142.0, ground + 7.0), Vector2(x + 150.0, ground + 9.0), Color8(68, 108, 119), 10.0)

func _draw_rescue_ship(x: float, water_y: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(x - 68.0, water_y), Vector2(x + 78.0, water_y), Vector2(x + 56.0, water_y + 25.0), Vector2(x - 45.0, water_y + 25.0)]), color)
	draw_rect(Rect2(x - 13.0, water_y - 29.0, 53.0, 29.0), color.darkened(0.1))
	draw_rect(Rect2(x + 2.0, water_y - 42.0, 22.0, 13.0), color.lightened(0.1))
	draw_line(Vector2(x - 44.0, water_y + 31.0), Vector2(x + 69.0, water_y + 32.0), Color8(172, 188, 163), 2.0)

func _draw_canal_atmosphere(width: float, height: float, panorama_top: float, panorama_height: float, road_y: float) -> void:
	var water_top: float = maxf(height * 0.48, panorama_top + panorama_height * 0.75)
	var water_bottom: float = minf(height - 12.0, road_y - 16.0)
	if water_bottom > water_top:
		for glint in range(12):
			var x: float = fposmod(float(glint) * 137.0 + _atmosphere_time_s * 7.0, width + 60.0) - 30.0
			var y: float = lerpf(water_top, water_bottom, float((glint * 7) % 12) / 12.0)
			var alpha: float = (0.5 + 0.5 * sin(_atmosphere_time_s * 1.4 + float(glint))) * 0.12
			draw_line(Vector2(x, y), Vector2(x + 20.0 + float(glint % 3) * 9.0, y + 0.6), Color(0.85, 0.91, 0.80, alpha), 1.0, true)
	# Small distant birds stay above the skyline and never obscure the car.
	for bird in range(5):
		var x: float = fposmod(_atmosphere_time_s * 15.0 + float(bird) * 29.0 + width * 0.45, width + 180.0) - 90.0
		var y: float = height * 0.16 + sin(float(bird) * 1.9) * 13.0
		var flap: float = sin(_atmosphere_time_s * 4.0 + float(bird) * 0.8) * 2.3
		var wing: float = 4.0 + float(bird % 2)
		draw_polyline(PackedVector2Array([Vector2(x - wing, y - flap), Vector2(x - wing * 0.5, y - 1.8), Vector2(x, y), Vector2(x + wing * 0.5, y - 1.8), Vector2(x + wing, y - flap)]), Color8(44, 58, 60, 165), 1.3, true)

func _draw_workshop_atmosphere(source: Rect2, source_size: Vector2, art_scale: float) -> void:
	for lamp in [Vector2(0.434, 0.235), Vector2(0.112, 0.420), Vector2(0.239, 0.386)]:
		var position: Vector2 = (lamp * source_size - source.position) * art_scale
		var pulse: float = 0.92 + sin(_atmosphere_time_s * 1.6 + lamp.x * 5.0) * 0.08
		for ring in range(4, 0, -1):
			draw_circle(position, float(ring) * 7.0 * art_scale, Color(1.0, 0.59, 0.17, 0.009 * pulse))
	for dust in range(12):
		var x: float = source_size.x * (0.20 + fposmod(float(dust) * 0.071 + _atmosphere_time_s * 0.0015, 0.28))
		var y: float = source_size.y * (0.26 + fposmod(float(dust) * 0.053 + _atmosphere_time_s * 0.002, 0.28))
		var position: Vector2 = (Vector2(x, y) - source.position) * art_scale
		draw_circle(position, (0.65 + float(dust % 2) * 0.4) * art_scale, Color8(235, 208, 153, 45))
