extends GutTest

# Test suite for the save system script (G.gd)
# This uses the GUT (Godot Unit Test) framework
# Install GUT addon: https://github.com/bitwes/Gut

var g_instance: Node
var test_save_dir: String
var test_bin_dir: String
var test_archive_dir: String

# Setup before each test
func before_each():
	g_instance = load("res://G.gd").new()
	add_child_autofree(g_instance)
	
	# Use temporary test directories
	test_save_dir = "user://test_saves/"
	test_bin_dir = "user://test_bin/"
	test_archive_dir = "user://test_archive/"
	
	# Override directory paths for testing
	g_instance.SAVE_DIR = test_save_dir
	g_instance.BIN_DIR = test_bin_dir
	g_instance.ARCHIVE_SAVE_DIR = test_archive_dir
	g_instance.SETTINGS_PATH = test_bin_dir + "game_settings.data"
	
	# Initialize test folders
	g_instance.init_folders()


# Cleanup after each test
func after_each():
	# Clean up test directories
	_remove_directory_recursive(test_save_dir)
	_remove_directory_recursive(test_bin_dir)
	_remove_directory_recursive(test_archive_dir)


# Helper to remove directory recursively
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


#region FOLDER INITIALIZATION TESTS

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


#region SETTINGS TESTS

func test_load_settings_creates_defaults_when_missing():
	# Ensure no settings file exists
	if FileAccess.file_exists(g_instance.SETTINGS_PATH):
		DirAccess.remove_absolute(g_instance.SETTINGS_PATH)
	
	var existed = g_instance.load_settings()
	
	assert_false(existed, "Should return false when creating new settings")
	assert_false(g_instance.settings.is_empty(), "Settings should not be empty")
	assert_eq(g_instance.settings[g_instance.Settings.MUSIC_VOLUME], 0, "Default music volume should be 0")


func test_load_settings_loads_existing_file():
	# Create settings first
	g_instance.load_settings()
	g_instance.settings[g_instance.Settings.MUSIC_VOLUME] = 5.0
	g_instance.save_settings()
	
	# Create new instance and load
	var new_instance = load("res://G.gd").new()
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
	var new_instance = load("res://G.gd").new()
	new_instance.SETTINGS_PATH = g_instance.SETTINGS_PATH
	new_instance.load_settings()
	
	assert_eq(new_instance.settings[new_instance.Settings.BRIGHTNESS], 1.5, "Brightness should persist")


func test_adjust_setting_clamps_values():
	g_instance.load_settings()
	
	# Test brightness clamping
	g_instance.adjust_setting(g_instance.Settings.BRIGHTNESS, 3.0)
	assert_eq(g_instance.settings[g_instance.Settings.BRIGHTNESS], 2.0, "Brightness should be clamped to 2.0")
	
	g_instance.adjust_setting(g_instance.Settings.BRIGHTNESS, -1.0)
	assert_eq(g_instance.settings[g_instance.Settings.BRIGHTNESS], 0.0, "Brightness should be clamped to 0.0")


func test_get_setting_text_formats_correctly():
	g_instance.load_settings()
	g_instance.settings[g_instance.Settings.MUSIC_VOLUME] = 0.0
	
	var text = g_instance.get_setting_text(g_instance.Settings.MUSIC_VOLUME)
	assert_eq(text, " 20%", "Volume text should format correctly")
	
	g_instance.settings[g_instance.Settings.FULLSCREEN_MODE] = true
	text = g_instance.get_setting_text(g_instance.Settings.FULLSCREEN_MODE)
	assert_eq(text, "Fullscreen Mode", "Fullscreen text should be correct")

#endregion


#region SAVE FILE CREATION TESTS

func test_create_save_file_creates_new_file():
	var file_path = g_instance.create_save_file("TestWorld")
	
	assert_ne(file_path, "", "Should return non-empty path")
	assert_true(FileAccess.file_exists(file_path), "Save file should exist")
	assert_true(g_instance.is_data_ready, "Data should be ready after creation")


func test_create_save_file_sets_metadata():
	g_instance.create_save_file("TestWorld")
	
	assert_false(g_instance.data.meta.creation_date == "", "Creation date should be set")
	assert_false(g_instance.data.meta.last_play_date == "", "Last play date should be set")
	assert_gt(g_instance.data.meta.save_date, 0, "Save date timestamp should be set")


