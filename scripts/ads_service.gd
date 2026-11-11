extends Node

signal rewarded_ads_changed
signal privacy_options_changed
signal service_status_changed(status: String)
signal rewarded_coins_earned(amount: int, failed_run_id: int)

const REWARDED_COINS: int = 500
const TEST_REWARDED_UNIT_ID: String = "ca-app-pub-3940256099942544/5224354917"
const TEST_INTERSTITIAL_UNIT_ID: String = "ca-app-pub-3940256099942544/1033173712"
const ADS_STATE_PATH: String = "user://ads_state.cfg"
const REWARDED_DAILY_LIMIT: int = 5
const INTERSTITIAL_DAILY_LIMIT: int = 2
const INTERSTITIAL_FAILURE_INTERVAL: int = 3
const INTERSTITIAL_COOLDOWN_S: int = 90
const DAY_SECONDS: int = 86400
const CALLBACK_TIMEOUT_S: float = 15.0
const QA_DIAGNOSTICS = preload("res://scripts/qa_diagnostics.gd")

# Release ads stay disabled until the developer's real AdMob IDs and consent
# messages have been configured. Debug Android builds use Google's official
# test units only.
const RELEASE_ADS_ENABLED: bool = false

var current_failure_run_id: int = -1
var service_status: String = "Nur auf Android verfügbar"

var _ads_initialized: bool = false
var _ads_requests_allowed: bool = false
var _consent_request_active: bool = false
var _consent_form_active: bool = false
var _privacy_options_required: bool = false
var _rewarded_loading: bool = false
var _interstitial_loading: bool = false
var _showing_rewarded: bool = false
var _rewarded_run_id: int = -1
var _reward_claimed_runs: Dictionary = {}
var _rewarded_ad: RewardedAd
var _interstitial_ad: InterstitialAd
var _active_consent_form: ConsentForm
var _rewarded_load_callback: RewardedAdLoadCallback
var _interstitial_load_callback: InterstitialAdLoadCallback
var _rewarded_timestamps: Array[int] = []
var _interstitial_timestamps: Array[int] = []
var _failure_exit_count: int = 0
var _last_interstitial_time: int = 0


func _ready() -> void:
	_load_ad_state()
	if OS.get_name() != "Android":
		_set_status("Werbung nur auf Android")
		return
	if not OS.is_debug_build() and not OS.has_feature("qa_release") and not RELEASE_ADS_ENABLED:
		_set_status("Live-Anzeigen erst nach AdMob-Konfiguration")
		return
	call_deferred("_request_consent")


func set_failure_context(run_id: int) -> void:
	if current_failure_run_id == run_id:
		return
	current_failure_run_id = run_id
	rewarded_ads_changed.emit()


func clear_failure_context() -> void:
	if current_failure_run_id == -1:
		return
	current_failure_run_id = -1
	rewarded_ads_changed.emit()


func has_rewarded_ad_for_current_failure() -> bool:
	return (
		current_failure_run_id >= 0
		and not _showing_rewarded
		and is_instance_valid(_rewarded_ad)
		and not _reward_claimed_runs.has(current_failure_run_id)
		and not _reward_limit_reached()
	)


func show_rewarded_ad_for_current_failure() -> bool:
	if not has_rewarded_ad_for_current_failure():
		return false
	var ad: RewardedAd = _rewarded_ad
	_rewarded_ad = null
	_rewarded_run_id = current_failure_run_id
	_showing_rewarded = true
	rewarded_ads_changed.emit()
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		_finish_rewarded_ad(ad)
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		_finish_rewarded_ad(ad)
	var reward_listener := OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		_on_rewarded_ad_earned(_rewarded_run_id)
	ad.show(reward_listener)
	return true


func is_privacy_options_required() -> bool:
	return _privacy_options_required


func show_privacy_options() -> bool:
	if OS.get_name() != "Android" or not _privacy_options_required:
		return false
	_ads_requests_allowed = false
	_destroy_loaded_ads()
	_set_status("Datenschutzauswahl geöffnet")
	UserMessagingPlatform.show_privacy_options_form(_on_privacy_options_dismissed)
	return true


