extends Node

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
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	
	# Initialize game folders (saves, settings, etc.)
	init_folders()
	
	# Load pre-existing settings file, and apply settings
	load_settings()
	
	#If settings are loaded, apply them
	apply_settings()


#region CORE SCENES SYSTEM : main menu, loading game core scenes
## Emmited to request a scene change
@warning_ignore("unused_signal")
signal request_core_scene(requested_core_scene : CoreScenes)

## Emmited when Core Scene changed and is loaded
@warning_ignore("unused_signal")
signal new_core_scene_loaded(new_core_scene : CoreScenes)

## The core game scenes
enum CoreScenes {
	LOADING, ## Loading scene scene (between Core Scenes)
	MAIN_MENU, ## Main menu scene (start of the game)
	GAME, ## Game scene (gameplay scene)
	
	CUSTOM_CORE_SCENE_1,
	CUSTOM_CORE_SCENE_2,
	CUSTOM_CORE_SCENE_3,
}

## Path the Core Scenes
var CoreScenesPaths : Dictionary = {
	G.CoreScenes.LOADING : "uid://5do4yrji1jit",
	G.CoreScenes.MAIN_MENU : "uid://b25u4t1skkerr",
	G.CoreScenes.GAME : "",
	
	G.CoreScenes.CUSTOM_CORE_SCENE_1 : "",
	G.CoreScenes.CUSTOM_CORE_SCENE_2 : "",
	G.CoreScenes.CUSTOM_CORE_SCENE_3 : "",
}

## Current Core Scene
var core_scene : CoreScenes
#endregion


#region BUILD PROFILE SYSTEM : what is the project state
enum BuildProfiles {
	DEV,
	RELEASE,
	EXPO,
}
var build_profile : BuildProfiles = BuildProfiles.DEV
#endregion


#region PAUSE SYSTEM : pause requests
## Emmited when pause state changes
signal pause_state_changed(is_game_paused)

## All objects requesting pause
var request_pause_objects : Array = []


func declare_pause() -> void:
	var declaring_pause : bool = request_pause_objects.size() > 0
	if declaring_pause != get_tree().paused:
		get_tree().paused = request_pause_objects.size() > 0
		pause_state_changed.emit(declaring_pause)
	print(get_tree().paused)


## Adds/Removes an object requesting pause, and setting pause accordingly
func request_pause(object : Object = null, requests_pause : bool = true) -> void:
	if not object == null:
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

enum Settings {
	MUSIC_VOLUME,
	SFX_VOLUME,
	UI_VOLUME,
	AMBIENT_VOLUME,
	
	BRIGHTNESS,
	CONTRAST,
	SATURATION,
	
	FULLSCREEN_MODE,
}

const DEFAULT_SETTINGS : Dictionary = {
	Settings.MUSIC_VOLUME: 0,
	Settings.SFX_VOLUME: 0,
	Settings.UI_VOLUME: 0,
	Settings.AMBIENT_VOLUME: 0,
	
	Settings.BRIGHTNESS: 1.,
	Settings.CONTRAST: 1.,
	Settings.SATURATION: 1.,
	
	Settings.FULLSCREEN_MODE:false,
}

signal setting_adjusted(setting : Settings, value : Variant)

## Signal to tell the WorldEnvironment node what brightness to set
signal adjust_brightness(intensity : float)

## Signal to tell the WorldEnvironment node what contrast to set
signal adjust_contrast(intensity : float)

## Signal to tell the WorldEnvironment node what saturation to set
signal adjust_saturation(intensity : float)


func apply_settings() -> void:
	if settings.is_empty():
		push_warning("No Settings file loaded")
		return
	
	for setting in settings.keys():
		adjust_setting(setting, settings[setting])