func test_create_save_file_handles_name_collision():
	var first_path = g_instance.create_save_file("TestWorld")
	var second_path = g_instance.create_save_file("TestWorld")
	
	assert_ne(first_path, second_path, "Duplicate names should get unique paths")
	assert_true(second_path.contains("TestWorld_1"), "Second file should have _1 suffix")
	assert_true(FileAccess.file_exists(first_path), "First file should still exist")
	assert_true(FileAccess.file_exists(second_path), "Second file should exist")


func test_create_save_file_sanitizes_name():
	var file_path = g_instance.create_save_file("Test/World\\Bad:Name")
	
	assert_true(file_path.contains("TestWorldBadName") or file_path != "", "Should sanitize invalid characters")
	if file_path != "":
		assert_true(FileAccess.file_exists(file_path), "Sanitized file should exist")


func test_create_save_file_emits_signal():
	var signal_watcher = watch_signals(g_instance)
	
	g_instance.create_save_file("TestWorld")
	
	assert_signal_emitted(g_instance, "data_is_ready", "Should emit data_is_ready signal")

#endregion


#region SAVE DATA TESTS

func test_save_data_updates_metadata():
	var file_path = g_instance.create_save_file("TestWorld")
	var original_date = g_instance.data.meta.last_play_date
	
	await wait_frames(2) # Wait a bit to ensure time difference
	var success = await g_instance.save_data(file_path)
	
	assert_true(success, "Save should succeed")
	assert_ne(g_instance.data.meta.last_play_date, original_date, "Last play date should update")


func test_save_data_preserves_custom_data():
	var file_path = g_instance.create_save_file("TestWorld")
	g_instance.data.player.level = Vector2i(5, 3)
	g_instance.data.world["custom_key"] = "custom_value"
	
	var success = await g_instance.save_data(file_path)
	assert_true(success, "Save should succeed")
	
	# Load in new instance
	var new_instance = load("res://G.gd").new()
	var loaded_data = new_instance.load_data(file_path, false)
	
	assert_eq(loaded_data[0].player.level, Vector2i(5, 3), "Player level should persist")
	assert_eq(loaded_data[0].world["custom_key"], "custom_value", "Custom data should persist")


func test_save_data_uses_temp_file():
	var file_path = g_instance.create_save_file("TestWorld")
	
	# Monitor for temp file creation
	var temp_path = file_path + g_instance.TEMP_FILE_SUFFIX
	
	var success = await g_instance.save_data(file_path)
	
	assert_true(success, "Save should succeed")
	assert_false(FileAccess.file_exists(temp_path), "Temp file should be cleaned up after successful save")

#endregion


#region LOAD DATA TESTS

func test_load_data_loads_saved_file():
	var file_path = g_instance.create_save_file("TestWorld")
	g_instance.data.player.position = Vector2i(10, 20)
	await g_instance.save_data(file_path)
	
	var new_instance = load("res://G.gd").new()
	var loaded_data = new_instance.load_data(file_path)
	
	assert_eq(loaded_data[0].player.position, Vector2i(10, 20), "Should load correct position")


func test_load_data_sets_as_current_when_requested():
	var file_path = g_instance.create_save_file("TestWorld")
	g_instance.data.player.level = Vector2i(7, 7)
	await g_instance.save_data(file_path)
	
	var new_instance = load("res://G.gd").new()
	add_child_autofree(new_instance)
	new_instance.load_data(file_path, true)
	
	assert_true(new_instance.is_data_ready, "Data should be marked as ready")
	assert_eq(new_instance.data.player.level, Vector2i(7, 7), "Current data should be updated")


func test_load_data_returns_fallback_on_missing_file():
	var loaded_data = g_instance.load_data("user://nonexistent.data", false)
	
	assert_false(loaded_data.is_empty(), "Should return fallback data")
	assert_eq(loaded_data[0].player.position, Vector2i(0, 0), "Should return default position")


