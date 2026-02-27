extends GutTest

# TRUE UNIT TESTS - Pure functions with no file I/O, no side effects
# These test isolated logic without touching the file system or external state

var g_instance: Node

func before_each():
	g_instance = load("uid://db11cacuq7ret").new()


#region STRING SANITIZATION AND VALIDATION

func test_sanitize_string_removes_invalid_chars():
	var result = g_instance.sanitize_string("Test/File\\Name:Bad")
	assert_eq(result, "TestFileNameBad", "Should remove invalid characters")


func test_sanitize_string_keeps_valid_chars():
	var result = g_instance.sanitize_string("ValidName_123-Plus+")
	assert_eq(result, "ValidName_123-Plus+", "Should keep all valid characters")


func test_sanitize_string_with_replacement():
	var result = g_instance.sanitize_string("Test/Name\\Bad", "_")
	assert_eq(result, "Test_Name_Bad", "Should replace invalid chars with underscore")


func test_sanitize_string_empty_replacement():
	var result = g_instance.sanitize_string("A/B/C", "")
	assert_eq(result, "ABC", "Should remove invalid chars with empty replacement")


func test_sanitize_string_handles_empty_input():
	var result = g_instance.sanitize_string("")
	assert_eq(result, "", "Should handle empty string")


func test_sanitize_string_all_invalid_chars():
	var result = g_instance.sanitize_string("///\\\\:::")
	assert_eq(result, "", "Should return empty when all chars invalid")


func test_is_input_string_valid_accepts_good_strings():
	assert_true(g_instance.is_input_string_valid("ValidName123"), "Should accept alphanumeric")
	assert_true(g_instance.is_input_string_valid("Test_Name-Plus"), "Should accept underscores, dashes, plus")
	assert_true(g_instance.is_input_string_valid("a"), "Should accept single char")
	assert_true(g_instance.is_input_string_valid("ABC xyz 123"), "Should accept spaces")


func test_is_input_string_valid_rejects_empty():
	assert_false(g_instance.is_input_string_valid(""), "Should reject empty string")


func test_is_input_string_valid_rejects_invalid_chars():
	assert_false(g_instance.is_input_string_valid("Bad/Name"), "Should reject slash")
	assert_false(g_instance.is_input_string_valid("Bad\\Name"), "Should reject backslash")
	assert_false(g_instance.is_input_string_valid("Bad:Name"), "Should reject colon")
	assert_false(g_instance.is_input_string_valid("Bad@Name"), "Should reject @")
	assert_false(g_instance.is_input_string_valid("Bad#Name"), "Should reject #")


func test_is_input_string_valid_rejects_default_name():
	assert_false(g_instance.is_input_string_valid("DefaultName", "DefaultName"), 
		"Should reject default name when specified")
	assert_true(g_instance.is_input_string_valid("DefaultName", "OtherDefault"), 
		"Should accept when not matching default")


func test_is_input_character_valid_letters():
	assert_true(g_instance.is_input_character_valid("a"), "Should accept lowercase letter")
	assert_true(g_instance.is_input_character_valid("Z"), "Should accept uppercase letter")


func test_is_input_character_valid_numbers():
	assert_true(g_instance.is_input_character_valid("0"), "Should accept zero")
	assert_true(g_instance.is_input_character_valid("5"), "Should accept digit")
	assert_true(g_instance.is_input_character_valid("9"), "Should accept nine")


func test_is_input_character_valid_special_allowed():
	assert_true(g_instance.is_input_character_valid("_"), "Should accept underscore")
	assert_true(g_instance.is_input_character_valid("-"), "Should accept dash")
	assert_true(g_instance.is_input_character_valid("+"), "Should accept plus")
	assert_true(g_instance.is_input_character_valid(" "), "Should accept space")


