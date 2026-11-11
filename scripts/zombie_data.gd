extends RefCounted

const RUNNER_CHARGE_TEXTURE: Texture2D = preload("res://assets/zombie_runner_charge_4frames.png")
const HEAVY_WALK_TEXTURES: Dictionary = {
	3: preload("res://assets/zombie_worker_walk_4frames.png"),
	4: preload("res://assets/zombie_riot_walk_4frames.png"),
	5: preload("res://assets/zombie_brute_walk_4frames.png")
}
static var _heavy_walk_frames: Dictionary = {}

static func heavy_walk_frame(variant: int, index: int) -> Rect2:
	if not _heavy_walk_frames.has(variant):
		var texture: Texture2D = HEAVY_WALK_TEXTURES[variant]
		var image: Image = texture.get_image()
		var cell := Vector2i(image.get_width() / 2, image.get_height() / 2)
		var frames: Array[Rect2] = []
		for frame in range(4):
			var origin := Vector2i(frame % 2, frame / 2) * cell
			var used: Rect2i = image.get_region(Rect2i(origin, cell)).get_used_rect()
			frames.append(Rect2(used.position + origin, used.size))
		_heavy_walk_frames[variant] = frames
	return _heavy_walk_frames[variant][posmod(index, 4)]

static func heavy_frame_height_scale(variant: int, source: Rect2) -> float:
	var maximum: float = 1.0
	for index in range(4):
		maximum = maxf(maximum, heavy_walk_frame(variant, index).size.y)
	return source.size.y / maximum

const CRAWL_TEXTURES: Dictionary = {
	1: preload("res://assets/zombie_normal_crawl_4frames.png"),
	2: preload("res://assets/zombie_runner_crawl_4frames.png"),
	3: preload("res://assets/zombie_worker_crawl_4frames.png"),
	4: preload("res://assets/zombie_riot_crawl_4frames.png"),
	5: preload("res://assets/zombie_brute_crawl_4frames.png")
}
# Measured visible alpha bounds, excluding faint transparent padding.
const CRAWL_VISIBLE: Dictionary = {
 1: [Rect2(27,36,854,362), Rect2(936,62,785,337), Rect2(27,496,860,355), Rect2(887,491,818,361)],
 2: [Rect2(29,62,828,329), Rect2(914,75,758,316), Rect2(26,511,854,325), Rect2(953,511,757,326)],
 3: [Rect2(42,60,841,345), Rect2(992,58,701,346), Rect2(34,497,853,347), Rect2(887,489,773,360)],
 4: [Rect2(19,79,855,323), Rect2(955,92,738,309), Rect2(18,529,868,317), Rect2(935,526,759,320)],
 5: [Rect2(22,92,865,307), Rect2(887,83,798,316), Rect2(26,527,861,315), Rect2(887,523,807,322)]
}
static func crawl_frame(variant: int, index: int) -> Rect2:
	return CRAWL_VISIBLE[clampi(variant, 1, 5)][posmod(index, 4)]

static func crawl_max_width(variant: int) -> float:
	var maximum: float = 1.0
	for index in range(4):
		maximum = maxf(maximum, crawl_frame(variant, index).size.x)
	return maximum

static var _runner_charge_frames: Array[Rect2] = []

static func runner_charge_frame(index: int) -> Rect2:
	if _runner_charge_frames.is_empty():
		var image: Image = RUNNER_CHARGE_TEXTURE.get_image()
		var cell := Vector2i(image.get_width() / 2, image.get_height() / 2)
		for frame in range(4):
			var origin := Vector2i(frame % 2, frame / 2) * cell
			var used: Rect2i = image.get_region(Rect2i(origin, cell)).get_used_rect()
			_runner_charge_frames.append(Rect2(used.position + origin, used.size))
	return _runner_charge_frames[posmod(index, 4)]

static func impact_pose(variant: int, speed_mps: float, progress: float, member_index: int, hit_seed: int) -> Vector3:
	var speed: float = smoothstep(2.0, 38.0, absf(speed_mps))
	var lightness: float = 1.0 if variant == 2 else 0.68 if variant == 1 else 0.31
	var style: int = posmod(hit_seed + member_index, 3)
	var lift: float = lerpf(3.0, lerpf(14.0, 34.0, lightness), speed)
	var momentum: float = absf(speed_mps) * 36.0 * lerpf(0.46, 0.78, lightness)
	var travel_progress: float = 1.0 - pow(1.0 - progress, 1.65)
	var travel: float = 18.0 * travel_progress + momentum * 0.60 * (1.0 - exp(-progress * 1.35 / 0.60))
	var roll: float = lerpf(1.30, lerpf(1.8, 2.8, lightness), speed)
	if style == 1:
		lift *= 1.22
		travel *= 0.66
		roll *= -0.84
	elif style == 2:
		lift *= 0.46
		travel *= 1.17
	return Vector3(travel, sin(progress * PI) * lift, roll * travel_progress)

