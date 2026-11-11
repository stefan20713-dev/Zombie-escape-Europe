extends Node2D
## A route-owned structure. The visible falling slabs are also the contact bounds.
signal message(text: String)
signal blast(strength: float)
signal clean_pass(amount: int)

const PLUME_TIME := 0.88
const FIRE_SOURCE := Rect2(35, 98, 1198, 982)
const RUNOUT := 310.0
const FLOOR_COUNT := 4
var course: Node2D
var fire: Texture2D
var building: Texture2D
var barrel: Texture2D
var barrel_source: Rect2
var building_size: Vector2
var building_source: Rect2
var rows: PackedFloat32Array
var site_x: float
var lead: float
var fuse_time: float
var stagger: float
var slide: float
var contact_trigger: bool
var manual_trigger: bool
var floor_height: Callable
var title: String
var elapsed := -1.0
var blast_count := 0
var got_hit := false
var reward_paid := false
var _shards: Array[Dictionary] = []
var _glow := _make_glow()

func setup(route: Node2D, settings: Dictionary) -> void:
	course = route
	site_x = float(settings.meter) * DrivingTestCourse.PIXELS_PER_METER
	title = settings.title
	lead = settings.lead
	fuse_time = settings.fuse
	stagger = settings.stagger
	slide = settings.get("slide", 1.0)
	contact_trigger = settings.get("contact_trigger", false)
	manual_trigger = settings.get("manual_trigger", false)
	floor_height = settings.get("floor_height", course.height_at)
	building = _texture(settings.building)
	fire = _texture("res://assets/effects/collapse_fire.png")
	if contact_trigger:
		barrel = _texture(settings.barrel)
	barrel_source = settings.get("barrel_source", Rect2())
	building_source = settings.source
	rows = PackedFloat32Array(settings.rows)
	building_size = building_source.size * (float(settings.height) / building_source.size.y)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path, "Texture2D"):
		return load(path) as Texture2D
	var source := Image.load_from_file(path)
	source.generate_mipmaps()
	return ImageTexture.create_from_image(source)

