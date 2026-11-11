extends Node

const WAGON_SCENE: PackedScene = preload("res://scenes/wagon.tscn")
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")
const ARMOR_TIER1: Texture2D = preload("res://assets/kombi_armor_tier1_0.5.43.png")
const ARMOR_TIER2: Texture2D = preload("res://assets/kombi_armor_tier2_0.5.43.png")
const ARMOR_TIER3: Texture2D = preload("res://assets/kombi_armor_tier3_0.5.43.png")
const TIRE_TIER1: Texture2D = preload("res://assets/kombi_wheel_tier1_0.7.0.png")
const TIRE_TIER2: Texture2D = preload("res://assets/kombi_wheel_0.6.0.png")
const TIRE_TIER3: Texture2D = preload("res://assets/kombi_wheel_tier3_0.7.0.png")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var wagon: EscapeWagon = WAGON_SCENE.instantiate() as EscapeWagon
	add_child(wagon)
	await get_tree().process_frame
	var stock_wheel_radius: float = float(CAMPAIGN_DATA.VEHICLES["kombi"]["wheel_radius"])
	var expected_textures: Array[Texture2D] = [ARMOR_TIER1, ARMOR_TIER2, ARMOR_TIER3]
	for level in range(4):
		var upgrades: Dictionary = {
			"engine": 0, "tires": 0, "tank": 0, "armor": level,
			"suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0
		}
		wagon.configure(upgrades, "kombi")
		if level == 0:
			assert(wagon.kombi_armor_body_texture() == null, "Stock Kombi must keep the stock body art.")
			assert(wagon.front_contact_offset_px() == 115.0, "Stock Kombi contact range should match the longer body.")
			assert(wagon.rear_wheel_x == -65.0 and wagon.front_wheel_x == 65.0, "Stock Kombi axles should align to the longer body.")
			assert(is_equal_approx(wagon.KOMBI_BODY_DRAW_WIDTH, 226.0), "Kombi body must use the longer aspect-correct draw width.")
			assert(is_equal_approx(wagon.chassis_shape.shape.size.x, 184.0), "Kombi chassis collision must extend with the longer stock body.")
			assert(is_equal_approx(wagon.wheel_visual_radius(), stock_wheel_radius), "Stock tire radius must match the smaller Kombi baseline.")
		else:
			var expected: Texture2D = expected_textures[level - 1]
			assert(wagon.kombi_armor_body_texture() == expected, "Armor level %d selected the wrong body sprite." % level)
			assert(expected.get_width() == 1774 and expected.get_height() == 887, "Armor level %d sprite canvas changed." % level)
			assert(wagon.front_contact_offset_px() == 115.0, "Armor level %d front rammer is not included in contact range." % level)
			assert(wagon.rear_wheel_x == -65.0 and wagon.front_wheel_x == 65.0, "Armor level %d must not move untuned tires." % level)
			assert(is_equal_approx(wagon.wheel_visual_radius(), stock_wheel_radius), "Armor level %d must not resize untuned tires." % level)
	var tire_textures: Array[Texture2D] = [TIRE_TIER1, TIRE_TIER2, TIRE_TIER3]
	for tire_level in range(1, 4):
		wagon.configure({"engine": 0, "tires": tire_level, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}, "kombi")
		assert(wagon.kombi_tire_texture(tire_level) == tire_textures[tire_level - 1], "Tire upgrade level %d selected the wrong wheel art." % tire_level)
		assert(wagon.wheel_visual_radius() > stock_wheel_radius, "Tire upgrade level %d should visibly enlarge the tire." % tire_level)
		if tire_level > 1:
			wagon.configure({"engine": 0, "tires": tire_level - 1, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}, "kombi")
			var previous_radius: float = wagon.wheel_visual_radius()
			wagon.configure({"engine": 0, "tires": tire_level, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}, "kombi")
			assert(wagon.wheel_visual_radius() > previous_radius, "Tire upgrade level %d must be larger than the previous stage." % tire_level)
	wagon.configure({"engine": 3, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}, "kombi")
	assert(is_equal_approx(wagon.wheel_visual_radius(), stock_wheel_radius), "Engine-only tuning must not alter stock tire size.")
	assert(wagon.rear_wheel_x == -65.0 and wagon.front_wheel_x == 65.0, "Engine-only tuning must not move the Kombi axles.")
	wagon.configure({"engine": 0, "tires": 1, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0, "nitro": 0}, "kombi")
	assert(is_equal_approx(wagon.wheel_visual_radius(), stock_wheel_radius + 1.2), "The first tire upgrade should visibly enlarge the stock wheel.")
	var other_vehicle: EscapeWagon = WAGON_SCENE.instantiate() as EscapeWagon
	add_child(other_vehicle)
	await get_tree().process_frame
	other_vehicle.configure({"armor": 3}, "offroad_pickup")
	assert(other_vehicle.kombi_armor_body_texture() == null, "Kombi armor art must not replace other vehicle bodies.")
	wagon.queue_free()
	other_vehicle.queue_free()
	print("KOMBI_ARMOR_VISUAL_PROGRESSION_OK longer_body=226px chassis=184px armor_keeps_stock_tires=true tire_stages=3 distinct_art=true")
	get_tree().quit()
