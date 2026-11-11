extends Node
var explosions := 0
var kills := 0
func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	var d = load("res://scenes/amsterdam_preview.tscn").instantiate()
	d.workshop_vehicle = "kombi"
	d.workshop_upgrades = {"engine": 2, "tires": 2, "tank": 3, "armor": 2, "nitro": 3, "suspension": 1, "weapon": 1}
	get_tree().root.add_child(d)
	await get_tree().physics_frame
	var c = d.course
	var w = d.wagon
	var e = c.explosives
	e.exploded.connect(func(count: int, _chain: bool): explosions += 1; kills += count)
	var drum: Dictionary = e.drums[0]
	var center: Vector2 = e.drum_rect(drum).get_center()
	var zombie_event: Dictionary = c._encounters.filter(func(event: Dictionary): return String(event.kind) == "zombie_group")[0]
	var member: Dictionary = zombie_event.members_data[0]
	member.area.position = center
	member.x = center.x
	# One member is in the real blast radius. Others are deliberately outside it.
	for event in c._encounters:
		for other in event.members_data:
			if other != member:
				other.area.position.y = center.y - 1000.0
	var crate: Dictionary = c._encounters[0]
	crate.members_data[0].area.position = center + Vector2(20, 0)
	crate.members_data[0].x = center.x + 20.0
	w.position = Vector2.ZERO
	assert(not e.try_weapon(w))
	w.position = Vector2(center.x - w.front_contact_offset_px() - 4.0 * 36.0, center.y)
	assert(e.try_weapon(w))
	w.position = Vector2.ZERO
	e._detonate(drum, w)
	e._detonate(drum, w)
	assert(explosions == 1 and kills == 1 and member.hit)
	assert(crate.done, "The same spatial blast must clear the wooden crate.")
	assert(e.drums[1].chain and float(e.drums[1].fuse) > 0.0)
	w.freeze = false
	e._physics_process(0.20)
	assert(explosions == 2 and kills == 1, "Chain reaction must never reward the same zombie twice.")
	assert(d._zombie_coins == 2)
	var before_health: float = w.durability
	w.position = e.drum_rect(e.drums[2]).get_center()
	e._detonate(e.drums[2], w)
	assert(w.durability < before_health, "Standing inside a blast must damage the car.")
	w.durability = 45.0
	var details = w.get_node("DamageDetails")
	details._process(0.016)
	assert(details.debris.size() == 2)
	w.durability = 20.0
	details._process(0.016)
	assert(details.debris.size() == 3)
	assert(w.engine_condition_factor() < 1.0 and w.engine_condition_factor() > 0.76)
	w.durability = 100.0
	details._process(0.016)
	assert(details.debris.is_empty() and is_equal_approx(w.engine_condition_factor(), 1.0))
	var max_slope := 0.0
	for meter in range(190, 385):
		max_slope = maxf(max_slope, absf(c.slope_at(float(meter) * 36.0)))
	assert(max_slope > deg_to_rad(25.0) and max_slope < deg_to_rad(38.0))
	e.reset()
	assert(e.blasts.is_empty() and e.fragments.is_empty() and e.drums.all(func(item: Dictionary): return not item.done))
	print("COMBAT_PASS_OK chain=spatial_once kills=once damage=progressive detached_parts=true reset=true max_slope_deg=", rad_to_deg(max_slope))
	get_tree().quit()
