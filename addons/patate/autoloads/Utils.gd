class_name Utils
extends Node


## Returns true is int is even (multiple of 2)
static func is_even(x: int) -> bool:
	return x % 2 == 0


## Returns true is int is odd (not a multiple of 2)
static func is_odd(x: int) -> bool:
	return x % 2 != 0


## Returns digit decimals of num as an int
static func round_to_dec(num: float, digit : int) -> float:
	return round(num * pow(10.0, digit)) / pow(10.0, digit)


## Generate a list of points in a circle, positioned at center, with points_nbr points and offseted in angle by starting_angle (deg, not rad)
static func generate_points_in_circle(center : Vector2 = Vector2.ZERO, radius : float = 10., points_nbr : int = 8, starting_angle : float = 0.) -> PackedVector2Array:
	var points_list : PackedVector2Array = []
	
	for i in range(points_nbr):
		var new_point : Vector2
		
		var rnd_angle : float = deg_to_rad(i * 360. / points_nbr + starting_angle)
		new_point = Vector2(
			cos(rnd_angle),
			sin(rnd_angle),
		) * radius
	
		points_list.append(new_point + center)
	
	return points_list


const AUTHORIZED_CHARACTERS : String = "abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+- "
## Sanitize a string by replacing invalid filename characters with underscores
## Can be used for filenames, save names, or any string that needs filesystem safety
static func sanitize_string(string_to_sanitize : String, replacement : String = "") -> String:
	var sanitized_string : String = ""
	
	for character in string_to_sanitize:
		if is_input_character_valid(character):
			sanitized_string += character
		elif replacement != "":
			sanitized_string += replacement
	
	return sanitized_string


## Test if a player text input is valid
static func is_input_string_valid(string_to_test : String, default_string : String = "") -> bool:
	var is_default_name : bool = string_to_test == default_string and not default_string == ""
	var is_empty_name : bool = string_to_test == ""
	
	var has_forbidden_characters : bool = false
	for character : String in string_to_test:
		if not character in AUTHORIZED_CHARACTERS:
			has_forbidden_characters = true
			break

	return not (is_default_name or is_empty_name or has_forbidden_characters)


## Test if a character is valid
static func is_input_character_valid(character : String) -> bool:
	return character in AUTHORIZED_CHARACTERS


static func get_hint_range_info(resource: Variant, property_name: String) -> Dictionary:
	var hint_range_info: Dictionary = {}
	
	for property in resource.get_property_list():
		if property.name == property_name:
			if property.hint == PROPERTY_HINT_RANGE:
				var parts = property.hint_string.split(",")
				var min_value = float(parts[0]) if parts.size() > 0 else 0.
				var max_value = float(parts[1]) if parts.size() > 1 else 1.0
				var step = float(parts[2]) if parts.size() > 2 else 1.0
				
				# Initialize the Slider parameters
				hint_range_info.min_value = min_value
				hint_range_info.max_value = max_value
				hint_range_info.step = step
				hint_range_info.tick_count = (max_value - min_value) / step + 1
	
	return hint_range_info

## Returns a human-readable duration string (days/hours/minutes).
## Seconds are intentionally omitted.
static func seconds_to_duration(seconds: float) -> String:
	var total := int(seconds)
	var d := total / 86400
	var h := (total % 86400) / 3600
	var m := (total % 3600) / 60
	
	var parts: Array[String] = []
	if d > 0: parts.append("%dd" % d)
	if h > 0: parts.append("%dh" % h)
	if m > 0: parts.append("%dm" % m)
	
	return " ".join(parts) if parts.size() > 0 else "0m"


static func seconds_to_hours(seconds: float) -> String:
	return "%.1f h" % (seconds / 3600.0)


enum TimeFormat {
	FULL_DATE,
	FILE_NAME_COMPATIBLE,
}
static func format_datetime(datetime_str: String, time_format: TimeFormat = TimeFormat.FULL_DATE) -> String:
	var dt := Time.get_datetime_dict_from_datetime_string(datetime_str, false)
	match time_format:
		TimeFormat.FULL_DATE:
			return "%02d.%02d.%d - %02d:%02d:%02d" % [dt.day, dt.month, dt.year, dt.hour, dt.minute, dt.second]
		
		TimeFormat.FILE_NAME_COMPATIBLE:
			return "%02d-%02d-%d_%02dh%02dm%02ds" % [dt.day, dt.month, dt.year, dt.hour, dt.minute, dt.second]
	
	return ""