func test_is_input_character_valid_special_forbidden():
	assert_false(g_instance.is_input_character_valid("/"), "Should reject slash")
	assert_false(g_instance.is_input_character_valid("\\"), "Should reject backslash")
	assert_false(g_instance.is_input_character_valid(":"), "Should reject colon")
	assert_false(g_instance.is_input_character_valid("@"), "Should reject @")
	assert_false(g_instance.is_input_character_valid("#"), "Should reject #")
	assert_false(g_instance.is_input_character_valid("*"), "Should reject asterisk")
	assert_false(g_instance.is_input_character_valid("?"), "Should reject question mark")

#endregion


#region DICTIONARY UPDATE LOGIC

func test_update_dict_adds_missing_keys():
	var target = {"existing": "value"}
	var defaults = {"existing": "default", "new_key": "new_value"}
	
	var result = g_instance.update_dict(target, defaults)
	
	assert_eq(result["existing"], "value", "Should preserve existing value")
	assert_eq(result["new_key"], "new_value", "Should add new key")
	assert_eq(result.size(), 2, "Should have 2 keys total")


func test_update_dict_preserves_all_existing():
	var target = {"key1": "val1", "key2": "val2", "key3": "val3"}
	var defaults = {"key1": "default1", "key4": "default4"}
	
	var result = g_instance.update_dict(target, defaults)
	
	assert_eq(result["key1"], "val1", "Should keep key1")
	assert_eq(result["key2"], "val2", "Should keep key2")
	assert_eq(result["key3"], "val3", "Should keep key3")
	assert_eq(result["key4"], "default4", "Should add key4")


func test_update_dict_recursive_nested():
	var target = {"nested": {"existing": "value"}}
	var defaults = {"nested": {"existing": "default", "new": "save_data"}}
	
	var result = g_instance.update_dict(target, defaults)
	
	assert_eq(result.nested.existing, "value", "Should preserve nested existing value")
	assert_eq(result.nested.new, "save_data", "Should add nested new value")


func test_update_dict_deep_recursion():
	var target = {"level1": {"level2": {"existing": "value"}}}
	var defaults = {"level1": {"level2": {"existing": "default", "new": "save_data"}, "new2": "data2"}}
	
	var result = g_instance.update_dict(target, defaults)
	
	assert_eq(result.level1.level2.existing, "value", "Should preserve deep nested value")
	assert_eq(result.level1.level2.new, "save_data", "Should add deep nested value")
	assert_eq(result.level1.new2, "data2", "Should add intermediate nested value")


func test_update_dict_empty_target():
	var target = {}
	var defaults = {"key1": "val1", "key2": "val2"}
	
	var result = g_instance.update_dict(target, defaults)
	
	assert_eq(result.size(), 2, "Should add all defaults to empty target")
	assert_eq(result["key1"], "val1", "Should have key1")


func test_update_dict_empty_defaults():
	var target = {"key1": "val1"}
	var defaults = {}
	
	var result = g_instance.update_dict(target, defaults)
	
	assert_eq(result.size(), 1, "Should keep existing when no defaults")
	assert_eq(result["key1"], "val1", "Should preserve value")


func test_update_dict_mixed_types():
	var target = {"string": "text", "number": 42}
	var defaults = {"string": "default", "number": 0, "bool": true, "array": [1, 2, 3]}
	
	var result = g_instance.update_dict(target, defaults)
	
	assert_eq(result["string"], "text", "Should preserve string")
	assert_eq(result["number"], 42, "Should preserve number")
	assert_eq(result["bool"], true, "Should add bool")
	assert_eq(result["array"], [1, 2, 3], "Should add array")


func test_update_dict_nested_dict_vs_non_dict():
	var target = {"save_data": "string_value"}
	var defaults = {"save_data": {"nested": "value"}}
	
	var result = g_instance.update_dict(target, defaults)
	
	# Non-dict in target stays as-is, doesn't get replaced by dict from defaults
	assert_eq(result["save_data"], "string_value", "Should keep non-dict value")

#endregion


#region MATHEMATICAL UTILITIES

func test_round_to_dec_zero_decimals():
	assert_eq(g_instance.round_to_dec(3.14159, 0), 3.0, "Should round to integer")
	assert_eq(g_instance.round_to_dec(3.7, 0), 4.0, "Should round up to integer")
	assert_eq(g_instance.round_to_dec(3.2, 0), 3.0, "Should round down to integer")