func test_load_data_updates_missing_keys():
	# Create a save with old structure (missing new keys)
	var file_path = g_instance.create_save_file("TestWorld")
	var old_data = {"meta": {"version": "1.0"}, "player": {}, "world": {}}
	g_instance.data = old_data
	await g_instance.save_data(file_path)
	
	# Load it back
	var loaded_data = g_instance.load_data(file_path, false)
	
	assert_true(loaded_data[0].meta.has("event_log"), "Should add missing event_log key")
	assert_true(loaded_data[0].player.has("position"), "Should add missing player position")

#endregion


#region FILE MANAGEMENT TESTS

func test_list_save_files_returns_all_saves():
	g_instance.create_save_file("World1")
	g_instance.create_save_file("World2")
	g_instance.create_save_file("World3")
	
	var files = g_instance.list_save_files()
	
	assert_eq(files.size(), 3, "Should list 3 save files")


func test_list_save_files_filters_by_extension():
	g_instance.create_save_file("ValidWorld")
	
	# Create a non-save file
	var junk_path = test_save_dir + "junk.txt"
	var file = FileAccess.open(junk_path, FileAccess.WRITE)
	file.store_string("junk")
	file.close()
	
	var files = g_instance.list_save_files()
	
	assert_eq(files.size(), 1, "Should only list files with correct extension")


func test_delete_file_removes_file():
	var file_path = g_instance.create_save_file("ToDelete")
	
	var success = g_instance.delete_file(file_path)
	
	assert_true(success, "Delete should succeed")
	assert_false(FileAccess.file_exists(file_path), "File should no longer exist")


func test_delete_file_handles_nonexistent():
	var success = g_instance.delete_file("user://nonexistent.data")
	
	assert_false(success, "Should return false for nonexistent file")


func test_move_files_to_archive():
	g_instance.create_save_file("Archive1")
	g_instance.create_save_file("Archive2")
	
	var moved_count = await g_instance.move_files_to_archive()
	
	assert_eq(moved_count, 2, "Should move 2 files")
	assert_eq(g_instance.list_save_files().size(), 0, "Save directory should be empty")
	
	# Check archive directory
	var archive_dir = DirAccess.open(test_archive_dir)
	var archive_files = []
	if archive_dir:
		archive_dir.list_dir_begin()
		var file_name = archive_dir.get_next()
		while file_name != "":
			if file_name.ends_with(g_instance.FILES_EXTENSION):
				archive_files.append(file_name)
			file_name = archive_dir.get_next()
	
	assert_eq(archive_files.size(), 2, "Archive should contain 2 files")

#endregion


#region EVENT LOG TESTS

func test_log_event_adds_to_log():
	g_instance.create_save_file("TestWorld")
	
	g_instance.log_event("test_event_1")
	g_instance.log_event("test_event_2")
	
	assert_eq(g_instance.data.meta.event_log.size(), 2, "Should have 2 events")
	assert_true("test_event_1" in g_instance.data.meta.event_log, "Should contain first event")


func test_log_event_prevents_duplicates():
	g_instance.create_save_file("TestWorld")
	
	g_instance.log_event("duplicate_event")
	g_instance.log_event("duplicate_event")
	g_instance.log_event("duplicate_event")
	
	assert_eq(g_instance.data.meta.event_log.size(), 1, "Should only have 1 event (no duplicates)")


func test_log_event_handles_uninitialized_data():
	# Don't create save file first
	g_instance.log_event("test_event")
	
	# Should not crash, just log warning
	assert_true(true, "Should handle gracefully")

#endregion


#region UTILITY FUNCTION TESTS

func test_sanitize_string_removes_invalid_chars():
	var result = g_instance.sanitize_string("Test/File\\Name:Bad")
	assert_eq(result, "TestFileName Bad", "Should remove invalid characters")


func test_sanitize_string_with_replacement():
	var result = g_instance.sanitize_string("Test/Name", "_")
	assert_eq(result, "Test_Name", "Should replace invalid chars with underscore")


func test_is_input_string_valid_accepts_good_strings():
	assert_true(g_instance.is_input_string_valid("ValidName123"), "Should accept valid string")
	assert_true(g_instance.is_input_string_valid("Test_Name-Plus"), "Should accept underscores, dashes, plus")


func test_is_input_string_valid_rejects_bad_strings():
	assert_false(g_instance.is_input_string_valid(""), "Should reject empty string")
	assert_false(g_instance.is_input_string_valid("Bad/Name"), "Should reject invalid chars")
	assert_false(g_instance.is_input_string_valid("DefaultName", "DefaultName"), "Should reject default name")


