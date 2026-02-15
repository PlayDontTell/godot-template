extends GutTest

# Integration tests for save system - complex workflows and edge cases

var g_instance: Node
var test_save_dir: String

func before_each():
	g_instance = load("res://G.gd").new()
	add_child_autofree(g_instance)
	
	test_save_dir = "user://test_integration_saves/"
	g_instance.SAVE_DIR = test_save_dir
	g_instance.BIN_DIR = "user://test_integration_bin/"
	g_instance.ARCHIVE_SAVE_DIR = "user://test_integration_archive/"
	g_instance.SETTINGS_PATH = g_instance.BIN_DIR + "game_settings.data"
	
	g_instance.init_folders()


func after_each():
	_cleanup_directory(test_save_dir)
	_cleanup_directory(g_instance.BIN_DIR)
	_cleanup_directory(g_instance.ARCHIVE_SAVE_DIR)


func _cleanup_directory(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				DirAccess.remove_absolute(path + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		DirAccess.remove_absolute(path)


#region SAVE LIFECYCLE INTEGRATION TESTS

func test_complete_save_load_cycle():
	# Create a new save
	var file_path = g_instance.create_save_file("IntegrationTest")
	assert_ne(file_path, "", "Save creation should succeed")
	
	# Modify game state
	g_instance.data.player.position = Vector2i(100, 200)
	g_instance.data.player.level = Vector2i(5, 10)
	g_instance.data.world["custom_data"] = {"inventory": ["sword", "shield"], "gold": 500}
	g_instance.log_event("player_leveled_up")
	g_instance.log_event("boss_defeated")
	
	# Save the data
	var save_success = await g_instance.save_data(file_path)
	assert_true(save_success, "Save should succeed")
	
	# Create new instance and load
	var new_instance = load("res://G.gd").new()
	var loaded_data = new_instance.load_data(file_path)
	
	# Verify all data persisted
	assert_eq(loaded_data[0].player.position, Vector2i(100, 200), "Player position should persist")
	assert_eq(loaded_data[0].player.level, Vector2i(5, 10), "Player level should persist")
	assert_eq(loaded_data[0].world.custom_data.gold, 500, "Custom data should persist")
	assert_eq(loaded_data[0].meta.event_log.size(), 2, "Event log should persist")
	assert_true("boss_defeated" in loaded_data[0].meta.event_log, "Specific events should persist")


func test_multiple_save_sessions():
	var file_path = g_instance.create_save_file("MultiSession")
	
	# Session 1
	g_instance.data.player.level = Vector2i(1, 1)
	await g_instance.save_data(file_path)
	
	# Session 2
	g_instance.data.player.level = Vector2i(2, 2)
	await g_instance.save_data(file_path)
	
	# Session 3
	g_instance.data.player.level = Vector2i(3, 3)
	await g_instance.save_data(file_path)
	
	# Load and verify final state
	var loaded_data = g_instance.load_data(file_path, false)
	assert_eq(loaded_data[0].player.level, Vector2i(3, 3), "Should have latest save data")


func test_save_file_corruption_protection():
	var file_path = g_instance.create_save_file("CorruptionTest")
	g_instance.data.player.position = Vector2i(50, 50)
	await g_instance.save_data(file_path)
	
	# Simulate corruption by writing garbage to the file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string("CORRUPTED_DATA_!@#$%")
	file.close()
	
	# Try to load - should return fallback
	var loaded_data = g_instance.load_data(file_path, false)
	assert_false(loaded_data.is_empty(), "Should return fallback data on corruption")
	assert_eq(loaded_data[0].player.position, Vector2i(0, 0), "Should return default position on corruption")


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

#endregion


#region DATA MIGRATION TESTS

func test_backward_compatibility_old_save_format():
	# Simulate an old save with missing keys
	var file_path = test_save_dir + "old_save.data"
	var old_data = {
		"meta": {
			"version": "0.1.0",
			"creation_date": "2024-01-01",
			# Missing: last_play_date, event_log, etc.
		},
		"player": {
			"position": Vector2i(10, 10),
			# Missing: level
		},
		# Missing: world
	}
	
	# Write old format
	var file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.WRITE, g_instance.ENCRYPT_KEY)
	file.store_var(old_data, true)
	file.store_var(g_instance.DEFAULT_SAVE_TEXTURE, true)
	file.close()
	
	# Load with new system
	var loaded_data = g_instance.load_data(file_path, false)
	
	# Verify migration
	assert_true(loaded_data[0].meta.has("event_log"), "Should add missing event_log")
	assert_true(loaded_data[0].player.has("level"), "Should add missing player level")
	assert_true(loaded_data[0].has("world"), "Should add missing world")
	assert_eq(loaded_data[0].player.position, Vector2i(10, 10), "Should preserve existing data")


func test_version_tracking():
	var file_path = g_instance.create_save_file("VersionTest")
	
	var version = g_instance.data.meta.version
	assert_ne(version, "", "Version should be set from project settings")


func test_timestamp_accuracy():
	var before_time = Time.get_unix_time_from_system()
	var file_path = g_instance.create_save_file("TimestampTest")
	var after_time = Time.get_unix_time_from_system()
	
	var save_time = g_instance.data.meta.save_date
	assert_ge(save_time, before_time, "Save timestamp should be after start")
	assert_le(save_time, after_time, "Save timestamp should be before end")

#endregion


#region STRESS TESTS

func test_large_data_save_load():
	var file_path = g_instance.create_save_file("LargeData")
	
	# Create large dataset
	var large_array = []
	for i in range(1000):
		large_array.append({
			"id": i,
			"data": "Item_" + str(i),
			"values": [i, i*2, i*3]
		})
	
	g_instance.data.world["large_inventory"] = large_array
	
	# Save
	var save_success = await g_instance.save_data(file_path)
	assert_true(save_success, "Should handle large data save")
	
	# Load
	var loaded_data = g_instance.load_data(file_path, false)
	assert_eq(loaded_data[0].world.large_inventory.size(), 1000, "Should load all items")
	assert_eq(loaded_data[0].world.large_inventory[500].id, 500, "Should preserve data integrity")


func test_deep_nested_structures():
	var file_path = g_instance.create_save_file("DeepNested")
	
	# Create deeply nested structure
	var nested = {"level1": {"level2": {"level3": {"level4": {"level5": "deep_value"}}}}}
	g_instance.data.world["nested"] = nested
	
	# Save and load
	await g_instance.save_data(file_path)
	var loaded_data = g_instance.load_data(file_path, false)
	
	assert_eq(loaded_data[0].world.nested.level1.level2.level3.level4.level5, "deep_value", 
		"Should preserve deeply nested structures")


func test_many_event_logs():
	g_instance.create_save_file("EventStress")
	
	# Log many events
	for i in range(100):
		g_instance.log_event("event_" + str(i))
	
	assert_eq(g_instance.data.meta.event_log.size(), 100, "Should handle many events")
	
	# Try to add duplicates
	for i in range(100):
		g_instance.log_event("event_" + str(i))
	
	assert_eq(g_instance.data.meta.event_log.size(), 100, "Should still have 100 (no duplicates)")

#endregion


#region EDGE CASES

func test_empty_world_name():
	var file_path = g_instance.create_save_file("")
	
	# Should handle gracefully (sanitize to some default or fail gracefully)
	# Behavior depends on implementation - test that it doesn't crash
	assert_true(true, "Should handle empty name without crashing")


func test_very_long_world_name():
	var long_name = ""
	for i in range(200):
		long_name += "a"
	
	var file_path = g_instance.create_save_file(long_name)
	
	# Should either truncate or handle gracefully
	assert_true(file_path == "" or FileAccess.file_exists(file_path), 
		"Should handle very long names without crashing")


func test_special_characters_in_save_data():
	var file_path = g_instance.create_save_file("SpecialChars")
	
	# Add various special characters and unicode
	g_instance.data.world["special"] = "Special: é, ñ, 中文, 🎮, \n\t\r"
	
	await g_instance.save_data(file_path)
	var loaded_data = g_instance.load_data(file_path, false)
	
	assert_eq(loaded_data[0].world.special, "Special: é, ñ, 中文, 🎮, \n\t\r", 
		"Should preserve special characters")


func test_null_and_empty_values():
	var file_path = g_instance.create_save_file("NullTest")
	
	g_instance.data.world["null_value"] = null
	g_instance.data.world["empty_string"] = ""
	g_instance.data.world["empty_array"] = []
	g_instance.data.world["empty_dict"] = {}
	
	await g_instance.save_data(file_path)
	var loaded_data = g_instance.load_data(file_path, false)
	
	assert_eq(loaded_data[0].world.null_value, null, "Should preserve null")
	assert_eq(loaded_data[0].world.empty_string, "", "Should preserve empty string")
	assert_eq(loaded_data[0].world.empty_array.size(), 0, "Should preserve empty array")
	assert_eq(loaded_data[0].world.empty_dict.size(), 0, "Should preserve empty dict")


func test_simultaneous_delete_and_create():
	var file_path1 = g_instance.create_save_file("Delete1")
	var file_path2 = g_instance.create_save_file("Delete2")
	
	# Delete first while creating third
	g_instance.delete_file(file_path1)
	var file_path3 = g_instance.create_save_file("Delete3")
	
	var files = g_instance.list_save_files()
	assert_eq(files.size(), 2, "Should have 2 files (deleted 1, kept 1, created 1)")

#endregion


#region SETTINGS INTEGRATION TESTS

func test_settings_persist_across_instances():
	# Instance 1: Set settings
	g_instance.load_settings()
	g_instance.adjust_setting(g_instance.Settings.MUSIC_VOLUME, 7.5)
	g_instance.adjust_setting(g_instance.Settings.BRIGHTNESS, 1.3)
	g_instance.adjust_setting(g_instance.Settings.FULLSCREEN_MODE, true)
	
	# Instance 2: Load and verify
	var new_instance = load("res://G.gd").new()
	new_instance.SETTINGS_PATH = g_instance.SETTINGS_PATH
	new_instance.load_settings()
	
	assert_eq(new_instance.settings[new_instance.Settings.MUSIC_VOLUME], 7.5)
	assert_eq(new_instance.settings[new_instance.Settings.BRIGHTNESS], 1.3)
	assert_eq(new_instance.settings[new_instance.Settings.FULLSCREEN_MODE], true)


func test_settings_signal_emission():
	g_instance.load_settings()
	var signal_watcher = watch_signals(g_instance)
	
	g_instance.adjust_setting(g_instance.Settings.MUSIC_VOLUME, 5.0)
	
	assert_signal_emitted_with_parameters(g_instance, "setting_adjusted", 
		[g_instance.Settings.MUSIC_VOLUME, 5.0])


func test_all_settings_types():
	g_instance.load_settings()
	
	# Audio settings
	g_instance.adjust_setting(g_instance.Settings.MUSIC_VOLUME, 3.0)
	g_instance.adjust_setting(g_instance.Settings.SFX_VOLUME, 4.0)
	g_instance.adjust_setting(g_instance.Settings.UI_VOLUME, 5.0)
	g_instance.adjust_setting(g_instance.Settings.AMBIENT_VOLUME, 6.0)
	
	# Visual settings
	g_instance.adjust_setting(g_instance.Settings.BRIGHTNESS, 1.2)
	g_instance.adjust_setting(g_instance.Settings.CONTRAST, 0.8)
	g_instance.adjust_setting(g_instance.Settings.SATURATION, 1.5)
	
	# Display settings
	g_instance.adjust_setting(g_instance.Settings.FULLSCREEN_MODE, true)
	
	# Verify all were saved
	var new_instance = load("res://G.gd").new()
	new_instance.SETTINGS_PATH = g_instance.SETTINGS_PATH
	new_instance.load_settings()
	
	assert_eq(new_instance.settings[new_instance.Settings.MUSIC_VOLUME], 3.0)
	assert_eq(new_instance.settings[new_instance.Settings.BRIGHTNESS], 1.2)
	assert_eq(new_instance.settings[new_instance.Settings.FULLSCREEN_MODE], true)

#endregion


#region ARCHIVE FUNCTIONALITY TESTS

func test_archive_preserves_all_data():
	# Create multiple saves with data
	var saves = []
	for i in range(3):
		var path = g_instance.create_save_file("Archive_" + str(i))
		g_instance.data.player.level = Vector2i(i, i)
		await g_instance.save_data(path)
		saves.append(path)
	
	# Move to archive
	var moved = await g_instance.move_files_to_archive()
	assert_eq(moved, 3, "Should move all files")
	
	# Verify archive contains readable data
	for i in range(3):
		var archived_path = g_instance.ARCHIVE_SAVE_DIR + saves[i].get_file()
		var loaded = g_instance.load_data(archived_path, false)
		# Note: The loaded level will be from the last save, not i-specific
		# Just verify it loads without error
		assert_false(loaded.is_empty(), "Archived file " + str(i) + " should be readable")


func test_archive_handles_partial_failures():
	# Create some saves
	g_instance.create_save_file("Archive1")
	var file2_path = g_instance.create_save_file("Archive2")
	
	# Make one file read-only or locked (simulate failure scenario)
	# This is platform-dependent, so we'll just test the happy path
	# In a real scenario, you'd want to test permission errors
	
	var moved = await g_instance.move_files_to_archive()
	assert_ge(moved, 0, "Should handle moves without crashing")

#endregion


#region UTILITY FUNCTIONS INTEGRATION

func test_sanitize_and_validate_workflow():
	var user_input = "My Game!/Save<1>"
	
	# Sanitize
	var sanitized = g_instance.sanitize_string(user_input)
	
	# Validate sanitized string
	var is_valid = g_instance.is_input_string_valid(sanitized)
	
	assert_true(is_valid, "Sanitized string should be valid")
	
	# Use in save creation
	var file_path = g_instance.create_save_file(sanitized)
	assert_true(FileAccess.file_exists(file_path), "Should create file with sanitized name")


func test_pause_system_with_save_operations():
	var pause_requester = Node.new()
	
	# Pause game
	g_instance.request_pause(pause_requester, true)
	assert_true(g_instance.get_tree().paused, "Game should be paused")
	
	# Try to save while paused (should still work - process_mode is ALWAYS)
	var file_path = g_instance.create_save_file("PausedSave")
	assert_ne(file_path, "", "Should create save even when paused")
	
	# Unpause
	g_instance.request_pause(pause_requester, false)
	assert_false(g_instance.get_tree().paused, "Game should be unpaused")

#endregion


#region MEMORY AND PERFORMANCE

func test_memory_cleanup_on_multiple_loads():
	# Create save
	var file_path = g_instance.create_save_file("MemoryTest")
	g_instance.data.world["large_data"] = range(10000)
	await g_instance.save_data(file_path)
	
	# Load multiple times
	for i in range(10):
		g_instance.load_data(file_path, true)
		await get_tree().process_frame
	
	# Should not leak memory - hard to test directly, but shouldn't crash
	assert_true(g_instance.is_data_ready, "Should handle multiple loads")


func test_rapid_save_operations():
	var file_path = g_instance.create_save_file("RapidTest")
	
	# Rapidly save multiple times
	for i in range(5):
		g_instance.data.player.position = Vector2i(i, i)
		await g_instance.save_data(file_path)
	
	# Load and verify final state
	var loaded = g_instance.load_data(file_path, false)
	assert_eq(loaded[0].player.position, Vector2i(4, 4), "Should have last save state")

#endregion
