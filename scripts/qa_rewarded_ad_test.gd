extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const QA_DIAGNOSTICS = preload("res://scripts/qa_diagnostics.gd")
const EXPECTED_REWARD: int = 500
const TEST_TIMEOUT_S: float = 210.0
const RESULT_HOLD_S: float = 5.0

var _game: Node2D
var _ads_service: Node
var _elapsed_s: float = 0.0
var _stage: String = "initializing"
var _failure_run_id: int = -1
var _money_before_reward: int = 0
var _observed_reward_amount: int = 0
var _observed_reward_run_id: int = -1
var _finished: bool = false
var _quit_at_msec: int = 0

func _ready() -> void:
	if not QA_DIAGNOSTICS.enabled():
		_fail("QA diagnostics are disabled for the rewarded-ad test scene.")
		return
	_game = MAIN_SCENE.instantiate() as Node2D
	if _game == null:
		_fail("The production game scene could not be instantiated.")
		return
	add_child(_game)
	await get_tree().process_frame
	if not is_instance_valid(_game) or _game.get_node_or_null("Wagon") == null:
		_fail("The production game scene is missing its vehicle.")
		return
	_ads_service = get_node_or_null("/root/AdsService")
	if not is_instance_valid(_ads_service):
		_fail("The production AdsService autoload is unavailable.")
		return
	_ads_service.connect("rewarded_coins_earned", _on_rewarded_coins_earned)
	_game.first_drive_tutorial_completed = true
	_game.selected_world_index = 0
	_game.unlocked_world_index = maxi(0, int(_game.unlocked_world_index))
	_game._configure_selected_world()
	_game._begin_run(false)
	_failure_run_id = int(_game.run_attempt_id)
	_game.wagon.durability = 0.0
	_stage = "waiting_for_failure"
	print("[QA_AD_REWARD] START run_id=%d mobile=%s" % [_failure_run_id, str(bool(_game.mobile_target))])

func _process(delta: float) -> void:
	if _finished:
		if Time.get_ticks_msec() >= _quit_at_msec:
			get_tree().quit()
		return
	_elapsed_s += delta
	if _elapsed_s >= TEST_TIMEOUT_S:
		_fail("Timed out while waiting at stage %s." % _stage, {
			"screen": String(_game.screen_state) if is_instance_valid(_game) else "missing",
			"ads_status": String(_ads_service.get("service_status")) if is_instance_valid(_ads_service) else "missing",
			"failure_run_id": _failure_run_id,
			"observed_reward_run_id": _observed_reward_run_id
		})
		return
	if not is_instance_valid(_game) or not is_instance_valid(_ads_service):
		_fail("The production scene or AdMob service was freed during the test.")
		return
	match _stage:
		"waiting_for_failure":
			if String(_game.screen_state) != "RESULT":
				return
			_money_before_reward = int(_game.money)
			if int(_game.run_attempt_id) != _failure_run_id:
				_fail("The production result screen belongs to a different run.")
				return
			_stage = "waiting_for_test_ad"
			print("[QA_AD_REWARD] FAILURE_READY run_id=%d money=%d" % [_failure_run_id, _money_before_reward])
		"waiting_for_test_ad":
			if int(_ads_service.get("current_failure_run_id")) != _failure_run_id:
				return
			if not bool(_ads_service.call("has_rewarded_ad_for_current_failure")):
				return
			if not bool(_ads_service.call("show_rewarded_ad_for_current_failure")):
				_fail("The real test ad was available but production AdsService refused to show it.")
				return
			_stage = "waiting_for_native_reward"
			print("[QA_AD_REWARD] AD_SHOWN run_id=%d" % _failure_run_id)
		"waiting_for_native_reward":
			if _observed_reward_run_id != _failure_run_id:
				return
			if _observed_reward_amount != EXPECTED_REWARD:
				_fail("The native callback returned an unexpected coin amount.", {
					"amount": _observed_reward_amount,
					"run_id": _observed_reward_run_id
				})
				return
			if not _game.rewarded_bonus_run_ids.has(_failure_run_id):
				_fail("The real callback did not grant the production run reward.")
				return
			var actual_money: int = int(_game.money)
			if actual_money != _money_before_reward + EXPECTED_REWARD:
				_fail("The production reward changed coins by an unexpected amount.", {
					"before": _money_before_reward,
					"after": actual_money,
					"expected_delta": EXPECTED_REWARD
				})
				return
			_stage = "waiting_for_ad_dismissal"
			print("[QA_AD_REWARD] REWARD_CONFIRMED run_id=%d amount=%d money_before=%d money_after=%d" % [
				_failure_run_id,
				_observed_reward_amount,
				_money_before_reward,
				actual_money
			])
		"waiting_for_ad_dismissal":
			if bool(_ads_service.get("_showing_rewarded")):
				return
			_finish(true, "run_id=%d amount=%d money_before=%d money_after=%d" % [
				_failure_run_id,
				_observed_reward_amount,
				_money_before_reward,
				int(_game.money)
			])

func _on_rewarded_coins_earned(amount: int, failed_run_id: int) -> void:
	_observed_reward_amount = amount
	_observed_reward_run_id = failed_run_id

func _fail(reason: String, details: Dictionary = {}) -> void:
	_finish(false, "reason=%s details=%s" % [reason, str(details)])

func _finish(passed: bool, details: String) -> void:
	if _finished:
		return
	_finished = true
	_stage = "finished"
	if is_instance_valid(_game):
		_game.clear_touch_actions()
		_game.paused = true
		if is_instance_valid(_game.wagon):
			_game.wagon.freeze = true
	var result: String = "PASS" if passed else "FAIL"
	print("[QA_AD_REWARD] %s %s" % [result, details])
	_quit_at_msec = Time.get_ticks_msec() + int(RESULT_HOLD_S * 1000.0)
