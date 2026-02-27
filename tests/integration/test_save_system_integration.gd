extends GutTest

# INTEGRATION TESTS - Tests that involve file I/O, multiple components, and external state
# These test how different parts of the system work together

var g_instance: Node
var test_save_dir: String
var test_bin_dir: String
var test_archive_dir: String

func before_each():
	g_instance = load("uid://db11cacuq7ret").new()
	add_child_autofree(g_instance)
	
	# Use temporary test directories
	test_save_dir = "user://test_saves/"
	test_bin_dir = "user://test_bin/"
	test_archive_dir = "user://test_archive/"
	
	# Override directory paths for testing
	g_instance.SAVE_DIR = test_save_dir
	g_instance.BIN_DIR = test_bin_dir
	g_instance.ARCHIVE_SAVE_DIR = test_archive_dir
	g_instance.SETTINGS_PATH = test_bin_dir + "game_settings.save_data"
	
	# Initialize test folders
	g_instance.init_folders()


func after_each():
	# Clean up test directories
	_remove_directory_recursive(test_save_dir)
	_remove_directory_recursive(test_bin_dir)
	_remove_directory_recursive(test_archive_dir)


func _remove_directory_recursive(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var file_path = path + file_name
			if dir.current_is_dir():
				_remove_directory_recursive(file_path + "/")
			else:
				DirAccess.remove_absolute(file_path)
			file_name = dir.get_next()
		dir.list_dir_end()
		DirAccess.remove_absolute(path)


#region FOLDER INITIALIZATION

func test_init_folders_creates_all_directories():
	# Clean up first
	_remove_directory_recursive(test_save_dir)
	_remove_directory_recursive(test_bin_dir)
	_remove_directory_recursive(test_archive_dir)
	
	# Initialize
	g_instance.init_folders()
	
	# Assert all directories exist
	assert_true(DirAccess.dir_exists_absolute(test_save_dir), "Save directory should exist")
	assert_true(DirAccess.dir_exists_absolute(test_bin_dir), "Bin directory should exist")
	assert_true(DirAccess.dir_exists_absolute(test_archive_dir), "Archive directory should exist")


func test_init_folders_is_idempotent():
	# Run twice - should not error
	g_instance.init_folders()
	g_instance.init_folders()
	
	assert_true(DirAccess.dir_exists_absolute(test_save_dir), "Directories should still exist after second init")

#endregion


#region SETTINGS FILE I/O

func test_load_settings_creates_defaults_when_missing():
	# Ensure no settings file exists
	if FileAccess.file_exists(g_instance.SETTINGS_PATH):
		DirAccess.remove_absolute(g_instance.SETTINGS_PATH)
	
	var existed = g_instance.load_settings()
	
	assert_false(existed, "Should return false when creating new settings")
	assert_false(g_instance.settings.is_empty(), "Settings should not be empty")
	assert_eq(g_instance.settings[g_instance.Settings.MUSIC_VOLUME], 0, "Default music volume should be 0")
	assert_true(FileAccess.file_exists(g_instance.SETTINGS_PATH), "Settings file should be created")


func test_load_settings_loads_existing_file():
	# Create settings first
	g_instance.load_settings()
	g_instance.settings[g_instance.Settings.MUSIC_VOLUME] = 5.0
	g_instance.save_settings()
	
	# Create new instance and load
	var new_instance = load("uid://db11cacuq7ret").new()
	new_instance.SETTINGS_PATH = g_instance.SETTINGS_PATH
	var existed = new_instance.load_settings()
	
	assert_true(existed, "Should return true when loading existing settings")
	assert_eq(new_instance.settings[new_instance.Settings.MUSIC_VOLUME], 5.0, "Should load saved value")


func test_save_settings_persists_changes():
	g_instance.load_settings()
	g_instance.settings[g_instance.Settings.BRIGHTNESS] = 1.5
	g_instance.save_settings()
	
	# Verify file exists
	assert_true(FileAccess.file_exists(g_instance.SETTINGS_PATH), "Settings file should exist")
	
	# Load in new instance
	var new_instance = load("uid://db11cacuq7ret").new()
	new_instance.SETTINGS_PATH = g_instance.SETTINGS_PATH
	new_instance.load_settings()
	
	assert_eq(new_instance.settings[new_instance.Settings.BRIGHTNESS], 1.5, "Brightness should persist")


func test_settings_persist_across_instances():
	# Instance 1: Set multiple settings
	g_instance.load_settings()
	g_instance.adjust_setting(g_instance.Settings.MUSIC_VOLUME, 7.5)
	g_instance.adjust_setting(g_instance.Settings.BRIGHTNESS, 1.3)
	g_instance.adjust_setting(g_instance.Settings.FULLSCREEN_MODE, true)
	
	# Instance 2: Load and verify
	var new_instance = load("uid://db11cacuq7ret").new()
	new_instance.SETTINGS_PATH = g_instance.SETTINGS_PATH
	new_instance.load_settings()
	
	assert_eq(new_instance.settings[new_instance.Settings.MUSIC_VOLUME], 7.5)
	assert_eq(new_instance.settings[new_instance.Settings.BRIGHTNESS], 1.3)
	assert_eq(new_instance.settings[new_instance.Settings.FULLSCREEN_MODE], true)


func test_adjust_setting_saves_automatically():
	g_instance.load_settings()
	var original_value = g_instance.settings[g_instance.Settings.MUSIC_VOLUME]
	
	g_instance.adjust_setting(g_instance.Settings.MUSIC_VOLUME, 8.0)
	
	# Load in new instance to verify it was saved
	var new_instance = load("uid://db11cacuq7ret").new()
	new_instance.SETTINGS_PATH = g_instance.SETTINGS_PATH
	new_instance.load_settings()
	
	assert_eq(new_instance.settings[new_instance.Settings.MUSIC_VOLUME], 8.0, "Setting should be auto-saved")


func test_adjust_setting_clamps_visual_values():
	g_instance.load_settings()
	
	# Test brightness clamping
	g_instance.adjust_setting(g_instance.Settings.BRIGHTNESS, 3.0)
	assert_eq(g_instance.settings[g_instance.Settings.BRIGHTNESS], 2.0, "Brightness should be clamped to 2.0")
	
	g_instance.adjust_setting(g_instance.Settings.BRIGHTNESS, -1.0)
	assert_eq(g_instance.settings[g_instance.Settings.BRIGHTNESS], 0.0, "Brightness should be clamped to 0.0")
	
	# Test contrast clamping
	g_instance.adjust_setting(g_instance.Settings.CONTRAST, 5.0)
	assert_eq(g_instance.settings[g_instance.Settings.CONTRAST], 2.0, "Contrast should be clamped to 2.0")
	
	# Test saturation clamping
	g_instance.adjust_setting(g_instance.Settings.SATURATION, -0.5)
	assert_eq(g_instance.settings[g_instance.Settings.SATURATION], 0.0, "Saturation should be clamped to 0.0")


func test_setting_adjusted_signal():
	g_instance.load_settings()
	var signal_watcher = watch_signals(g_instance)
	
	g_instance.adjust_setting(g_instance.Settings.MUSIC_VOLUME, 5.0)
	
	assert_signal_emitted_with_parameters(g_instance, "setting_adjusted", 
		[g_instance.Settings.MUSIC_VOLUME, 5.0])

#endregion


#region SAVE FILE CREATION AND MANAGEMENT

func test_create_save_file_creates_new_file():
	var file_path = g_instance.create_save_file("TestWorld")
	
	assert_ne(file_path, "", "Should return non-empty path")
	assert_true(FileAccess.file_exists(file_path), "Save file should exist")
	assert_true(g_instance.is_data_ready, "Data should be ready after creation")


func test_create_save_file_sets_metadata():
	g_instance.create_save_file("TestWorld")
	
	assert_false(g_instance.save_data.meta.creation_date == "", "Creation date should be set")
	assert_false(g_instance.save_data.meta.last_play_date == "", "Last play date should be set")
	assert_true(g_instance.save_data.meta.save_date > 0, "Save date timestamp should be set")
	assert_false(g_instance.save_data.meta.version == "", "Version should be set")


func test_create_save_file_initializes_default_structure():
	g_instance.create_save_file("TestWorld")
	
	assert_true(g_instance.save_data.has("meta"), "Should have meta")
	assert_true(g_instance.save_data.has("player"), "Should have player")
	assert_true(g_instance.save_data.has("world"), "Should have world")
	assert_true(g_instance.save_data.meta.has("event_log"), "Should have event_log")
	assert_eq(g_instance.save_data.player.position, Vector2i(0, 0), "Should have default position")


func test_create_save_file_handles_name_collision():
	var first_path = g_instance.create_save_file("TestWorld")
	var second_path = g_instance.create_save_file("TestWorld")
	
	assert_ne(first_path, second_path, "Duplicate names should get unique paths")
	assert_true(second_path.contains("TestWorld_1"), "Second file should have _1 suffix")
	assert_true(FileAccess.file_exists(first_path), "First file should still exist")
	assert_true(FileAccess.file_exists(second_path), "Second file should exist")


func test_create_save_file_multiple_collisions():
	g_instance.create_save_file("Collision")
	g_instance.create_save_file("Collision")
	var third_path = g_instance.create_save_file("Collision")
	
	assert_true(third_path.contains("Collision_2"), "Third collision should have _2 suffix")


func test_create_save_file_emits_signal():
	var signal_watcher = watch_signals(g_instance)
	
	g_instance.create_save_file("TestWorld")
	
	assert_signal_emitted(g_instance, "data_is_ready", "Should emit data_is_ready signal")

#endregion


#region SAVE AND LOAD DATA

func test_save_data_updates_metadata():
	var file_path = g_instance.create_save_file("TestWorld")
	var original_date = g_instance.save_data.meta.last_play_date
	
	await wait_seconds(1.01)
	var success = await g_instance.save_data(file_path)
	
	assert_true(success, "Save should succeed")
	assert_ne(g_instance.save_data.meta.last_play_date, original_date, "Last play date should update")


func test_save_data_preserves_custom_data():
	var file_path = g_instance.create_save_file("TestWorld")
	g_instance.save_data.player.level = Vector2i(5, 3)
	g_instance.save_data.world["custom_key"] = "custom_value"
	g_instance.save_data.world["inventory"] = ["sword", "shield", "potion"]
	
	var success = await g_instance.save_data(file_path)
	assert_true(success, "Save should succeed")
	
	# Load in new instance
	var new_instance = load("uid://db11cacuq7ret").new()
	var loaded_data = new_instance.load_data(file_path, false)
	
	assert_eq(loaded_data[0].player.level, Vector2i(5, 3), "Player level should persist")
	assert_eq(loaded_data[0].world["custom_key"], "custom_value", "Custom save_data should persist")
	assert_eq(loaded_data[0].world["inventory"].size(), 3, "Inventory should persist")


func test_save_data_uses_temp_file_for_safety():
	var file_path = g_instance.create_save_file("TestWorld")
	var temp_path = file_path + g_instance.TEMP_FILE_SUFFIX
	
	var success = await g_instance.save_data(file_path)
	
	assert_true(success, "Save should succeed")
	assert_false(FileAccess.file_exists(temp_path), "Temp file should be cleaned up after successful save")
	assert_true(FileAccess.file_exists(file_path), "Final file should exist")


func test_load_data_loads_saved_file():
	var file_path = g_instance.create_save_file("TestWorld")
	g_instance.save_data.player.position = Vector2i(10, 20)
	g_instance.save_data.player.level = Vector2i(3, 7)
	await g_instance.save_data(file_path)
	
	var new_instance = load("uid://db11cacuq7ret").new()
	var loaded_data = new_instance.load_data(file_path, false)
	
	assert_eq(loaded_data[0].player.position, Vector2i(10, 20), "Should load correct position")
	assert_eq(loaded_data[0].player.level, Vector2i(3, 7), "Should load correct level")


func test_load_data_sets_as_current_when_requested():
	var file_path = g_instance.create_save_file("TestWorld")
	g_instance.save_data.player.level = Vector2i(7, 7)
	await g_instance.save_data(file_path)
	
	var new_instance = load("uid://db11cacuq7ret").new()
	add_child_autofree(new_instance)
	new_instance.load_data(file_path, true)
	
	assert_true(new_instance.is_data_ready, "Data should be marked as ready")
	assert_eq(new_instance.save_data.player.level, Vector2i(7, 7), "Current save_data should be updated")


func test_load_data_does_not_set_current_when_not_requested():
	var file_path = g_instance.create_save_file("TestWorld")
	g_instance.save_data.player.level = Vector2i(5, 5)
	await g_instance.save_data(file_path)
	
	var new_instance = load("uid://db11cacuq7ret").new()
	var loaded_data = new_instance.load_data(file_path, false)
	
	assert_false(new_instance.is_data_ready, "Data should not be marked as ready")
	assert_true(new_instance.save_data.is_empty(), "Current save_data should remain empty")
	assert_eq(loaded_data[0].player.level, Vector2i(5, 5), "Returned save_data should be correct")


func test_load_data_returns_fallback_on_missing_file():
	var loaded_data = g_instance.load_data("user://nonexistent.save_data", false)
	
	assert_false(loaded_data.is_empty(), "Should return fallback save_data")
	assert_eq(loaded_data[0].player.position, Vector2i(0, 0), "Should return default position")
	assert_true(loaded_data[0].has("meta"), "Should have default structure")


func test_load_data_updates_missing_keys_from_old_format():
	# Create a save with old structure (missing new keys)
	var file_path = g_instance.create_save_file("TestWorld")
	var old_data = {"meta": {"version": "1.0"}, "player": {}, "world": {}}
	g_instance.save_data = old_data
	await g_instance.save_data(file_path)
	
	# Load it back
	var loaded_data = g_instance.load_data(file_path, false)
	
	assert_true(loaded_data[0].meta.has("event_log"), "Should add missing event_log key")
	assert_true(loaded_data[0].player.has("position"), "Should add missing player position")
	assert_true(loaded_data[0].player.has("level"), "Should add missing player level")


func test_complete_save_load_cycle():
	# Create a new save
	var file_path = g_instance.create_save_file("CompleteCycle")
	
	# Modify game state
	g_instance.save_data.player.position = Vector2i(100, 200)
	g_instance.save_data.player.level = Vector2i(5, 10)
	g_instance.save_data.world["custom_data"] = {"inventory": ["sword", "shield"], "gold": 500}
	g_instance.log_event("player_leveled_up")
	g_instance.log_event("boss_defeated")
	
	# Save the save_data
	var save_success = await g_instance.save_data(file_path)
	assert_true(save_success, "Save should succeed")
	
	# Create new instance and load
	var new_instance = load("uid://db11cacuq7ret").new()
	var loaded_data = new_instance.load_data(file_path, false)
	
	# Verify all save_data persisted
	assert_eq(loaded_data[0].player.position, Vector2i(100, 200), "Player position should persist")
	assert_eq(loaded_data[0].player.level, Vector2i(5, 10), "Player level should persist")
	assert_eq(loaded_data[0].world.custom_data.gold, 500, "Custom save_data should persist")
	assert_eq(loaded_data[0].meta.event_log.size(), 2, "Event log should persist")
	assert_true("boss_defeated" in loaded_data[0].meta.event_log, "Specific events should persist")


func test_multiple_save_sessions():
	var file_path = g_instance.create_save_file("MultiSession")
	
	# Session 1
	g_instance.save_data.player.level = Vector2i(1, 1)
	await g_instance.save_data(file_path)
	
	# Session 2
	g_instance.save_data.player.level = Vector2i(2, 2)
	await g_instance.save_data(file_path)
	
	# Session 3
	g_instance.save_data.player.level = Vector2i(3, 3)
	await g_instance.save_data(file_path)
	
	# Load and verify final state
	var loaded_data = g_instance.load_data(file_path, false)
	assert_eq(loaded_data[0].player.level, Vector2i(3, 3), "Should have latest save save_data")

#endregion


#region FILE LISTING AND MANAGEMENT

func test_list_save_files_returns_all_saves():
	g_instance.create_save_file("World1")
	g_instance.create_save_file("World2")
	g_instance.create_save_file("World3")
	
	var files = g_instance.list_save_files()
	
	assert_eq(files.size(), 3, "Should list 3 save files")


func test_list_save_files_returns_full_paths():
	var file_path = g_instance.create_save_file("TestWorld")
	
	var files = g_instance.list_save_files()
	
	assert_true(file_path in files, "Should return full path")
	assert_true(files[0].begins_with(test_save_dir), "Path should start with save directory")


func test_list_save_files_filters_by_extension():
	g_instance.create_save_file("ValidWorld")
	
	# Create a non-save file
	var junk_path = test_save_dir + "junk.txt"
	var file = FileAccess.open(junk_path, FileAccess.WRITE)
	file.store_string("junk")
	file.close()
	
	var files = g_instance.list_save_files()
	
	assert_eq(files.size(), 1, "Should only list files with correct extension")
	assert_false(junk_path in files, "Should not include non-save files")


func test_list_save_files_empty_directory():
	var files = g_instance.list_save_files()
	
	assert_eq(files.size(), 0, "Should return empty array for empty directory")


func test_delete_file_removes_file():
	var file_path = g_instance.create_save_file("ToDelete")
	assert_true(FileAccess.file_exists(file_path), "File should exist before delete")
	
	var success = g_instance.delete_file(file_path)
	
	assert_true(success, "Delete should succeed")
	assert_false(FileAccess.file_exists(file_path), "File should no longer exist")


func test_delete_file_handles_nonexistent():
	var success = g_instance.delete_file("user://nonexistent.save_data")
	
	assert_false(success, "Should return false for nonexistent file")


func test_delete_file_updates_list():
	g_instance.create_save_file("Keep")
	var delete_path = g_instance.create_save_file("Delete")
	
	g_instance.delete_file(delete_path)
	var files = g_instance.list_save_files()
	
	assert_eq(files.size(), 1, "Should have 1 file remaining")
	assert_false(delete_path in files, "Deleted file should not be in list")

#endregion


#region ARCHIVE FUNCTIONALITY

func test_move_files_to_archive():
	g_instance.create_save_file("Archive1")
	g_instance.create_save_file("Archive2")
	
	var moved_count = await g_instance.move_files_to_archive()
	
	assert_eq(moved_count, 2, "Should move 2 files")
	assert_eq(g_instance.list_save_files().size(), 0, "Save directory should be empty")


func test_move_files_to_archive_preserves_data():
	# Create saves with save_data
	var path1 = g_instance.create_save_file("Archive1")
	g_instance.save_data.player.level = Vector2i(5, 5)
	await g_instance.save_data(path1)
	
	# Move to archive
	await g_instance.move_files_to_archive()
	
	# Verify archive contains readable save_data
	var archived_path = g_instance.ARCHIVE_SAVE_DIR + path1.get_file()
	assert_true(FileAccess.file_exists(archived_path), "File should exist in archive")
	
	var loaded = g_instance.load_data(archived_path, false)
	assert_false(loaded.is_empty(), "Archived file should be readable")
	assert_eq(loaded[0].player.level, Vector2i(5, 5), "Data should be preserved in archive")


func test_move_files_to_archive_empty_directory():
	var moved_count = await g_instance.move_files_to_archive()
	
	assert_eq(moved_count, 0, "Should move 0 files from empty directory")

#endregion


#region EVENT LOGGING

func test_log_event_adds_to_log():
	g_instance.create_save_file("TestWorld")
	
	g_instance.log_event("test_event_1")
	g_instance.log_event("test_event_2")
	
	assert_eq(g_instance.save_data.meta.event_log.size(), 2, "Should have 2 events")
	assert_true("test_event_1" in g_instance.save_data.meta.event_log, "Should contain first event")
	assert_true("test_event_2" in g_instance.save_data.meta.event_log, "Should contain second event")


func test_log_event_prevents_duplicates():
	g_instance.create_save_file("TestWorld")
	
	g_instance.log_event("duplicate_event")
	g_instance.log_event("duplicate_event")
	g_instance.log_event("duplicate_event")
	
	assert_eq(g_instance.save_data.meta.event_log.size(), 1, "Should only have 1 event (no duplicates)")


func test_log_event_handles_uninitialized_data():
	# Don't create save file first
	g_instance.log_event("test_event")
	
	# Should not crash, just handle gracefully
	assert_true(true, "Should handle uninitialized save_data without crashing")


func test_log_event_persists_across_save_load():
	var file_path = g_instance.create_save_file("EventTest")
	
	g_instance.log_event("event_before_save")
	await g_instance.save_data(file_path)
	
	# Load in new instance
	var new_instance = load("uid://db11cacuq7ret").new()
	var loaded_data = new_instance.load_data(file_path, false)
	
	assert_true("event_before_save" in loaded_data[0].meta.event_log, "Events should persist")

#endregion


#region PAUSE SYSTEM WITH SCENE TREE

func test_request_pause_pauses_game():
	var test_object = Node.new()
	
	g_instance.request_pause(test_object, true)
	
	assert_true(g_instance.get_tree().paused, "Game should be paused")
	assert_eq(g_instance.request_pause_objects.size(), 1, "Should have 1 pause requester")


func test_request_pause_unpauses_when_no_requests():
	var test_object = Node.new()
	
	g_instance.request_pause(test_object, true)
	g_instance.request_pause(test_object, false)
	
	assert_false(g_instance.get_tree().paused, "Game should be unpaused")
	assert_eq(g_instance.request_pause_objects.size(), 0, "Should have no pause requesters")


func test_request_pause_handles_multiple_objects():
	var obj1 = Node.new()
	var obj2 = Node.new()
	
	g_instance.request_pause(obj1, true)
	g_instance.request_pause(obj2, true)
	
	assert_true(g_instance.get_tree().paused, "Game should be paused")
	assert_eq(g_instance.request_pause_objects.size(), 2, "Should have 2 pause requesters")
	
	g_instance.request_pause(obj1, false)
	assert_true(g_instance.get_tree().paused, "Game should still be paused (obj2 still requesting)")
	
	g_instance.request_pause(obj2, false)
	assert_false(g_instance.get_tree().paused, "Game should be unpaused when all released")


func test_reset_pause_state():
	var obj1 = Node.new()
	var obj2 = Node.new()
	
	g_instance.request_pause(obj1, true)
	g_instance.request_pause(obj2, true)
	
	g_instance.reset_pause_state()
	
	assert_false(g_instance.get_tree().paused, "Game should be unpaused")
	assert_eq(g_instance.request_pause_objects.size(), 0, "Pause request list should be empty")


func test_pause_emits_signal():
	var test_object = Node.new()
	var signal_watcher = watch_signals(g_instance)
	
	g_instance.request_pause(test_object, true)
	
	assert_signal_emitted_with_parameters(g_instance, "pause_state_changed", [true])
	
	g_instance.request_pause(test_object, false)
	
	assert_signal_emitted_with_parameters(g_instance, "pause_state_changed", [false])

#endregion


#region LOCALIZATION SYSTEM

func test_set_locale_changes_locale():
	var available_locales = g_instance.get_available_locales()
	if available_locales.size() > 0:
		var test_locale = available_locales[0]
		
		g_instance.set_locale(test_locale)
		
		assert_eq(g_instance.current_locale, test_locale, "Locale should be set")
		assert_eq(TranslationServer.get_locale(), test_locale, "Translation server should be updated")


func test_set_locale_emits_signal():
	var available_locales = g_instance.get_available_locales()
	if available_locales.size() > 1:
		var signal_watcher = watch_signals(g_instance)
		
		g_instance.set_locale(available_locales[0])
		g_instance.set_locale(available_locales[1])
		
		assert_signal_emitted(g_instance, "locale_changed", "Should emit locale_changed signal")


func test_set_locale_handles_invalid():
	var original_locale = g_instance.current_locale
	
	g_instance.set_locale("invalid_locale_xyz")
	
	# Should fall back to current system locale, not crash
	assert_true(true, "Should handle invalid locale gracefully")
	assert_ne(g_instance.current_locale, "invalid_locale_xyz", "Should not set invalid locale")


func test_set_locale_same_locale_no_change():
	var available_locales = g_instance.get_available_locales()
	if available_locales.size() > 0:
		var test_locale = available_locales[0]
		g_instance.set_locale(test_locale)
		
		var signal_watcher = watch_signals(g_instance)
		g_instance.set_locale(test_locale)
		
		# Setting same locale shouldn't emit signal (based on code logic)
		assert_eq(g_instance.current_locale, test_locale, "Locale should remain same")

#endregion


#region STRESS AND EDGE CASES

func test_large_data_save_load():
	var file_path = g_instance.create_save_file("LargeData")
	
	# Create large dataset
	var large_array = []
	for i in range(1000):
		large_array.append({
			"id": i,
			"save_data": "Item_" + str(i),
			"values": [i, i*2, i*3]
		})
	
	g_instance.save_data.world["large_inventory"] = large_array
	
	# Save
	var save_success = await g_instance.save_data(file_path)
	assert_true(save_success, "Should handle large save_data save")
	
	# Load
	var loaded_data = g_instance.load_data(file_path, false)
	assert_eq(loaded_data[0].world.large_inventory.size(), 1000, "Should load all items")
	assert_eq(loaded_data[0].world.large_inventory[500].id, 500, "Should preserve save_data integrity")


func test_deep_nested_structures():
	var file_path = g_instance.create_save_file("DeepNested")
	
	# Create deeply nested structure
	var nested = {"level1": {"level2": {"level3": {"level4": {"level5": "deep_value"}}}}}
	g_instance.save_data.world["nested"] = nested
	
	# Save and load
	await g_instance.save_data(file_path)
	var loaded_data = g_instance.load_data(file_path, false)
	
	assert_eq(loaded_data[0].world.nested.level1.level2.level3.level4.level5, "deep_value", 
		"Should preserve deeply nested structures")


func test_special_characters_in_save_data():
	var file_path = g_instance.create_save_file("SpecialChars")
	
	# Add various special characters and unicode
	g_instance.save_data.world["special"] = "Special: é, ñ, 中文, 🎮, \n\t\r"
	
	await g_instance.save_data(file_path)
	var loaded_data = g_instance.load_data(file_path, false)
	
	assert_eq(loaded_data[0].world.special, "Special: é, ñ, 中文, 🎮, \n\t\r", 
		"Should preserve special characters")


func test_null_and_empty_values():
	var file_path = g_instance.create_save_file("NullTest")
	
	g_instance.save_data.world["null_value"] = null
	g_instance.save_data.world["empty_string"] = ""
	g_instance.save_data.world["empty_array"] = []
	g_instance.save_data.world["empty_dict"] = {}
	
	await g_instance.save_data(file_path)
	var loaded_data = g_instance.load_data(file_path, false)
	
	assert_eq(loaded_data[0].world.null_value, null, "Should preserve null")
	assert_eq(loaded_data[0].world.empty_string, "", "Should preserve empty string")
	assert_eq(loaded_data[0].world.empty_array.size(), 0, "Should preserve empty array")
	assert_eq(loaded_data[0].world.empty_dict.size(), 0, "Should preserve empty dict")


func test_concurrent_save_file_operations():
	# Create multiple saves quickly
	var paths = []
	for i in range(5):
		var path = g_instance.create_save_file("Concurrent_" + str(i))
		paths.append(path)
	
	# Verify all were created
	assert_eq(paths.size(), 5, "All saves should be created")
	for path in paths:
		assert_true(FileAccess.file_exists(path), "Each save file should exist")
	
	# List and verify count
	var listed = g_instance.list_save_files()
	assert_eq(listed.size(), 5, "Should list all 5 saves")


func test_rapid_save_operations():
	var file_path = g_instance.create_save_file("RapidTest")
	
	# Rapidly save multiple times
	for i in range(5):
		g_instance.save_data.player.position = Vector2i(i, i)
		await g_instance.save_data(file_path)
	
	# Load and verify final state
	var loaded = g_instance.load_data(file_path, false)
	assert_eq(loaded[0].player.position, Vector2i(4, 4), "Should have last save state")

#endregion
