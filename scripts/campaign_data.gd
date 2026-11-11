extends RefCounted

const PIXELS_PER_METER: float = 36.0
const LEGACY_PIXEL_SCALE: float = 4.0
const ROUTE_LENGTH_M: float = 6000.0
const WORLD_START_OFFSET_M: float = 22.0
const PLAYABLE_WORLD_COUNT: int = 2

const CAMPAIGN_WORLDS: Array[Dictionary] = [
	{"number": 1, "id": "amsterdam", "city": "Amsterdam", "country": "Niederlande", "map": Vector2(0.373, 0.504), "threat": "Einzelne langsame Zombies", "theme": "canals", "setpiece": "Grachtenstraßen und beschädigte Brücken", "challenge": "Einführung in Gas, Sprünge, Treibstoff und Garage", "vehicle": "Kombi", "length_m": 1800,
		"drive_scene": "res://scenes/amsterdam_preview.tscn", "menu_art": "res://assets/amsterdam_menu_gracht.png", "workshop_view": "res://assets/amsterdam_gameplay_panorama_0.5.56.png"},
	{"number": 2, "id": "utrecht", "city": "Utrecht", "country": "Niederlande", "map": Vector2(0.54, 0.40), "theme": "canals", "setpiece": "Ladekai, Baustellen und kippende Überfahrt", "challenge": "Schwung halten und Höhenwege nutzen", "vehicle": "Kombi", "length_m": 1400, "drive_scene": "res://levels/utrecht/preview.tscn", "menu_art": "res://levels/utrecht/art/skyline.png", "workshop_view": "res://levels/utrecht/art/skyline.png"}
]
# Amsterdam's authored, readable road encounter profile.
const WORLD_SETPIECE_PROFILES: Dictionary = {
	"amsterdam": {"kind": "canal_debris", "label": "Grachtenbrücke", "speed_retention": 0.80, "damage": 3.0}
}
# Background-only atmosphere; it does not change vehicle physics.
const WORLD_ATMOSPHERE_PROFILES: Dictionary = {
	"amsterdam": {"kind": "mist", "intensity": 0.34}
}
# Broad Amsterdam elevation contours. Drawing, vehicle placement, and collision
# all use the same interpolated road height.
const ROUTE_ELEVATION_M: Dictionary = {
	"amsterdam": [0.0, 0.8, 1.8, 1.0, -0.6, -1.2, 0.4, 0.8, 0.0]
}
const VEHICLE_ORDER: Array[String] = ["kombi", "lieferwagen", "offroad_pickup"]

const VEHICLES: Dictionary = {
	"kombi": {
		"name": "KOMBI",
		"unlock_meter": 0.0,
		"mass": 420.0,
		"base_engine_force": 78000.0,
		"engine_force_per_level": 7500.0,
		"base_speed_mps": 20.0,
		"speed_per_level_mps": 5.8333333,
		"base_fuel": 70.0,
		"fuel_per_tank_level": 22.0,
		"boost_force": 75000.0,
		"obstacle_damage": 20.0,
		"wheel_radius": 16.0,
		"suspension_strength": 9500.0,
		"suspension_damping": 1550.0,
		"grounded_torque": 360000.0,
		"airborne_torque": 3200000.0
	},
	"lieferwagen": {
		"name": "LIEFERWAGEN",
		"unlock_meter": 2800.0,
		"unlock_world": 2,
		"mass": 520.0,
		"base_engine_force": 62000.0,
		"engine_force_per_level": 6000.0,
		"base_speed_mps": 15.5,
		"speed_per_level_mps": 2.8,
		"base_fuel": 88.0,
		"fuel_per_tank_level": 26.0,
		"boost_force": 31000.0,
		"obstacle_damage": 18.0,
		"suspension_strength": 9500.0,
		"suspension_damping": 1550.0,
		"grounded_torque": 360000.0,
		"airborne_torque": 2800000.0
	},
	"offroad_pickup": {
		"name": "GELÄNDE-PICKUP",
		"unlock_meter": 32900.0,
		"unlock_world": 14,
		"mass": 465.0,
		"base_engine_force": 58000.0,
		"engine_force_per_level": 6400.0,
		"base_speed_mps": 16.0,
		"speed_per_level_mps": 2.9,
		"base_fuel": 80.0,
		"fuel_per_tank_level": 24.0,
		"boost_force": 34000.0,
		"obstacle_damage": 14.0,
		"suspension_strength": 11200.0,
		"suspension_damping": 1780.0,
		"grounded_torque": 410000.0,
		"airborne_torque": 3200000.0,
		"wheel_radius": 19.5,
		"rear_wheel_x": -51.0,
		"front_wheel_x": 51.0
	}
}


static func world_index_for_id(city_id: String) -> int:
	for index in range(CAMPAIGN_WORLDS.size()):
		if String(CAMPAIGN_WORLDS[index].id) == city_id:
			return index
	return -1