func register_failed_result_exit() -> void:
	if OS.get_name() != "Android" or not _ads_requests_allowed:
		return
	_failure_exit_count += 1
	if _failure_exit_count % INTERSTITIAL_FAILURE_INTERVAL != 0:
		_save_ad_state()
		return
	if not is_instance_valid(_interstitial_ad):
		_save_ad_state()
		return
	var now: int = int(Time.get_unix_time_from_system())
	_prune_ad_timestamps()
	if now - _last_interstitial_time < INTERSTITIAL_COOLDOWN_S:
		_save_ad_state()
		return
	if _interstitial_timestamps.size() >= INTERSTITIAL_DAILY_LIMIT:
		_save_ad_state()
		return
	var ad: InterstitialAd = _interstitial_ad
	_interstitial_ad = null
	_last_interstitial_time = now
	_interstitial_timestamps.append(now)
	_save_ad_state()
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		_finish_interstitial_ad(ad)
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		_finish_interstitial_ad(ad)
	ad.show()


func _request_consent() -> void:
	if not is_inside_tree():
		return
	_consent_request_active = true
	_set_status("Einwilligung wird geprüft")
	get_tree().create_timer(CALLBACK_TIMEOUT_S).timeout.connect(_on_consent_request_timeout, CONNECT_ONE_SHOT)
	var request := ConsentRequestParameters.new()
	if OS.has_feature("debug") or OS.has_feature("qa_release"):
		# The Android QA AVD is registered as a UMP test device. Keep its test
		# geography outside the EEA so the Google test-consent overlay cannot
		# block automated gameplay checks. Production builds always use the
		# device's actual geography and normal UMP flow.
		var debug_settings := ConsentDebugSettings.new()
		debug_settings.debug_geography = DebugGeography.Values.NOT_EEA
		debug_settings.test_device_hashed_ids.append("B3EEABB8EE11C2BE770B684D95219ECB")
		request.consent_debug_settings = debug_settings
	UserMessagingPlatform.consent_information.update(
		request,
		_on_consent_update_succeeded,
		_on_consent_update_failed
	)


func _on_consent_request_timeout() -> void:
	if not _consent_request_active:
		return
	_consent_request_active = false
	_block_ad_requests("Einwilligung nicht erreichbar · Spiel läuft ohne Werbung weiter")


func _on_consent_update_succeeded() -> void:
	if not _consent_request_active:
		return
	_consent_request_active = false
	_refresh_privacy_options_state()
	var consent_status: int = UserMessagingPlatform.consent_information.get_consent_status()
	_trace_qa("consent_updated status=%d privacy_options=%s" % [consent_status, _privacy_options_required])
	if consent_status == ConsentInformation.ConsentStatus.REQUIRED:
		_load_required_consent_form()
	elif _consent_status_allows_ads(consent_status):
		_initialize_mobile_ads()
	else:
		_block_ad_requests("Einwilligung nicht verfügbar · Spiel läuft ohne Werbung weiter")


func _on_consent_update_failed(error: FormError) -> void:
	if not _consent_request_active:
		return
	_consent_request_active = false
	_refresh_privacy_options_state()
	var consent_status: int = UserMessagingPlatform.consent_information.get_consent_status()
	if _consent_status_allows_ads(consent_status):
		_initialize_mobile_ads()
	else:
		_block_ad_requests("Einwilligung konnte nicht geprüft werden · %s" % str(error))


func _load_required_consent_form() -> void:
	if not UserMessagingPlatform.consent_information.get_is_consent_form_available():
		_block_ad_requests("Datenschutzauswahl ist nicht verfügbar · Spiel läuft ohne Werbung weiter")
		return
	_consent_form_active = true
	_set_status("Datenschutzauswahl wird geladen")
	get_tree().create_timer(CALLBACK_TIMEOUT_S).timeout.connect(_on_consent_form_timeout, CONNECT_ONE_SHOT)
	UserMessagingPlatform.load_consent_form(_on_consent_form_loaded, _on_consent_form_load_failed)


func _on_consent_form_timeout() -> void:
	if not _consent_form_active:
		return
	_consent_form_active = false
	_block_ad_requests("Datenschutzauswahl nicht erreichbar · Spiel läuft ohne Werbung weiter")


func _on_consent_form_loaded(form: ConsentForm) -> void:
	if not _consent_form_active:
		return
	_active_consent_form = form
	form.show(_on_consent_form_dismissed)


func _on_consent_form_load_failed(error: FormError) -> void:
	if not _consent_form_active:
		return
	_consent_form_active = false
	_block_ad_requests("Datenschutzauswahl konnte nicht geladen werden · %s" % str(error))


func _on_consent_form_dismissed(error: FormError) -> void:
	if not _consent_form_active:
		return
	_consent_form_active = false
	_active_consent_form = null
	_refresh_privacy_options_state()
	var consent_status: int = UserMessagingPlatform.consent_information.get_consent_status()
	_trace_qa("consent_form_dismissed status=%d error=%s" % [consent_status, str(error)])
	if error == null and _consent_status_allows_ads(consent_status):
		_initialize_mobile_ads()
	else:
		_block_ad_requests("Keine Anzeigenanfrage ohne gültige Datenschutzauswahl")


