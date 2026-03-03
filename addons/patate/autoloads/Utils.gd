class_name Utils
extends Node


## Returns true is int is even (multiple of 2)
static func is_even(x: int):
	return x % 2 == 0


## Returns true is int is odd (not a multiple of 2)
static func is_odd(x: int):
	return x % 2 != 0


## Returns digit decimals of num as an int
static func round_to_dec(num: float, digit : int) -> float:
	return round(num * pow(10.0, digit)) / pow(10.0, digit)


## Generate a list of points in a circle, positioned at center, with points_nbr points and offseted in angle by starting_angle (deg, not rad)
static func generate_points_in_circle(center : Vector2 = Vector2.ZERO, rayon : float = 10., points_nbr : int = 8, starting_angle : float = 0.) -> PackedVector2Array:
	var points_list : PackedVector2Array = []
	
	for i in range(points_nbr):
		var new_point : Vector2
		
		var rnd_angle : float = deg_to_rad(i * 360. / points_nbr + starting_angle)
		new_point = Vector2(
			cos(rnd_angle),
			sin(rnd_angle),
		) * rayon
	
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
