extends "res://scripts/amsterdam_preview_course.gd"
## Same Amsterdam course, plus the horde waves in amsterdam_extra_waves.gd.

func _build_encounters() -> void:
	super()
	var waves: Array = preload("res://scripts/amsterdam_extra_waves.gd").WAVES
	var base_count: int = _encounters.size()
	for wave_index in range(waves.size()):
		var event: Dictionary = (waves[wave_index] as Dictionary).duplicate(true)
		var layout_index: int = base_count + wave_index
		event["agile_chase"] = true
		event["done"] = false
		event["areas"] = []
		event["members_data"] = []
		var kind: String = String(event["kind"])
		var member_count: int = int(event["members"])
		var variant: int = int(event["variant"])
		var group_spacing: float = 108.0 if variant == 2 else 62.0
		for member_index in range(member_count):
			var x: float = float(event["meter"]) * PIXELS_PER_METER
			if kind in ["zombie_group", "runner_group"]:
				x += float(member_index) * group_spacing - float(member_count - 1) * group_spacing * 0.5
			var ground_y: float = height_at(x)
			var visual_height: float = float(ZOMBIE_DATA.profile(variant).get("visual_height", 78.0))
			var area_size := Vector2(visual_height * 0.52, visual_height * 0.84)
			var area := Area2D.new()
			area.name = "AmsterdamEncounter_%02d_%02d" % [layout_index, member_index]
			area.position = Vector2(x, ground_y - area_size.y * 0.5)
			area.collision_layer = 0
			area.collision_mask = 1
			area.monitoring = true
			area.monitorable = false
			var collision := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = area_size
			collision.shape = shape
			area.add_child(collision)
			area.body_entered.connect(_on_encounter_body_entered.bind(layout_index, member_index))
			add_child(area)
			(event["areas"] as Array).append(area)
			(event["members_data"] as Array).append({"x": x, "area": area, "area_height": area_size.y, "phase": float(member_index) * 0.8, "hit": false})
		_encounters.append(event)