func _on_privacy_options_dismissed(error: FormError) -> void:
	_refresh_privacy_options_state()
	var consent_status: int = UserMessagingPlatform.consent_information.get_consent_status()
	if error == null and _consent_status_allows_ads(consent_status):
		_ads_requests_allowed = true
		_load_rewarded_ad()
		_load_interstitial_ad()
		_set_status("Datenschutzauswahl gespeichert")
	else:
		_block_ad_requests("Anzeigen bleiben nach der Datenschutzauswahl deaktiviert")


func _refresh_privacy_options_state() -> void:
	var required: bool = (
		UserMessagingPlatform.consent_information.get_privacy_options_requirement_status()
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
	)
	if required == _privacy_options_required:
		return
	_privacy_options_required = required
	privacy_options_changed.emit()


func _consent_status_allows_ads(consent_status: int) -> bool:
	return consent_status in [
		ConsentInformation.ConsentStatus.NOT_REQUIRED,
		ConsentInformation.ConsentStatus.OBTAINED
	]


func _initialize_mobile_ads() -> void:
	if _ads_initialized:
		_ads_requests_allowed = true
		_load_rewarded_ad()
		_load_interstitial_ad()
		return
	_set_status("Google Mobile Ads wird gestartet")
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = _on_mobile_ads_initialized
	get_tree().create_timer(CALLBACK_TIMEOUT_S).timeout.connect(_on_mobile_ads_initialization_timeout, CONNECT_ONE_SHOT)
	MobileAds.initialize(listener)


func _on_mobile_ads_initialization_timeout() -> void:
	if _ads_initialized:
		return
	_block_ad_requests("Anzeigen konnten nicht gestartet werden · Spiel läuft ohne Werbung weiter")


func _on_mobile_ads_initialized(_initialization_status: InitializationStatus) -> void:
	_ads_initialized = true
	_ads_requests_allowed = true
	_trace_qa("mobile_ads_initialized test_units=true")
	_set_status("Google-Testanzeigen werden geladen")
	_load_rewarded_ad()
	_load_interstitial_ad()


func _load_rewarded_ad() -> void:
	if not _ads_requests_allowed or _rewarded_loading or _showing_rewarded or is_instance_valid(_rewarded_ad):
		return
	if _reward_limit_reached():
		rewarded_ads_changed.emit()
		return
	_rewarded_loading = true
	_rewarded_load_callback = RewardedAdLoadCallback.new()
	_rewarded_load_callback.on_ad_loaded = _on_rewarded_ad_loaded
	_rewarded_load_callback.on_ad_failed_to_load = _on_rewarded_ad_load_failed
	var loader := RewardedAdLoader.new()
	loader.load(TEST_REWARDED_UNIT_ID, AdRequest.new(), _rewarded_load_callback)


func _on_rewarded_ad_loaded(ad: RewardedAd) -> void:
	_rewarded_loading = false
	if not _ads_requests_allowed:
		ad.destroy()
		return
	_rewarded_ad = ad
	_trace_qa("rewarded_test_ad_loaded")
	_set_status("Belohnungsvideo bereit")
	rewarded_ads_changed.emit()


func _on_rewarded_ad_load_failed(error: LoadAdError) -> void:
	_rewarded_loading = false
	_set_status("Belohnungsvideo derzeit nicht verfügbar")
	_trace_qa("rewarded_test_ad_failed error=%s" % str(error))
	push_warning("AdMob rewarded test ad failed to load: %s" % str(error))
	rewarded_ads_changed.emit()


func _on_rewarded_ad_earned(run_id: int) -> void:
	if not _showing_rewarded or run_id != _rewarded_run_id or _reward_claimed_runs.has(run_id):
		return
	_reward_claimed_runs[run_id] = true
	_rewarded_timestamps.append(int(Time.get_unix_time_from_system()))
	_prune_ad_timestamps()
	_save_ad_state()
	_trace_qa("rewarded_callback_earned run_id=%d amount=%d" % [run_id, REWARDED_COINS])
	rewarded_coins_earned.emit(REWARDED_COINS, run_id)
	rewarded_ads_changed.emit()


