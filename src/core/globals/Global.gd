@tool
extends Node

var build_profile : G.BuildProfile = G.BuildProfile.DEV

const DEFAULT_DATA : Dictionary = {
	"meta": {
		"version": "",
		"creation_date": "",
		"last_play_date": "",
		"time_since_start": 0.0,
		"time_played": 0.0,
		"save_date": 0.0,
		"event_log": [],
	},
	"world": {},
	"player": {
		"position": Vector2i(0, 0),
		"level": Vector2i(0, 0),
	}
}


func _ready() -> void:
	set_process(false)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	reset_variables()
	
	# Initialize game folders (saves, settings, etc.)
	init_folders()
	
	# Load pre-existing settings file, and apply settings
	load_settings()
	
	# Load custom player bindings if there are any in settings file
	I.load_bindings()
	
	#If settings are loaded, apply them
	apply_settings()
	
	data = DEFAULT_DATA.duplicate(true)
	
	# Process should only start when data has been initialized, so that data.meta exists.
	set_process(true)


func _process(delta: float) -> void:
	data.meta.time_since_start += delta
	if not get_tree().paused:
		data.meta.time_played += delta


func reset_variables() -> void:
	pass


#region CORE SCENES SYSTEM : main menu, loading game core scenes
## Emmited to request a game restart
@warning_ignore("unused_signal")
signal request_game_restart

## Emmited to request a scene change
@warning_ignore("unused_signal")
signal request_core_scene(requested_core_scene : CoreScene)

## Emmited when Core Scene changed and is loaded
@warning_ignore("unused_signal")
signal new_core_scene_loaded(new_core_scene : CoreScene)

## The core game scenes
enum CoreScene {
	INTRO_CREDITS, ## Loading scene scene (between Core Scenes)
	EXPO_INTRO_VIDEO, ## Loading scene scene (between Core Scenes)
	
	LOADING, ## Loading scene scene (between Core Scenes)
	MAIN_MENU, ## Main menu scene (start of the game)
	GAME, ## Game scene (gameplay scene)
	
	CUSTOM_CORE_SCENE_1,
	CUSTOM_CORE_SCENE_2,
	CUSTOM_CORE_SCENE_3,
}

## Path the Core Scenes
var CoreScenePath : Dictionary = {
	G.CoreScene.INTRO_CREDITS : "",
	G.CoreScene.EXPO_INTRO_VIDEO : "",
	
	G.CoreScene.LOADING : "uid://5do4yrji1jit",
	G.CoreScene.MAIN_MENU : "uid://b25u4t1skkerr",
	G.CoreScene.GAME : "",
	
	G.CoreScene.CUSTOM_CORE_SCENE_1 : "",
	G.CoreScene.CUSTOM_CORE_SCENE_2 : "",
	G.CoreScene.CUSTOM_CORE_SCENE_3 : "",
}

## Current Core Scene
var core_scene : CoreScene
#endregion


#region BUILD PROFILE SYSTEM : what is the project state
enum BuildProfile {
	DEV,
	RELEASE,
	EXPO,
}

## Quickly test if game is run for dev or debugging
func is_debug() -> bool:
	return build_profile == BuildProfile.DEV

## Quickly test if game is run for an expo event
func is_expo() -> bool:
	return build_profile == BuildProfile.EXPO
#endregion


#region PAUSE SYSTEM : pause requests
## Emmited when pause state changes
signal pause_state_changed(is_game_paused)

## All objects requesting pause
var request_pause_objects : Array = []


func declare_pause() -> void:
	var declaring_pause : bool = request_pause_objects.size() > 0
	if declaring_pause != get_tree().paused:
		get_tree().paused = declaring_pause
		pause_state_changed.emit(declaring_pause)


## Adds/Removes an object requesting pause, and setting pause accordingly
func request_pause(object : Object = null, requests_pause : bool = true) -> void:
	if is_instance_valid(object):
		if requests_pause and not request_pause_objects.has(object):
			request_pause_objects.append(object)
		elif not requests_pause and request_pause_objects.has(object):
			request_pause_objects.erase(object)
	declare_pause()


## Resets game pause (clear all pause requests and reset pause)
func reset_pause_state() -> void:
	request_pause_objects.clear()
	declare_pause()
#endregion


#region LOCALIZATION SYSTEM : locales, texts
# Using translated text : tr("STRING_NAME")

## Emmited when game locale has been changed
signal locale_changed

## The game currently used locale
var current_locale : String = get_OS_default_locale()