func _make_glow() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.add_point(0.45, Color(1, 1, 1, 0.44))
	gradient.set_color(gradient.get_point_count() - 1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	return texture

func reset() -> void:
	elapsed = -1.0
	blast_count = 0
	got_hit = false
	reward_paid = false
	_shards.clear()
	queue_redraw()

func arm() -> void:
	if elapsed < 0.0:
		elapsed = 0.0

func _floor_y(x: float) -> float:
	return float(floor_height.call(x))

func _drum_rect() -> Rect2:
	var x := site_x - lead
	return Rect2(x - 28.0, _floor_y(x) - 50.0, 56.0, 50.0)

func _physics_process(delta: float) -> void:
	var car: EscapeWagon = course._wagon
	if not is_instance_valid(car) or car.freeze:
		return
	queue_redraw()
	if elapsed < 0.0:
		if manual_trigger:
			return
		var drum := _drum_rect()
		var armed := car.chassis_overlaps_world_rect(drum) if contact_trigger else car.position.x >= site_x - lead
		if not armed:
			return
		elapsed = 0.0
		message.emit(title + (" · ZÜNDSCHNUR BRENNT" if contact_trigger else " · MAUER REISST"))
	elapsed += delta
	while blast_count < 2 and elapsed >= fuse_time + blast_count * stagger:
		var point := _blast_center(blast_count)
		_explode(point, car)
		blast_count += 1
	if blast_count > 0 and not got_hit:
		for level in range(FLOOR_COUNT):
			var drop := _drop_time(level)
			if drop >= 0.0 and drop < _fall_duration(level) and car.chassis_overlaps_world_rect(_slab_rect(level).grow(-9.0)):
				_hit(car, _slab_rect(level).get_center(), 1.8, 0.93)
				break
		if elapsed >= fuse_time + 0.95 and absf(car.speed_mps) > 10.0 and car.chassis_overlaps_world_rect(_rubble_rect()):
			_hit(car, _rubble_rect().get_center(), 0.42, 0.98)
	for i in range(_shards.size() - 1, -1, -1):
		var shard := _shards[i]
		shard.age += delta
		if shard.age >= 1.5:
			_shards.remove_at(i)
			continue
		shard.v.y += 450.0 * delta
		shard.p += shard.v * delta
		shard.angle += shard.spin * delta
		var floor := _floor_y(shard.p.x) - 2.0
		if shard.p.y > floor and shard.v.y > 0.0:
			shard.p.y = floor
			shard.v *= Vector2(0.60, -0.28)
	if not reward_paid and car.position.x >= site_x + RUNOUT and elapsed >= fuse_time + stagger + PLUME_TIME:
		reward_paid = true
		if not got_hit and not manual_trigger:
			clean_pass.emit(14)
	queue_redraw()

func _hit(car: EscapeWagon, point: Vector2, damage: float, retention: float) -> void:
	got_hit = true
	car.record_damage_contact(point)
	car.hit_road_hazard(retention, damage, true)
	blast.emit(0.10)
	message.emit(title + " · TREFFER")

func _blast_center(index: int) -> Vector2:
	var x := site_x + (-54.0 if index == 0 else 85.0)
	return Vector2(x, _floor_y(x) - (27.0 if index == 0 else 65.0))

func _explode(center: Vector2, car: EscapeWagon) -> void:
	var reach := 126.0 if blast_count == 0 else 105.0
	var distance := center.distance_to(car.position)
	if not got_hit and distance < reach:
		_hit(car, center, 1.6 * (1.0 - distance / reach), 0.97)
	for i in range(12):
		var direction := Vector2.from_angle(-0.12 - float(i) * 0.26)
		_shards.append({"p": center, "v": direction * (135.0 + float(i % 5) * 44.0), "age": 0.0, "angle": float(i), "spin": float(i % 4) * 3.0 - 4.0})
	blast.emit(0.14 if distance < 280.0 else 0.04)
	message.emit(title + (" · ERSTE EXPLOSION" if blast_count == 0 else " · KETTENREAKTION"))

func _drop_time(level: int) -> float:
	return elapsed - fuse_time - float(FLOOR_COUNT - 1 - level) * (stagger * 0.44)

func _fall_duration(level: int) -> float:
	return 0.56 + float(FLOOR_COUNT - 1 - level) * 0.17

func _slab_rect(level: int) -> Rect2:
	var h := building_size.y * (rows[level + 1] - rows[level])
	var time := clampf(_drop_time(level) / _fall_duration(level), 0.0, 1.0)
	var x := site_x - building_size.x * 0.5 + (35.0 + float(level % 2) * 21.0) * time * slide
	var y := _floor_y(site_x) - building_size.y + rows[level] * building_size.y
	y = lerpf(y, _floor_y(site_x) - h * 0.67, time * time)
	return Rect2(x, y, building_size.x, h)

func _rubble_rect() -> Rect2:
	return Rect2(site_x - 32.0, _floor_y(site_x) - 24.0, 152.0, 24.0)

func _draw() -> void:
	if building == null:
		return
	var camera := get_viewport().get_camera_2d()
	if camera != null and absf(camera.get_screen_center_position().x - site_x) > 1450.0:
		return
	_draw_warning_board()
	var size := building_source.size
	for level in range(FLOOR_COUNT):
		var drop := _drop_time(level)
		if elapsed >= 0.0 and drop >= _fall_duration(level):
			continue
		var rect := _slab_rect(level) if elapsed >= 0.0 else Rect2(site_x - building_size.x * 0.5, _floor_y(site_x) - building_size.y + building_size.y * rows[level], building_size.x, building_size.y * (rows[level + 1] - rows[level]))
		if elapsed >= 0.0 and elapsed < fuse_time:
			rect.position.x += sin(elapsed * 70.0 + level) * (1.0 + elapsed * 2.0)
		draw_texture_rect_region(building, rect, Rect2(building_source.position + Vector2(0, size.y * rows[level]), Vector2(size.x, size.y * (rows[level + 1] - rows[level]))))
	if contact_trigger and blast_count == 0:
		draw_texture_rect_region(barrel, _drum_rect(), barrel_source)
		if elapsed >= 0.0:
			_draw_cloud(_drum_rect().position + Vector2(26, 10), 10.0, Color(1.0, 0.48, 0.14, 0.76))
	if blast_count == 0 and elapsed >= 0.0:
		var marker := Vector2(site_x, _floor_y(site_x) - building_size.y - 20.0)
		draw_circle(marker, 7.0, Color(1.0, 0.67, 0.15, 0.65 + 0.30 * sin(elapsed * 36.0)), true, -1.0, true)
	if blast_count > 0:
		var rubble := _rubble_rect()
		for i in range(5):
			var region := Rect2(building_source.position + Vector2(size.x * (0.25 + (i % 3) * 0.15), size.y * 0.65), Vector2(size.x * 0.17, size.y * 0.11))
			var rect := Rect2(rubble.position + Vector2(i * 28.0, 8.0 - (i % 3) * 4.0), Vector2(39, 14 + (i % 3) * 4))
			draw_texture_rect_region(building, rect, region)
	for index in range(blast_count):
		var age := elapsed - fuse_time - index * stagger
		if age > PLUME_TIME:
			continue
		var point := _blast_center(index)
		if age < 0.49:
			var expansion := smoothstep(0.0, 0.23, age)
			var width := lerpf(85.0, 230.0 if index == 0 else 182.0, expansion)
			var extent := Vector2(width, width * FIRE_SOURCE.size.y / FIRE_SOURCE.size.x)
			var alpha := 1.0 - smoothstep(0.16, 0.49, age)
			draw_texture_rect_region(fire, Rect2(point - Vector2(extent.x * 0.5, extent.y * 0.77), extent), FIRE_SOURCE, Color(1, 1, 1, alpha))
		if age < 0.20:
			_draw_cloud(point, 38.0 + age * 185.0, Color(1, 0.30, 0.05, 0.65 * (1.0 - age / 0.20)))
			_draw_cloud(point - Vector2(0, 9), 21.0 + age * 105.0, Color(1, 0.81, 0.40, 0.65 * (1.0 - age / 0.20)))
		for i in range(6):
			_draw_cloud(point + Vector2(sin(i * 2.1) * (24 + age * 58), -age * (65 + 18 * i)), 16 + age * 50, Color(0.32, 0.26, 0.21, 0.57 * (1.0 - age / PLUME_TIME)))
	for shard in _shards:
		draw_set_transform(shard.p, shard.angle)
		draw_texture_rect_region(building, Rect2(-7, -4, 14, 8), Rect2(building_source.position + Vector2(size.x * 0.38, size.y * 0.70), Vector2(size.x * 0.11, size.y * 0.035)), Color(1, 1, 1, 1.0 - shard.age / 1.5))
	draw_set_transform(Vector2.ZERO)

func _draw_cloud(center: Vector2, radius: float, tint: Color) -> void:
	var extent := Vector2.ONE * radius
	draw_texture_rect(_glow, Rect2(center - extent, extent * 2.0), false, tint)

func _draw_warning_board() -> void:
	var x := site_x - lead - (125.0 if contact_trigger else 10.0)
	var y := _floor_y(x)
	var p := Vector2(x, y - 59.0)
	draw_line(Vector2(x, y), p, Color8(86, 74, 54), 4.0)
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -15), p + Vector2(-16, 12), p + Vector2(16, 12)]), Color8(65, 53, 35))
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -11), p + Vector2(-12, 9), p + Vector2(12, 9)]), Color8(228, 170, 65))
	draw_line(p + Vector2(0, -4), p + Vector2(0, 3), Color8(74, 58, 33), 2.0, true)
	draw_circle(p + Vector2(0, 6), 1.2, Color8(74, 58, 33))
func camera_weight(world_x: float) -> float:
	var relative := (world_x - site_x) / DrivingTestCourse.PIXELS_PER_METER
	return smoothstep(-43.0, -22.0, relative) * (1.0 - smoothstep(-3.0, 13.0, relative))