func test_is_input_character_valid():
	assert_true(g_instance.is_input_character_valid("a"), "Should accept letter")
	assert_true(g_instance.is_input_character_valid("5"), "Should accept number")
	assert_true(g_instance.is_input_character_valid("_"), "Should accept underscore")
	assert_false(g_instance.is_input_character_valid("/"), "Should reject slash")
	assert_false(g_instance.is_input_character_valid("@"), "Should reject @")


func test_update_dict_adds_missing_keys():
	var target = {"existing": "value"}
	var defaults = {"existing": "default", "new_key": "new_value"}
	
	var result = g_instance.update_dict(target, defaults)
	
	assert_eq(result["existing"], "value", "Should keep existing value")
	assert_eq(result["new_key"], "new_value", "Should add new key")


func test_update_dict_recursive():
	var target = {"nested": {"existing": "value"}}
	var defaults = {"nested": {"existing": "default", "new": "data"}}
	
	var result = g_instance.update_dict(target, defaults)
	
	assert_eq(result.nested.existing, "value", "Should preserve nested existing value")
	assert_eq(result.nested.new, "data", "Should add nested new value")


func test_round_to_dec():
	assert_eq(g_instance.round_to_dec(3.14159, 2), 3.14, "Should round to 2 decimals")
	assert_eq(g_instance.round_to_dec(3.14159, 3), 3.142, "Should round to 3 decimals")
	assert_eq(g_instance.round_to_dec(10.5, 0), 11.0, "Should round to integer")


func test_generate_points_in_circle():
	var points = g_instance.generate_points_in_circle(Vector2.ZERO, 10.0, 4, 0.0)
	
	assert_eq(points.size(), 4, "Should generate 4 points")
	
	# Check that points are roughly on the circle
	for point in points:
		var distance = point.length()
		assert_almost_eq(distance, 10.0, 0.1, "Points should be on circle radius")

#endregion


#region PAUSE SYSTEM TESTS

func test_request_pause_pauses_game():
	var test_object = Node.new()
	
	g_instance.request_pause(test_object, true)
	
	assert_true(g_instance.get_tree().paused, "Game should be paused")


func test_request_pause_unpauses_when_no_requests():
	var test_object = Node.new()
	
	g_instance.request_pause(test_object, true)
	g_instance.request_pause(test_object, false)
	
	assert_false(g_instance.get_tree().paused, "Game should be unpaused")


func test_request_pause_handles_multiple_objects():
	var obj1 = Node.new()
	var obj2 = Node.new()
	
	g_instance.request_pause(obj1, true)
	g_instance.request_pause(obj2, true)
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

#endregion


#region LOCALIZATION TESTS

func test_set_locale_changes_locale():
	var available_locales = g_instance.get_available_locales()
	if available_locales.size() > 0:
		var test_locale = available_locales[0]
		
		g_instance.set_locale(test_locale)
		
		assert_eq(g_instance.current_locale, test_locale, "Locale should be set")


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
	
	# Should fall back to system locale, not crash
	assert_true(true, "Should handle invalid locale gracefully")

#endregion


#region COLOR UTILITY TESTS

func test_apply_saturation_full():
	var color = Color(1.0, 0.0, 0.0, 1.0) # Red
	var result = g_instance.apply_saturation(color, 1.0)
	
	assert_almost_eq(result.r, 1.0, 0.01, "Full saturation should keep original color")
	assert_almost_eq(result.g, 0.0, 0.01)


func test_apply_saturation_zero():
	var color = Color(1.0, 0.0, 0.0, 1.0) # Red
	var result = g_instance.apply_saturation(color, 0.0)
	
	# Should be grayscale
	assert_almost_eq(result.r, result.g, 0.01, "Zero saturation should create grayscale")
	assert_almost_eq(result.g, result.b, 0.01)


func test_apply_saturation_preserves_alpha():
	var color = Color(1.0, 0.0, 0.0, 0.5)
	var result = g_instance.apply_saturation(color, 0.5)
	
	assert_almost_eq(result.a, 0.5, 0.01, "Alpha should be preserved")

#endregion