## Sets game locale (langage setting)
func set_locale(request_locale : String) -> void:
	if request_locale in get_available_locales():
		if request_locale == current_locale:
			print("locale is already " + request_locale)
		else:
			current_locale = request_locale
			TranslationServer.set_locale(request_locale)
			locale_changed.emit()
			print("locale set to " + request_locale)
	else:
		current_locale = TranslationServer.get_locale()
		printerr("requested locale named " + request_locale + " not supported. Available locales: " + str(get_available_locales()))


## Get the locale used on the machine
func get_OS_default_locale() -> String:
	return OS.get_locale_language()


# List all available locales in the game
func get_available_locales() -> PackedStringArray:
	return TranslationServer.get_loaded_locales()
#endregion


#region SETTINGS SYSTEM : what is the project state
## To change project defaults, edit res://config/default_settings.tres in the inspector.

var settings : GameSettings = GameSettings.new()

signal setting_adjusted(setting : String, value : Variant)

## Signals to tell the WorldEnvironment node to set itself
signal adjust_brightness(intensity : float)
signal adjust_contrast(intensity : float)
signal adjust_saturation(intensity : float)

const AUDIO_BUSES : Dictionary = {
	"music_volume"   : "music",
	"sfx_volume"     : "sfx",
	"ui_volume"      : "ui",
	"ambient_volume" : "ambient",
}

func apply_settings(settings_to_apply : GameSettings = settings) -> void:
	for property in settings_to_apply.get_property_list():
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		
		if property.name == "input_bindings":
			continue	# handled separately by InputService
		
		adjust_setting(property.name, settings_to_apply.get(property.name))


func adjust_setting(setting : String, value : Variant) -> void:
	match setting:
		"music_volume", "sfx_volume", "ui_volume", "ambient_volume":
			if value is float or value is int:
				var new_audio_volume : float = value
				
				AudioServer.set_bus_volume_db(
					AudioServer.get_bus_index(AUDIO_BUSES[setting]),
					new_audio_volume
				)
				
				save_setting_value(setting, new_audio_volume)
		
		"brightness", "contrast", "saturation":
			if value is float or value is int:
				var intensity : float = clampf(value, 0., 2.)
				if setting == "brightness":
					adjust_brightness.emit(intensity)
				elif setting == "contrast":
					adjust_contrast.emit(intensity)
				elif setting == "saturation":
					adjust_saturation.emit(intensity)
				
				save_setting_value(setting, intensity)
		
		"fullscreen":
			if value is bool:
				var is_fullscreen_mode : bool = value
				if is_fullscreen_mode:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
				else:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				
				save_setting_value(setting, is_fullscreen_mode)


func save_setting_value(setting : String, value : Variant) -> void:
	if settings.get(setting) != value:
		settings.set(setting, value)
		setting_adjusted.emit(setting, value)
	
	# don't save settings if in expo mode, because we don't need to save settings between games
	if not is_expo():
		save_settings()


func get_setting_text(setting : String) -> String:
	var value : Variant = settings.get(setting)
	if value == null:
		push_warning("G.get_setting_text : unknown property '%s'" % setting)
		return ""
	
	match setting:
		"music_volume", "sfx_volume", "ui_volume", "ambient_volume":
			return "%3d" % int(value * 10 + 20) + "%"
		
		"brightness", "contrast", "saturation":
			return "%3d" % int(value * 10 + 50) + "%"
		
		"fullscreen":
			return "Fullscreen" if value else "Windowed"
		
		"input_bindings":
			push_warning("No Text can be rendered for this setting.")
	
	return ""
#endregion


#region BASIC METHODS : geometry, calculus, colors, etc.
## Returns digit decimals of num as an int
func round_to_dec(num: float, digit : int) -> float:
	return round(num * pow(10.0, digit)) / pow(10.0, digit)


## Generate a list of points in a circle, positioned at center, with points_nbr points and offseted in angle by starting_angle (deg, not rad)
func generate_points_in_circle(center : Vector2 = Vector2.ZERO, rayon : float = 10., points_nbr : int = 8, starting_angle : float = 0.) -> PackedVector2Array:
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
func sanitize_string(string_to_sanitize : String, replacement : String = "") -> String:
	var sanitized_string : String = ""
	
	for character in string_to_sanitize:
		if is_input_character_valid(character):
			sanitized_string += character
		elif replacement != "":
			sanitized_string += replacement
	
	return sanitized_string