const VARIANT_PROFILES: Dictionary = {
	1: {
		"name": "Normale Infizierte",
		"class": "slow",
		"hit_damage": 5.5,
		"speed_retention": 0.78,
		"chase_speed_mps": 9.0,
		"minimum_charge": 0.20,
		"visual_height": 85.0,
		"contact_radius_px": 39.0
	},
	2: {
		"name": "Schneller Läufer",
		"class": "fast",
		"hit_damage": 2.5,
		"speed_retention": 0.94,
		"chase_speed_mps": 17.0,
		"minimum_charge": 0.76,
		"visual_height": 91.0,
		"contact_radius_px": 43.0
	},
	3: {
		"name": "Schwerer Bauarbeiter",
		"class": "robust",
		"hit_damage": 10.0,
		"speed_retention": 0.63,
		"chase_speed_mps": 7.0,
		"minimum_charge": 0.35,
		"visual_height": 99.0,
		"contact_radius_px": 50.0
	},
	4: {
		"name": "Gepanzerter Infizierter",
		"class": "robust",
		"hit_damage": 11.0,
		"speed_retention": 0.57,
		"chase_speed_mps": 8.0,
		"minimum_charge": 0.43,
		"visual_height": 100.0,
		"contact_radius_px": 50.0
	},
	5: {
		"name": "Kettenbrute",
		"class": "robust",
		"hit_damage": 19.0,
		"speed_retention": 0.34,
		"chase_speed_mps": 6.2,
		"minimum_charge": 0.32,
		"visual_height": 112.0,
		"contact_radius_px": 57.0,
		"stop_duration": 1.0
	}
}

static func profile(variant_id: int) -> Dictionary:
	var safe_id: int = clampi(variant_id, 1, 5)
	var selected_profile: Dictionary = VARIANT_PROFILES[safe_id]
	return selected_profile.duplicate(true)

static func variant_for_world(world_id: String, world_index: int, seeded_index: int) -> int:
	# Amsterdam starts with two readable enemy types; later city variants will
	# be authored when those routes are rebuilt.
	return 1 if posmod(seeded_index, 4) != 0 else 2

static func latch_profile(variant_id: int, seeded_roll: int) -> Dictionary:
	var roll: int = posmod(seeded_roll, 100)
	match clampi(variant_id, 1, 5):
		1:
			if roll < 18:
				return {}
			if roll < 54:
				return {"duration": 1.55, "drag": 0.88, "damage": 0.95}
			if roll < 88:
				return {"duration": 2.55, "drag": 1.42, "damage": 1.65}
			return {"duration": 3.4, "drag": 2.0, "damage": 2.25}
		2:
			if roll < 78:
				return {}
			if roll < 95:
				return {"duration": 0.9, "drag": 0.48, "damage": 0.35}
			return {"duration": 1.45, "drag": 0.76, "damage": 0.58}
		3:
			if roll < 10:
				return {}
			if roll < 35:
				return {"duration": 2.4, "drag": 2.05, "damage": 1.8}
			if roll < 74:
				return {"duration": 3.6, "drag": 2.8, "damage": 2.65}
			return {"duration": 5.0, "drag": 3.5, "damage": 3.35}
		4:
			if roll < 4:
				return {}
			if roll < 25:
				return {"duration": 4.0, "drag": 2.75, "damage": 2.7}
			if roll < 65:
				return {"duration": 5.3, "drag": 3.35, "damage": 3.45}
			return {"duration": 6.7, "drag": 3.85, "damage": 4.2}
		_:
			if roll < 10:
				return {}
			if roll < 35:
				return {"duration": 3.8, "drag": 3.0, "damage": 4.2}
			if roll < 70:
				return {"duration": 5.8, "drag": 3.8, "damage": 5.2}
			return {"duration": 7.5, "drag": 4.5, "damage": 6.2}
	return {}

static func walk_motion(phase: float, intensity: float) -> Dictionary:
	var gait: float = clampf(intensity, 0.0, 1.0)
	var step: float = sin(phase)
	return {
		"bob": absf(step) * (0.35 + gait * 0.65),
		"body_roll": sin(phase * 0.5) * 0.045 * (0.35 + gait),
		"arm_swing": cos(phase) * 4.2 * (0.35 + gait),
		"left_step": step * 7.0 * (0.35 + gait),
		"right_step": sin(phase + PI) * 7.0 * (0.35 + gait),
		"squash": absf(step) * 0.018 * (0.35 + gait)
	}

static func latch_motion(phase: float, strength: float) -> Dictionary:
	var grip: float = clampf(strength, 0.0, 1.0)
	var kick: float = 4.0 + grip * 5.0
	return {
		"body_roll": sin(phase) * (0.04 + grip * 0.065),
		"head_sway": sin(phase * 0.72 + 0.6) * (1.0 + grip * 1.2),
		"left_elbow": Vector2(-15.0 + sin(phase) * (2.0 + grip * 2.0), 13.0 + cos(phase) * 2.0),
		"right_elbow": Vector2(15.0 + sin(phase + PI) * (2.0 + grip * 2.0), 13.0 + cos(phase + PI) * 2.0),
		"left_knee": Vector2(-5.0 + sin(phase * 1.25) * kick, 52.0 + absf(cos(phase)) * 2.0),
		"right_knee": Vector2(5.0 + sin(phase * 1.25 + PI) * kick, 52.0 + absf(cos(phase + PI)) * 2.0),
		"left_foot": Vector2(-10.0 + sin(phase * 1.25) * kick * 1.5, 67.0 + cos(phase) * 3.0),
		"right_foot": Vector2(10.0 + sin(phase * 1.25 + PI) * kick * 1.5, 67.0 + cos(phase + PI) * 3.0)
	}