func adjust_setting(setting : Settings, value : Variant) -> void:
	match setting:
		Settings.MUSIC_VOLUME, Settings.SFX_VOLUME, Settings.UI_VOLUME, Settings.AMBIENT_VOLUME:
			if value is float or value is int:
				var new_audio_volume : float = value
				var audio_buses_names : Dictionary = {
					Settings.MUSIC_VOLUME: "music",
					Settings.SFX_VOLUME: "sfx",
					Settings.UI_VOLUME: "ui",
					Settings.AMBIENT_VOLUME: "ambient",
				}
				AudioServer.set_bus_volume_db(AudioServer.get_bus_index(audio_buses_names[setting]), new_audio_volume)
				
				save_setting_value(setting, new_audio_volume)
		
		Settings.BRIGHTNESS, Settings.CONTRAST, Settings.SATURATION:
			if value is float or value is int:
				var intensity : float = clampf(value, 0., 2.)
				if setting == Settings.BRIGHTNESS:
					adjust_brightness.emit(intensity)
				elif setting == Settings.CONTRAST:
					adjust_contrast.emit(intensity)
				elif setting == Settings.SATURATION:
					adjust_saturation.emit(intensity)
				
				save_setting_value(setting, intensity)
		
		Settings.FULLSCREEN_MODE:
			if value is bool:
				var is_fullscreen_mode : bool = value
				if is_fullscreen_mode:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
				else:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				
				save_setting_value(setting, is_fullscreen_mode)


func save_setting_value(setting : Settings, value : Variant) -> void:
	if not settings[setting] == value:
		settings[setting] = value
		setting_adjusted.emit(setting, value)
		save_settings()


func get_setting_text(setting : Settings) -> String:
	match setting:
		Settings.MUSIC_VOLUME, Settings.SFX_VOLUME, Settings.UI_VOLUME, Settings.AMBIENT_VOLUME:
			return "%3d" % int(settings[setting] * 10 + 20) + "%"
		
		Settings.BRIGHTNESS, Settings.CONTRAST, Settings.SATURATION:
			return "%3d" % int(settings[setting] * 10 + 50) + "%"
		
		Settings.FULLSCREEN_MODE:
			return "Fullscreen Mode" if settings[setting] else "Windowed Mode"
	
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
	print(sanitized_string)
	return sanitized_string


## Test if a player text input is valid
func is_input_string_valid(string_to_test : String, default_string : String = "") -> bool:
	var is_default_name : bool = string_to_test == default_string and not default_string == ""
	var is_empty_name : bool = string_to_test == ""
	
	var has_forbidden_characters : bool = false
	for character : String in string_to_test:
		if not character in AUTHORIZED_CHARACTERS:
			has_forbidden_characters = true

	return not (is_default_name or is_empty_name or has_forbidden_characters)


## Test if a player text input is valid
func is_input_character_valid(character : String) -> bool:
	return character in AUTHORIZED_CHARACTERS
#endregion


#region SAVE SYSTEM : data, saves, settings save, loading, listing files
signal data_is_ready

const ENCRYPT_KEY : String = "&Fr4GMt8T!0n.5%eR52:r&/iPJKl3s?,nnr"
const FILES_EXTENSION : String = ".data"
var BIN_DIR : String = "user://bin/"
var SAVE_DIR : String = "user://saves/"
var ARCHIVE_SAVE_DIR : String = "user://archive_saves/"
var SETTINGS_PATH : String = BIN_DIR + "game_settings" + FILES_EXTENSION
const DEFAULT_SAVE_TEXTURE : Texture2D = preload("res://icon.svg")
const SCREENSHOT_SIZE : Vector2i = Vector2i(80, 40)
const TEMP_FILE_SUFFIX : String = ".tmp"

var SCREENSHOT_DIR : String = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES) + "/Mosaic/"

enum FileMode { ENCRYPTED, PLAIN }

var is_data_ready : bool = false
var data : Dictionary = {}
var settings : Dictionary = {}


func init_folders() -> void:
	for dir_path in [SAVE_DIR, BIN_DIR, SCREENSHOT_DIR, ARCHIVE_SAVE_DIR]:
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
	var existed : bool = FileAccess.file_exists(SETTINGS_PATH)
	settings = _ensure_settings_file(SETTINGS_PATH, DEFAULT_SETTINGS, FileMode.PLAIN)
	return existed


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
	var moved_count : int = 0
	
	for file_path in list_save_files():
		var file_name : String = file_path.get_file()
		var dest : String = ARCHIVE_SAVE_DIR + file_name
		
		var copy_error : Error = DirAccess.copy_absolute(file_path, dest)
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


# PRIVATE HELPER FUNCTIONS

## Load or create a settings file with defaults
func _ensure_settings_file(file_path : String, default_settings : Dictionary, mode : FileMode) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		var settings_data : Dictionary = default_settings.duplicate(true)
		_write_file(file_path, [settings_data], mode)
		return settings_data
	
	var loaded : Variant = _read_file(file_path, mode)[0]
	return update_dict(loaded, default_settings) if loaded is Dictionary else default_settings.duplicate(true)


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
