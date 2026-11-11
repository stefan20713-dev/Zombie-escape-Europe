extends RefCounted

const COBBLES: Texture2D = preload("res://assets/amsterdam_street_setts_v2.png")
const TIMBER: Texture2D = preload("res://assets/amsterdam_timber_material_v2.png")
const CRANE: Texture2D = preload("res://assets/amsterdam_dock_crane_v2.png")
const CRANE_SOURCE := Rect2(203.0, 25.0, 969.0, 1151.0)
const DETAILS: Texture2D = preload("res://assets/amsterdam_quay_details_v2.png")
const DETAIL_WIDTHS: Array[float] = [28.0, 42.0, 20.0, 100.0]
# Opaque bounds measured at alpha > 0.12; transparent RGB fringe is excluded.
const DETAIL_SOURCES: Array[Rect2] = [
	Rect2(155.0, 13.0, 414.0, 467.0), Rect2(797.0, 26.0, 583.0, 488.0),
	Rect2(164.0, 534.0, 331.0, 446.0), Rect2(714.0, 682.0, 676.0, 185.0)
]

static func material_size(texture: Texture2D, world_width: float) -> Vector2:
	return Vector2(world_width, world_width * texture.get_height() / float(texture.get_width()))

static func detail_source(index: int) -> Rect2:
	return DETAIL_SOURCES[clampi(index, 0, 3)]