## Test if a player text input is valid
func is_input_string_valid(string_to_test : String, default_string : String = "") -> bool:
	var is_default_name : bool = string_to_test == default_string and not default_string == ""
	var is_empty_name : bool = string_to_test == ""
	
	var has_forbidden_characters : bool = false
	for character : String in string_to_test:
		if not character in AUTHORIZED_CHARACTERS:
			has_forbidden_characters = true
			break

	return not (is_default_name or is_empty_name or has_forbidden_characters)


## Test if a character is valid
func is_input_character_valid(character : String) -> bool:
	return character in AUTHORIZED_CHARACTERS
#endregion


#region SAVE SYSTEM : data, saves, settings save, loading, listing files
signal data_is_ready

const ENCRYPT_KEY : String = "&Fr4GMt8T!0n.5%eR52:r&/iPJKl3s?,nnr"
const FILES_EXTENSION : String = ".data"
const BIN_DIR : String = "user://bin/"
const SAVE_DIR : String = "user://saves/"
var ARCHIVE_SAVE_DIR : String = "user://archive/"
const SETTINGS_PATH : String = BIN_DIR + "game_settings" + FILES_EXTENSION
const DEFAULT_SAVE_TEXTURE : Texture2D = preload("res://icon.svg")
const SCREENSHOT_SIZE : Vector2i = Vector2i(80, 40)
const TEMP_FILE_SUFFIX : String = ".tmp"

# Cannot be a cosnt since its needs parse time to initialize
var SCREENSHOT_DIR : String = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)

enum FileMode { ENCRYPTED, PLAIN }

var is_data_ready : bool = false
var data : Dictionary = {}


func init_folders(additional_folders : PackedStringArray = []) -> void:
	SCREENSHOT_DIR = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES) + "/" + sanitize_string(ProjectSettings.get_setting("application/config/name")) + "/"
	
	var directories_init : Array = [SAVE_DIR, BIN_DIR, SCREENSHOT_DIR, ARCHIVE_SAVE_DIR]
	directories_init.append_array(additional_folders)
	
	for dir_path in directories_init:
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_dir_recursive_absolute(dir_path)


## Log an event to the event log (avoids duplicates)
func log_event(event_data : Variant) -> void:
	if data.is_empty() or not data.has("meta"):
		push_warning("Cannot log event - data not initialized")
		return
	
	if event_data not in data.meta.event_log:
		data.meta.event_log.append(event_data)


## Load settings from file or create defaults. Returns true if settings existed, false if created new.
func load_settings() -> bool:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return false
	
	var loaded : Array = _read_file(SETTINGS_PATH, FileMode.PLAIN)
	if not loaded.is_empty() and loaded[0] is GameSettings:
		settings = loaded[0]
		return true
	
	return false


## Save current settings to file
func save_settings() -> void:
	_write_file(SETTINGS_PATH, [settings], FileMode.PLAIN)


## Create a new save file with given world name. Returns full file path, or empty string on failure.
## If a save with the same name exists, auto-increments with a number suffix.
func create_save_file(save_name : String) -> String:
	is_data_ready = false
	
	data = DEFAULT_DATA.duplicate(true)
	
	var now : String = Time.get_datetime_string_from_system()
	data.meta.version = ProjectSettings.get_setting("application/config/version")
	data.meta.save_date = Time.get_unix_time_from_system()
	data.meta.creation_date = now
	data.meta.last_play_date = now
	
	# Find unique filename if collision occurs
	var safe_name : String = sanitize_string(save_name)
	var file_name : String = safe_name + FILES_EXTENSION
	var file_path : String = SAVE_DIR + file_name
	var counter : int = 1
	
	while FileAccess.file_exists(file_path):
		push_warning("Save file already exists, auto-incrementing: " + file_path)
		file_name = safe_name + "_" + str(counter) + FILES_EXTENSION
		file_path = SAVE_DIR + file_name
		counter += 1
	
	if not _write_file(file_path, [data, DEFAULT_SAVE_TEXTURE], FileMode.ENCRYPTED):
		push_error("Failed to create save file")
		return ""
	
	is_data_ready = true
	data_is_ready.emit()
	
	return file_path


## Save current game data with screenshot (async - must await)
## Uses temporary file for transaction safety to prevent corruption on crash.
## Returns true on success, false on failure.
func save_data(file_path : String) -> bool:
	data.meta.version = ProjectSettings.get_setting("application/config/version")
	data.meta.last_play_date = Time.get_datetime_string_from_system()
	
	var save_img : Image = await _capture_screenshot()
	
	# Write to temporary file first to prevent corruption if crash occurs during save
	var temp_path : String = file_path + TEMP_FILE_SUFFIX
	if not _write_file(temp_path, [data, save_img], FileMode.ENCRYPTED):
		push_error("Failed to write temp save file")
		delete_file(temp_path)  # Clean up failed temp file
		return false
	
	# Atomic rename - if this succeeds, save is complete. If it fails, original file remains intact.
	var error : Error = DirAccess.rename_absolute(temp_path, file_path)
	if error != OK:
		push_error("Failed to finalize save file: " + str(error))
		delete_file(temp_path)  # Clean up temp file on rename failure
		return false
	
	return true