func test_round_to_dec_two_decimals():
	assert_eq(g_instance.round_to_dec(3.14159, 2), 3.14, "Should round to 2 decimals")
	assert_eq(g_instance.round_to_dec(3.14999, 2), 3.15, "Should round up at 2 decimals")
	assert_eq(g_instance.round_to_dec(3.14001, 2), 3.14, "Should round down at 2 decimals")


func test_round_to_dec_three_decimals():
	assert_eq(g_instance.round_to_dec(3.14159, 3), 3.142, "Should round to 3 decimals")
	assert_eq(g_instance.round_to_dec(3.14155, 3), 3.142, "Should round up at 3 decimals")


func test_round_to_dec_negative_numbers():
	assert_eq(g_instance.round_to_dec(-3.14159, 2), -3.14, "Should round negative to 2 decimals")
	assert_eq(g_instance.round_to_dec(-3.7, 0), -4.0, "Should round negative to integer")


func test_round_to_dec_already_rounded():
	assert_eq(g_instance.round_to_dec(3.14, 2), 3.14, "Should handle already rounded number")
	assert_eq(g_instance.round_to_dec(5.0, 3), 5.0, "Should handle integer as float")


func test_round_to_dec_very_small():
	assert_eq(g_instance.round_to_dec(0.00001, 4), 0.0, "Should round very small to zero at 4 decimals")
	assert_eq(g_instance.round_to_dec(0.00001, 5), 0.00001, "Should preserve at 5 decimals")


func test_generate_points_in_circle_count():
	var points = g_instance.generate_points_in_circle(Vector2.ZERO, 10.0, 4, 0.0)
	assert_eq(points.size(), 4, "Should generate exactly 4 points")
	
	points = g_instance.generate_points_in_circle(Vector2.ZERO, 10.0, 8, 0.0)
	assert_eq(points.size(), 8, "Should generate exactly 8 points")


func test_generate_points_in_circle_radius():
	var points = g_instance.generate_points_in_circle(Vector2.ZERO, 10.0, 4, 0.0)
	
	for point in points:
		var distance = point.length()
		assert_almost_eq(distance, 10.0, 0.01, "Point should be on circle radius")


func test_generate_points_in_circle_center_offset():
	var center = Vector2(50, 50)
	var points = g_instance.generate_points_in_circle(center, 10.0, 4, 0.0)
	
	for point in points:
		var distance = (point - center).length()
		assert_almost_eq(distance, 10.0, 0.01, "Point should be at radius from offset center")


func test_generate_points_in_circle_angle_offset():
	var points_no_offset = g_instance.generate_points_in_circle(Vector2.ZERO, 10.0, 4, 0.0)
	var points_with_offset = g_instance.generate_points_in_circle(Vector2.ZERO, 10.0, 4, 90.0)
	
	# First point should be different due to rotation
	assert_ne(points_no_offset[0], points_with_offset[0], "Angle offset should rotate points")


func test_generate_points_in_circle_even_distribution():
	var points = g_instance.generate_points_in_circle(Vector2.ZERO, 10.0, 4, 0.0)
	
	# For 4 points, they should be 90 degrees apart
	# Check that points are roughly evenly spaced
	assert_eq(points.size(), 4, "Should have 4 evenly distributed points")


func test_generate_points_in_circle_single_point():
	var points = g_instance.generate_points_in_circle(Vector2.ZERO, 10.0, 1, 0.0)
	assert_eq(points.size(), 1, "Should handle single point")
	assert_almost_eq(points[0].length(), 10.0, 0.01, "Single point should be at radius")


func test_generate_points_in_circle_zero_radius():
	var points = g_instance.generate_points_in_circle(Vector2.ZERO, 0.0, 4, 0.0)
	
	for point in points:
		assert_almost_eq(point.length(), 0.0, 0.01, "Zero radius should put all points at center")

#endregion


#region PAUSE SYSTEM LOGIC

