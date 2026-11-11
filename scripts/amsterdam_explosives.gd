extends Node2D
## Authored fuel drums. Every ignition, blast hit and reward is resolved once.
const P := 36.0
const RADIUS := 190.0
const BARREL = preload("res://assets/amsterdam_explosive_drum_v1.png")
const BURST = preload("res://assets/amsterdam_explosion_v1.png")
const BARREL_SOURCE := Rect2(139, 136, 738, 1289)
const BURST_SOURCE := Rect2(97, 73, 1238, 912)
var course: Node2D
var drums: Array[Dictionary] = []
var blasts: Array[Dictionary] = []
var fragments: Array[Dictionary] = []
signal exploded(zombies: int, chain: bool)

func _ready() -> void:
	course = get_parent()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	reset()

func reset() -> void:
	drums.clear()
	blasts.clear()
	fragments.clear()
	for meter in [138.0, 140.0, 317.0, 319.0, 613.0, 616.0, 712.0, 714.0, 956.0, 958.0, 1062.0, 1064.0, 1472.0, 1608.0]:
		drums.append({"x": meter * P, "fuse": -1.0, "done": false, "chain": false, "velocity": 0.0})
	queue_redraw()

func drum_rect(drum: Dictionary) -> Rect2:
	var height := 47.0
	var width: float = height * BARREL_SOURCE.size.x / BARREL_SOURCE.size.y
	var x: float = float(drum.x)
	return Rect2(x - width * 0.5, course.height_at(x) - height, width, height)

func try_weapon(wagon: EscapeWagon) -> bool:
	if not wagon.weapon_active or wagon.weapon_level <= 0:
		return false
	var front: float = wagon.position.x + wagon.front_contact_offset_px()
	for drum in drums:
		if drum.done or float(drum.fuse) >= 0.0:
			continue
		var center := drum_rect(drum).get_center()
		if center.x - front >= 0.0 and center.x - front <= 9.0 * P and absf(center.y - wagon.position.y) < 70.0:
			wagon.show_weapon_shot(center)
			# A bullet detonates the drum at its visible position immediately;
			# a contact fuse lets a fast car overtake its own explosion.
			_detonate(drum,wagon)
			return true
	return false

func _physics_process(delta: float) -> void:
	if course._finish_safe:return
	var wagon: EscapeWagon = course._wagon
	if wagon == null or wagon.freeze:
		return
	for drum in drums:
		if drum.done:
			continue
		if float(drum.fuse) < 0.0 and wagon.chassis_overlaps_world_rect(drum_rect(drum)):
			drum.fuse = 0.30
			drum.velocity = wagon.linear_velocity.x * 0.35
		if float(drum.fuse) >= 0.0:
			drum.x += float(drum.velocity) * delta
			drum.fuse -= delta
			if float(drum.fuse) <= 0.0:
				_detonate(drum, wagon)
	for i in range(blasts.size() - 1, -1, -1):
		blasts[i].age += delta
		if float(blasts[i].age) > 0.65:
			blasts.remove_at(i)
	for i in range(fragments.size() - 1, -1, -1):
		var fragment: Dictionary = fragments[i]
		fragment.age += delta
		fragment.velocity += Vector2(0, 340) * delta
		fragment.position += fragment.velocity * delta
		fragment.angle += float(fragment.spin) * delta
		if float(fragment.age) > 1.8:
			fragments.remove_at(i)
	queue_redraw()

func _detonate(drum: Dictionary, wagon: EscapeWagon) -> void:
	if drum.done:
		return
	drum.done = true
	var center := drum_rect(drum).get_center()
	blasts.append({"center": center, "age": 0.0})
	var killed := 0
	for event_index in range(course._encounters.size()):
		var event: Dictionary = course._encounters[event_index]
		if event.done:
			continue
		if String(event.kind) not in ["zombie_group", "runner_group"]:
			if String(event.get("prop", "")) in ["timber_barrier", "wood_crates", "barrel_stack"]:
				for member in event.members_data:
					var area: Area2D = member.area
					if is_instance_valid(area) and area.position.distance_to(center) < RADIUS:
						course._clear_encounter(event_index)
						course.spawn_timber_fragments(area.position.x, course.height_at(area.position.x), 14.0)
						break
			continue
		for member in event.members_data:
			var area: Area2D = member.area
			if member.hit or not is_instance_valid(area) or area.position.distance_to(center) > RADIUS:
				continue
			member.hit = true
			area.set_deferred("monitoring", false)
			killed += 1
			course._reactions.append({"variant": event.variant, "members": [member.duplicate()], "time_left": 1.2, "duration": 1.2, "ground_y": course.height_at(area.position.x), "speed_mps": 17.0, "seed": floori(area.position.x)})
		event.done = event.members_data.all(func(member: Dictionary) -> bool: return member.hit)
	for other in drums:
		if not other.done and float(other.fuse) < 0.0 and drum_rect(other).get_center().distance_to(center) <= RADIUS:
			other.fuse = 0.18
			other.chain = true
	var distance: float = wagon.global_position.distance_to(center)
	if distance < RADIUS:
		wagon.record_damage_contact(center)
		wagon.hit_road_hazard(0.98, 4.0 * (1.0 - distance / RADIUS), true)
	for i in range(10):
		fragments.append({"position": center, "velocity": Vector2(cos(float(i) * 2.4) * 170.0, -110.0 - float(i % 4) * 45.0), "age": 0.0, "angle": float(i), "spin": -5.0 + float(i), "source": Rect2(BARREL_SOURCE.position + Vector2(float(i % 3) * 150.0, float(i % 4) * 240.0), Vector2(120, 140))})
	exploded.emit(killed, bool(drum.chain))
	course.queue_redraw()

func _draw() -> void:
	if course == null:
		return
	var bounds: Vector2 = course._visible_world_x_bounds(200.0)
	for drum in drums:
		if drum.done or float(drum.x) < bounds.x or float(drum.x) > bounds.y:
			continue
		var rect := drum_rect(drum)
		draw_texture_rect_region(BARREL, rect, BARREL_SOURCE)
		if float(drum.fuse) >= 0.0:
			draw_circle(rect.position + Vector2(rect.size.x * 0.5, 1), 3.0, Color8(255, 225, 122))
	for blast in blasts:
		var progress: float = float(blast.age) / 0.65
		var height: float = 95.0 + sin(progress * PI) * 80.0
		var size := Vector2(height * BURST_SOURCE.size.x / BURST_SOURCE.size.y, height)
		draw_texture_rect_region(BURST, Rect2(Vector2(blast.center) - size * Vector2(0.5, 0.65), size), BURST_SOURCE, Color(1, 1, 1, 1.0 - smoothstep(0.28, 0.65, float(blast.age))))
	for fragment in fragments:
		draw_set_transform(fragment.position, fragment.angle)
		draw_texture_rect_region(BARREL, Rect2(-4, -4, 8, 9), fragment.source, Color(1, 1, 1, 1.0 - float(fragment.age) / 1.8))
	draw_set_transform(Vector2.ZERO)

func active_hint(wagon: EscapeWagon) -> String:
	for drum in drums:
		if not drum.done and float(drum.x) > wagon.position.x and float(drum.x) - wagon.position.x < 20.0 * P:
			return "ROTES FASS · WAFFE ZÜNDET AUS ABSTAND" if wagon.weapon_active else "ROTES FASS · RAMMEN ZÜNDET ES · ABSTAND HALTEN"
	return ""