## Load data from a save file, optionally without setting it as current
func load_data(file_path : String, set_as_current : bool = true) -> Array:
	var file_data : Array = _read_file(file_path, FileMode.ENCRYPTED)
	
	if file_data.is_empty():
		#push_error("Failed to load save file: " + file_path)
		var fallback := [DEFAULT_DATA.duplicate(true), DEFAULT_SAVE_TEXTURE]
		if set_as_current:
			data = fallback[0]
			is_data_ready = true
			data_is_ready.emit()
		return fallback
	
	if file_data.size() < 2:
		file_data.append(DEFAULT_SAVE_TEXTURE)
	
	file_data[0] = update_dict(file_data[0], DEFAULT_DATA)
	
	if set_as_current:
		data = file_data[0]
		is_data_ready = true
		data_is_ready.emit()
	
	return file_data


## List all save files in the save directory (returns full paths)
func list_save_files() -> Array:
	var files : Array = []
	var dir : DirAccess = DirAccess.open(SAVE_DIR)
	
	if not dir:
		push_error("Failed to access save directory")
		return []
	
	for file_name in dir.get_files():
		if file_name.ends_with(FILES_EXTENSION):
			files.append(SAVE_DIR + file_name)
	
	return files



## Move all save files to archive directory. Returns number of files successfully moved.
func move_files_to_archive() -> int:
	init_folders([ARCHIVE_SAVE_DIR])
	
	var moved_count : int = 0
	
	for file_path in list_save_files():
		var file_name : String = file_path.get_file()
		var destination : String = ARCHIVE_SAVE_DIR + file_name
		
		var copy_error : Error = DirAccess.copy_absolute(file_path, destination)
		if copy_error != OK:
			push_error("Failed to copy file to archive: " + file_path)
			continue
		
		var remove_error : Error = DirAccess.remove_absolute(file_path)
		if remove_error != OK:
			push_error("Failed to remove original file: " + file_path)
			continue
		
		moved_count += 1
		await get_tree().process_frame
	
	return moved_count


## Delete a file at the given path. Returns true on success.
func delete_file(file_path : String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_warning("Attempted to delete non-existent file: " + file_path)
		return false
	
	var error : Error = DirAccess.remove_absolute(file_path)
	if error != OK:
		push_error("Failed to delete file: " + file_path + " (Error: " + str(error) + ")")
		return false
	
	return true


## Update dictionary with missing keys from default (recursive, preserves existing values)
func update_dict(target : Dictionary, defaults : Dictionary) -> Dictionary:
	for key in defaults:
		if key not in target:
			target[key] = defaults[key].duplicate(true) if defaults[key] is Dictionary else defaults[key]
		elif target[key] is Dictionary and defaults[key] is Dictionary:
			update_dict(target[key], defaults[key])
	return target


## Read a file and return its contents as an array
func _read_file(file_path : String, mode : FileMode = FileMode.ENCRYPTED) -> Array:
	var file : FileAccess
	
	if mode == FileMode.ENCRYPTED:
		file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.READ, ENCRYPT_KEY)
	else:
		file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		#push_error("Failed to read file: " + file_path)
		return []
	
	var contents : Array = []
	while file.get_position() < file.get_length():
		contents.append(file.get_var(true))
	
	return contents


## Write data to a file. Returns true on success.
func _write_file(file_path : String, data_array : Array, mode : FileMode = FileMode.ENCRYPTED) -> bool:
	var file : FileAccess
	
	if mode == FileMode.ENCRYPTED:
		file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.WRITE, ENCRYPT_KEY)
	else:
		file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		push_error("Failed to write file: " + file_path)
		return false
	
	for element in data_array:
		file.store_var(element, true)
	
	return true


## Capture a screenshot and resize it for save files
func _capture_screenshot() -> Image:
	await get_tree().process_frame
	var img : Image = get_viewport().get_texture().get_image()
	img.resize(SCREENSHOT_SIZE.x, SCREENSHOT_SIZE.y, Image.INTERPOLATE_NEAREST)
	return img
#endregion