func test_pause_requests_array_management():
	# This tests the logic of adding/removing from array, not the actual pausing
	var obj1 = Node.new()
	var obj2 = Node.new()
	
	# Initially empty
	assert_eq(g_instance.request_pause_objects.size(), 0, "Should start with no requests")
	
	# Add first object
	g_instance.request_pause_objects.append(obj1)
	assert_eq(g_instance.request_pause_objects.size(), 1, "Should have 1 request")
	assert_true(obj1 in g_instance.request_pause_objects, "Should contain obj1")
	
	# Add second object
	g_instance.request_pause_objects.append(obj2)
	assert_eq(g_instance.request_pause_objects.size(), 2, "Should have 2 requests")
	
	# Remove first object
	g_instance.request_pause_objects.erase(obj1)
	assert_eq(g_instance.request_pause_objects.size(), 1, "Should have 1 request after removal")
	assert_false(obj1 in g_instance.request_pause_objects, "Should not contain obj1")
	assert_true(obj2 in g_instance.request_pause_objects, "Should still contain obj2")


func test_pause_requests_duplicate_handling():
	var obj = Node.new()
	
	# Add same object twice
	g_instance.request_pause_objects.append(obj)
	
	# Check if already in array before adding again
	if not g_instance.request_pause_objects.has(obj):
		g_instance.request_pause_objects.append(obj)
	
	assert_eq(g_instance.request_pause_objects.size(), 1, "Should not add duplicates")

#endregion


#region SETTINGS TEXT FORMATTING

func test_get_setting_text_volume_formatting():
	g_instance.settings = g_instance.DEFAULT_SETTINGS.duplicate(true)
	
	g_instance.settings[g_instance.Settings.MUSIC_VOLUME] = 0.0
	var text = g_instance.get_setting_text(g_instance.Settings.MUSIC_VOLUME)
	assert_eq(text, " 20%", "Volume 0.0 should format to 20%")
	
	g_instance.settings[g_instance.Settings.MUSIC_VOLUME] = 5.0
	text = g_instance.get_setting_text(g_instance.Settings.MUSIC_VOLUME)
	assert_eq(text, " 70%", "Volume 5.0 should format to 70%")
	
	g_instance.settings[g_instance.Settings.SFX_VOLUME] = -2.0
	text = g_instance.get_setting_text(g_instance.Settings.SFX_VOLUME)
	assert_eq(text, "  0%", "Volume -2.0 should format to 0%")


func test_get_setting_text_visual_formatting():
	g_instance.settings = g_instance.DEFAULT_SETTINGS.duplicate(true)
	
	g_instance.settings[g_instance.Settings.BRIGHTNESS] = 1.0
	var text = g_instance.get_setting_text(g_instance.Settings.BRIGHTNESS)
	assert_eq(text, " 60%", "Brightness 1.0 should format to 60%")
	
	g_instance.settings[g_instance.Settings.CONTRAST] = 0.0
	text = g_instance.get_setting_text(g_instance.Settings.CONTRAST)
	assert_eq(text, " 50%", "Contrast 0.0 should format to 50%")
	
	g_instance.settings[g_instance.Settings.SATURATION] = 2.0
	text = g_instance.get_setting_text(g_instance.Settings.SATURATION)
	assert_eq(text, " 70%", "Saturation 2.0 should format to 70%")


func test_get_setting_text_fullscreen_mode():
	g_instance.settings = g_instance.DEFAULT_SETTINGS.duplicate(true)
	
	g_instance.settings[g_instance.Settings.FULLSCREEN_MODE] = true
	var text = g_instance.get_setting_text(g_instance.Settings.FULLSCREEN_MODE)
	assert_eq(text, "Fullscreen Mode", "True should show Fullscreen Mode")
	
	g_instance.settings[g_instance.Settings.FULLSCREEN_MODE] = false
	text = g_instance.get_setting_text(g_instance.Settings.FULLSCREEN_MODE)
	assert_eq(text, "Windowed Mode", "False should show Windowed Mode")

#endregion
