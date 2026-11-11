extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const CAMPAIGN_DATA = preload("res://scripts/campaign_data.gd")

func _ready() -> void:
	call_deferred("_run_starting_hill_package_test")

func _run_starting_hill_package_test() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	game.selected_vehicle = "kombi"
	game.selected_world_index = 0
	game.screen_state = "GARAGE"
	game.campaign_meter = 0.0
	game.money = 100
	game.upgrades = _empty_upgrades()
	game.vehicle_upgrades["kombi"] = _empty_upgrades()
	game.wagon.configure(game.upgrades, "kombi")

	var engine_price: int = game.upgrade_price("engine")
	var tank_price: int = game.upgrade_price("tank")
	assert(engine_price + tank_price == 95, "The starter package must preserve the established 55 + 40 coin prices.")
	assert(game.is_starting_hill_package_available(), "A fresh garage should offer the first-hill package.")
	assert(game.starting_hill_package_price() == 95, "The package price must match its two individual upgrades.")

	var hud: Variant = game.get_node("HUDLayer/HUD")
	hud.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	assert(_has_button(hud, "starter_package"), "The garage must expose the one-tap starter-package button.")
	var package_rect: Rect2 = _button_rect(hud, "starter_package")
	var start_rect: Rect2 = _button_rect(hud, "start")
	assert(not package_rect.intersects(start_rect), "The package action must not overlap the drive button.")
	for part in ["engine", "tires", "tank", "armor"]:
		var card_rect: Rect2 = _button_rect(hud, "upgrade:" + part)
		assert(card_rect.end.x <= package_rect.position.x + 0.5, "The %s card must stay left of the package slot." % part)
		assert(not card_rect.intersects(start_rect), "The %s card must not overlap the drive button." % part)
	hud._handle_button("starter_package")
	assert(int(game.money) == 5, "Buying the package should deduct exactly 95 coins.")
	assert(game.upgrade_level("engine") == 1 and game.upgrade_level("tank") == 1, "The package must install one engine and one tank level together.")
	assert(game.vehicle_upgrades["kombi"]["engine"] == 1 and game.vehicle_upgrades["kombi"]["tank"] == 1, "Both upgrades must be saved to the selected vehicle.")
	assert(game.wagon._engine_force > float(CAMPAIGN_DATA.VEHICLES["kombi"]["base_engine_force"]), "The purchased engine must raise real vehicle force.")
	assert(game.wagon.fuel_capacity > float(CAMPAIGN_DATA.VEHICLES["kombi"]["base_fuel"]), "The purchased tank must raise real fuel capacity.")
	assert(not game.is_starting_hill_package_available(), "The package must disappear after either included upgrade is installed.")
	assert(not game.buy_starting_hill_package() and int(game.money) == 5, "The package must not be purchasable twice.")

	_reset_fresh_game(game, 90)
	assert(game.is_starting_hill_package_available(), "The offer remains visible when the player is short on coins.")
	assert(not game.buy_starting_hill_package(), "The package must refuse an underfunded transaction.")
	assert(int(game.money) == 90 and game.upgrade_level("engine") == 0 and game.upgrade_level("tank") == 0, "An underfunded package must not charge the player or partially install upgrades.")
	assert(String(game.toast_text).contains("5 Münzen"), "The failure message must tell the player how many coins are missing.")

	_reset_fresh_game(game, 100)
	assert(game.buy_upgrade("engine"), "The existing individual engine purchase must continue to work.")
	var money_after_engine: int = int(game.money)
	assert(not game.is_starting_hill_package_available(), "An individual engine purchase must remove the bundled offer.")
	assert(not game.buy_starting_hill_package() and int(game.money) == money_after_engine and game.upgrade_level("tank") == 0, "The package must not stack or double-charge after an individual purchase.")

	_reset_fresh_game(game, 100)
	game.campaign_meter = game.route_length_m * 0.5
	assert(not game.is_starting_hill_package_available() and game.starting_hill_package_price() == -1, "The first-hill offer must end after the early-route window.")
	game.campaign_meter = 0.0
	game.unlocked_vehicles.append(CAMPAIGN_DATA.VEHICLE_ORDER[1])
	assert(not game.is_starting_hill_package_available(), "The package must not displace the vehicle selector after a second vehicle unlocks.")

	print("STARTING_HILL_PACKAGE_OK price=95 atomic=true real_vehicle_stats=true insufficient_funds=true repeat_purchase=false unlock_ui_preserved=true")
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _reset_fresh_game(game: Node, starting_money: int) -> void:
	game.selected_vehicle = "kombi"
	game.selected_world_index = 0
	game.screen_state = "GARAGE"
	game.campaign_meter = 0.0
	game.money = starting_money
	game.upgrades = _empty_upgrades()
	game.vehicle_upgrades["kombi"] = _empty_upgrades()
	game.wagon.configure(game.upgrades, "kombi")

func _empty_upgrades() -> Dictionary:
	return {"engine": 0, "tires": 0, "tank": 0, "armor": 0, "suspension": 0, "efficiency": 0, "brakes": 0}

func _has_button(hud: Variant, button_id: String) -> bool:
	for button in hud.buttons:
		if String(button.get("id", "")) == button_id:
			return true
	return false

func _button_rect(hud: Variant, button_id: String) -> Rect2:
	for button in hud.buttons:
		if String(button.get("id", "")) == button_id:
			return Rect2(button.get("rect", Rect2()))
	return Rect2()
