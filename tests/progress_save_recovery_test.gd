extends Node

const SAVE_PATH: String = "user://progress.cfg"
const SAVE_TEMP_PATH: String = "user://progress.cfg.tmp"
const SAVE_BACKUP_PATH: String = "user://progress.cfg.bak"
const SAVE_CORRUPT_PATH: String = "user://progress.cfg.corrupt"
const SAVE_INTEGRITY_SECTION: String = "zz_save_integrity"
const SAVE_INTEGRITY_MARKER: String = "ZEE_SAVE_COMPLETE_V1"
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_remove_save_file(SAVE_PATH)
	_remove_save_file(SAVE_TEMP_PATH)
	_remove_save_file(SAVE_BACKUP_PATH)
	_remove_save_file(SAVE_CORRUPT_PATH)
	_write_profile(SAVE_PATH, 1001, 5, 12)
	_write_profile(SAVE_TEMP_PATH, 1002, 4, 12)
	_write_profile(SAVE_BACKUP_PATH, 1003, 3, 12)

	var game: Node = MAIN_SCENE.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	assert(int(game.money) == 1001, "A valid primary save with the newest generation should load ahead of older recovery files.")
	assert(String(game._last_progress_load_source) == "primary", "A valid primary save should be selected first when its generation is newest.")

	_write_corrupt_file(SAVE_PATH)
	_write_profile(SAVE_TEMP_PATH, 2002, 7, 12)
	_write_profile(SAVE_BACKUP_PATH, 2001, 6, 12)
	game._load_progress()
	assert(int(game.money) == 2002, "A complete temporary save should recover progress after an interrupted replacement.")
	assert(String(game._last_progress_load_source) == "temporary", "The highest valid temporary generation should be reported as the recovery source.")
	assert(_read_money(SAVE_PATH) == 2002, "Recovered temporary data should be restored as the primary save.")

	_write_corrupt_file(SAVE_PATH)
	_write_corrupt_file(SAVE_TEMP_PATH)
	_write_profile(SAVE_BACKUP_PATH, 3003, 8, 12)
	game._load_progress()
	assert(int(game.money) == 3003, "A valid backup should recover progress when the primary and temporary files are corrupt.")
	assert(String(game._last_progress_load_source) == "backup", "Backup recovery should be reported accurately.")
	assert(_read_money(SAVE_PATH) == 3003, "Backup data should be restored as the primary save.")

	_remove_save_file(SAVE_TEMP_PATH)
	_remove_save_file(SAVE_BACKUP_PATH)
	_write_profile(SAVE_PATH, 4004, 0, 9)
	game._load_progress()
	assert(int(game.money) == 4004, "A valid schema 9 profile should load without losing currency.")
	var migrated_primary: ConfigFile = _read_config(SAVE_PATH)
	assert(int(migrated_primary.get_value("campaign", "schema", 0)) == 12, "A schema 9 profile should migrate to the current schema 12.")
	assert(String(migrated_primary.get_value(SAVE_INTEGRITY_SECTION, "complete", "")) == SAVE_INTEGRITY_MARKER, "Migrated profiles should include the completion marker.")
	assert(int(migrated_primary.get_value(SAVE_INTEGRITY_SECTION, "generation", 0)) == 1, "A first transactional save should begin at generation 1.")
	assert(int(_read_config(SAVE_BACKUP_PATH).get_value("campaign", "schema", 0)) == 9, "Migration should retain the previous valid profile as a backup.")

	game.money = 5005
	game._save_progress()
	var newest_primary: ConfigFile = _read_config(SAVE_PATH)
	var previous_backup: ConfigFile = _read_config(SAVE_BACKUP_PATH)
	assert(int(newest_primary.get_value("progress", "money", 0)) == 5005, "The primary save should contain the latest currency after a successful save.")
	assert(int(newest_primary.get_value(SAVE_INTEGRITY_SECTION, "generation", 0)) == 2, "Every successful save should advance its generation.")
	assert(int(previous_backup.get_value("progress", "money", 0)) == 4004, "The backup should retain the prior valid progress generation.")
	assert(not FileAccess.file_exists(SAVE_TEMP_PATH), "A committed temporary save should be renamed away from the staging path.")

	_write_corrupt_file(SAVE_PATH)
	_write_profile(SAVE_TEMP_PATH, 6006, 4, 12)
	_write_profile(SAVE_BACKUP_PATH, 6005, 3, 12)
	game._load_progress()
	assert(int(game.money) == 6006, "Recovery should choose a fully written temporary generation ahead of an older backup.")
	assert(_read_money(SAVE_PATH) == 6006, "The recovered newest temporary generation should be restored to the primary path.")

	_write_corrupt_file(SAVE_PATH)
	_write_corrupt_file(SAVE_TEMP_PATH)
	_write_corrupt_file(SAVE_BACKUP_PATH)
	game.money = 100
	game._load_progress()
	assert(int(game.money) == 100, "When every save candidate is corrupt, startup defaults should remain usable.")
	assert(String(game._last_progress_load_source) == "defaults", "The default profile should be reported when no candidate is valid.")
	assert(FileAccess.file_exists(SAVE_PATH), "Loading a corrupt profile should not destructively replace its source file.")

	game.money = 7007
	game._save_progress()
	assert(_read_money(SAVE_PATH) == 7007, "A new valid profile should be writable after a corrupt save is detected.")
	assert(FileAccess.file_exists(SAVE_CORRUPT_PATH), "The original corrupt profile should be preserved before a new save replaces it.")
	assert(not FileAccess.file_exists(SAVE_TEMP_PATH), "The replacement profile should commit from staging to the primary path.")

	print("PROGRESS_SAVE_RECOVERY_OK primary_precedence=true temporary_recovery=true backup_recovery=true schema9_migration=true generation_rotation=true corrupt_preserved=true")
	game.free()
	await get_tree().process_frame
	get_tree().quit()

func _write_profile(path: String, profile_money: int, generation: int, schema: int) -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "money", profile_money)
	config.set_value("campaign", "schema", schema)
	config.set_value("campaign", "selected_world", 0)
	config.set_value("campaign", "unlocked_world", 0)
	if schema >= 10:
		config.set_value(SAVE_INTEGRITY_SECTION, "generation", generation)
		config.set_value(SAVE_INTEGRITY_SECTION, "complete", SAVE_INTEGRITY_MARKER)
	var save_error: Error = config.save(path)
	assert(save_error == OK, "Test profile should be writable at %s." % path)

func _write_corrupt_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "Corrupt fixture should be writable at %s." % path)
	file.store_string("[progress]\nmoney=999\n[campaign]\nschema=10\n")
	file.close()

func _remove_save_file(path: String) -> void:
	if FileAccess.file_exists(path):
		var remove_error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		assert(remove_error == OK, "Test fixture should be removable at %s." % path)

func _read_config(path: String) -> ConfigFile:
	var config := ConfigFile.new()
	assert(config.load(path) == OK, "Expected a readable config file at %s." % path)
	return config

func _read_money(path: String) -> int:
	return int(_read_config(path).get_value("progress", "money", -1))