func _finish_rewarded_ad(ad: RewardedAd) -> void:
	if not _showing_rewarded:
		return
	_showing_rewarded = false
	_rewarded_run_id = -1
	if is_instance_valid(ad):
		ad.destroy()
	if _rewarded_ad == ad:
		_rewarded_ad = null
	_trace_qa("rewarded_ad_dismissed")
	rewarded_ads_changed.emit()
	_load_rewarded_ad()


func _load_interstitial_ad() -> void:
	if not _ads_requests_allowed or _interstitial_loading or is_instance_valid(_interstitial_ad):
		return
	_prune_ad_timestamps()
	if _interstitial_timestamps.size() >= INTERSTITIAL_DAILY_LIMIT:
		return
	_interstitial_loading = true
	_interstitial_load_callback = InterstitialAdLoadCallback.new()
	_interstitial_load_callback.on_ad_loaded = _on_interstitial_ad_loaded
	_interstitial_load_callback.on_ad_failed_to_load = _on_interstitial_ad_load_failed
	var loader := InterstitialAdLoader.new()
	loader.load(TEST_INTERSTITIAL_UNIT_ID, AdRequest.new(), _interstitial_load_callback)


func _on_interstitial_ad_loaded(ad: InterstitialAd) -> void:
	_interstitial_loading = false
	if not _ads_requests_allowed:
		ad.destroy()
		return
	_interstitial_ad = ad
	_trace_qa("interstitial_test_ad_loaded")


func _on_interstitial_ad_load_failed(error: LoadAdError) -> void:
	_interstitial_loading = false
	_trace_qa("interstitial_test_ad_failed error=%s" % str(error))
	push_warning("AdMob interstitial test ad failed to load: %s" % str(error))


func _finish_interstitial_ad(ad: InterstitialAd) -> void:
	if is_instance_valid(ad):
		ad.destroy()
	if _interstitial_ad == ad:
		_interstitial_ad = null
	_load_interstitial_ad()


func _destroy_loaded_ads() -> void:
	if is_instance_valid(_rewarded_ad):
		_rewarded_ad.destroy()
	_rewarded_ad = null
	if is_instance_valid(_interstitial_ad):
		_interstitial_ad.destroy()
	_interstitial_ad = null
	rewarded_ads_changed.emit()


func _block_ad_requests(message: String) -> void:
	_ads_requests_allowed = false
	_destroy_loaded_ads()
	_set_status(message)


func _set_status(message: String) -> void:
	if service_status == message:
		return
	service_status = message
	_trace_qa("status=%s" % message)
	service_status_changed.emit(message)


func _trace_qa(message: String) -> void:
	if QA_DIAGNOSTICS.enabled():
		print("[AD_QA] %s" % message)


func _load_ad_state() -> void:
	var config := ConfigFile.new()
	if config.load(ADS_STATE_PATH) != OK:
		return
	_failure_exit_count = maxi(0, int(config.get_value("limits", "failure_exits", 0)))
	_last_interstitial_time = maxi(0, int(config.get_value("limits", "last_interstitial", 0)))
	_read_timestamps(config.get_value("limits", "rewarded_timestamps", []), _rewarded_timestamps)
	_read_timestamps(config.get_value("limits", "interstitial_timestamps", []), _interstitial_timestamps)
	_prune_ad_timestamps()


func _read_timestamps(source: Variant, destination: Array[int]) -> void:
	destination.clear()
	if source is Array or source is PackedInt64Array or source is PackedInt32Array:
		for timestamp in source:
			destination.append(int(timestamp))


func _prune_ad_timestamps() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	_rewarded_timestamps = _recent_timestamps(_rewarded_timestamps, now)
	_interstitial_timestamps = _recent_timestamps(_interstitial_timestamps, now)


func _recent_timestamps(source: Array[int], now: int) -> Array[int]:
	var recent: Array[int] = []
	for timestamp in source:
		if timestamp <= now and now - timestamp < DAY_SECONDS:
			recent.append(timestamp)
	return recent


func _reward_limit_reached() -> bool:
	_prune_ad_timestamps()
	return _rewarded_timestamps.size() >= REWARDED_DAILY_LIMIT


func _save_ad_state() -> void:
	var config := ConfigFile.new()
	config.set_value("limits", "failure_exits", _failure_exit_count)
	config.set_value("limits", "last_interstitial", _last_interstitial_time)
	config.set_value("limits", "rewarded_timestamps", _rewarded_timestamps)
	config.set_value("limits", "interstitial_timestamps", _interstitial_timestamps)
	var error: Error = config.save(ADS_STATE_PATH)
	if error != OK:
		push_warning("Could not save AdMob frequency limits: %s" % error_string(error))
