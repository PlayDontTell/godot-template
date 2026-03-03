extends Node

signal data_is_ready

func get_encrypt_key() -> String:
	return G.config.SAVE_ENCRYPT_KEY if G.config else ""

func get_save_dir() -> String:
	return G.config.SAVE_DIR if G.config else "user://saves/"

func get_bin_dir() -> String:
	return G.config.BIN_DIR if G.config else "user://bin/"

func get_files_extension() -> String:
	return G.config.FILES_EXTENSION if G.config else ".data"

const DEFAULT_SAVE_TEXTURE : Texture2D = preload("res://icon.svg")
const SCREENSHOT_SIZE : Vector2i = Vector2i(80, 40)
const TEMP_FILE_SUFFIX : String = ".tmp"

# Cannot be a cosnt since its needs parse time to initialize
# Initialized in init_folders() method
var SCREENSHOT_DIR : String

enum FileMode { ENCRYPTED, PLAIN }

var is_data_ready : bool = false
var save_data : SaveData = SaveData.new()


func init_folders(additional_folders : PackedStringArray = []) -> void:
	SCREENSHOT_DIR = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES) + "/" + Utils.sanitize_string(ProjectSettings.get_setting("application/config/name")) + "/"
	
	var directories_init : Array = [
		G.config.SAVE_DIR,
		G.config.BIN_DIR,
		SCREENSHOT_DIR,
		G.config.ARCHIVE_SAVE_DIR
	]
	directories_init.append_array(additional_folders)
	
	for dir_path in directories_init:
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_dir_recursive_absolute(dir_path)


## Log an event to the event log (avoids duplicates)
func log_event(event_data : Variant) -> void:
	if not is_instance_valid(save_data):
		push_warning("Cannot log event - save_data not initialized")
		return
	
	if event_data not in save_data.event_log:
		save_data.event_log.append(event_data)


### Load settings from file or create defaults. Returns true if settings existed, false if created new.
#func load_settings() -> bool:
	#var settings_path: String = G.config.BIN_DIR + "game_settings" + G.config.FILES_EXTENSION
	#if not FileAccess.file_exists(settings_path):
		#return false
	#
	#var loaded : Array = _read_file(settings_path, FileMode.PLAIN)
	#if not loaded.is_empty() and loaded[0] is GameSettings:
		#SettingsManager.settings = loaded[0]
		#return true
	#
	#return false
#
#
### Save current settings to file
#func save_settings() -> void:
	#var settings_path: String = G.config.BIN_DIR + "game_settings" + G.config.FILES_EXTENSION
	#_write_file(settings_path, [SettingsManager.settings], FileMode.PLAIN)


## Create a new save file with given world name. Returns full file path, or empty string on failure.
## If a save with the same name exists, auto-increments with a number suffix.
func create_save_file(save_name : String) -> String:
	is_data_ready = false
	
	save_data = SaveData.new()
	
	# Find unique filename if collision occurs
	var safe_name : String = Utils.sanitize_string(save_name)
	var file_name : String = safe_name + G.config.FILES_EXTENSION
	var file_path : String = G.config.SAVE_DIR + file_name
	var counter : int = 1
	
	while FileAccess.file_exists(file_path):
		push_warning("Save file already exists, auto-incrementing: " + file_path)
		file_name = safe_name + "_" + str(counter) + G.config.FILES_EXTENSION
		file_path = G.config.SAVE_DIR + file_name
		counter += 1
	
	if not _write_file(file_path, [save_data, DEFAULT_SAVE_TEXTURE], FileMode.ENCRYPTED):
		push_error("Failed to create save file")
		return ""
	
	is_data_ready = true
	data_is_ready.emit()
	
	return file_path


## Save current game save_data with screenshot (async - must await)
## Uses temporary file for transaction safety to prevent corruption on crash.
## Returns true on success, false on failure.
func _save_data(file_path : String) -> bool:
	save_data.game_version = ProjectSettings.get_setting("application/config/version")
	save_data.date_saved = Time.get_datetime_string_from_system()
	
	var save_img : Image = await _capture_screenshot()
	
	# Write to temporary file first to prevent corruption if crash occurs during save
	var temp_path : String = file_path + TEMP_FILE_SUFFIX
	if not _write_file(temp_path, [save_data, save_img], FileMode.ENCRYPTED):
		push_error("Failed to write temp save file")
		delete_file(temp_path)  # Clean up failed temp file
		return false
	
	# Atomic rename - if this succeeds, save is complete. If it fails, original file remains intact.
	var error : Error = DirAccess.rename_absolute(temp_path, file_path)
	if error != OK:
		push_error("Failed to finalize save file: " + str(error))
		delete_file(temp_path)  # Clean up temp file on rename failure
		return false
	prints()
	return true


## Load save_data from a save file, optionally without setting it as current
func _load_data(file_path : String, set_as_current : bool = true) -> Array:
	var file_data : Array = _read_file(file_path, FileMode.ENCRYPTED)
	
	if file_data.is_empty():
		#push_error("Failed to load save file: " + file_path)
		var fallback := [SaveData.new(), DEFAULT_SAVE_TEXTURE]
		if set_as_current:
			save_data = fallback[0]
			is_data_ready = true
			data_is_ready.emit()
		return fallback
	
	if file_data.size() < 2:
		file_data.append(DEFAULT_SAVE_TEXTURE)
	
	file_data[0] = update_save_data(file_data[0])
	
	if set_as_current:
		save_data = file_data[0]
		is_data_ready = true
		data_is_ready.emit()
	
	return file_data


## List all save files in the save directory (returns full paths)
func list_save_files() -> Array:
	var files : Array = []
	var dir : DirAccess = DirAccess.open(G.config.SAVE_DIR)
	
	if not dir:
		push_error("Failed to access save directory")
		return []
	
	for file_name in dir.get_files():
		if file_name.ends_with(G.config.FILES_EXTENSION):
			files.append(G.config.SAVE_DIR + file_name)
	
	return files



## Move all save files to archive directory. Returns number of files successfully moved.
func archive_save_data() -> int:
	init_folders([G.config.ARCHIVE_SAVE_DIR])
	
	var moved_count : int = 0
	
	for file_path in list_save_files():
		var file_name : String = file_path.get_file()
		var destination : String = G.config.ARCHIVE_SAVE_DIR + file_name
		
		# TODO : already existing files are written over (deleted)
		var file_already_exist
		
		# Create a readable json_file of the SaveData
		var json_destination : String = destination.trim_suffix(G.config.FILES_EXTENSION) + ".json"
		var json_file : FileAccess = FileAccess.open(json_destination, FileAccess.WRITE)
		assert(json_file.is_open())
		var json_text : String = JSON.stringify(save_data, "\t")
		json_file.store_string(json_text)
		json_file.close()
		
		# Copy the save file to the its archiving folder
		var copy_error : Error = DirAccess.copy_absolute(file_path, destination)
		if copy_error != OK:
			push_error("Failed to copy file to archive: " + file_path)
			continue
		
		# Delete the original save file
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


## Migrates a loaded SaveData to the current schema:
## - fills missing scalar properties with current defaults
## - fills missing dictionary keys with defaults (recursive)
## Call after loading any save file.
func update_save_data(loaded: SaveData) -> SaveData:
	var defaults := SaveData.new()
	for p in defaults.get_property_list():
		if not p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		var default_val: Variant = defaults.get(p.name)
		var loaded_val: Variant = loaded.get(p.name)

		if loaded_val == null:
			# Property missing entirely — add it.
			loaded.set(p.name, default_val)
		elif loaded_val is Dictionary and default_val is Dictionary:
			# Fill missing keys inside dictionaries.
			loaded.set(p.name, _fill_missing_dict_keys(loaded_val, default_val))

	return loaded


## Recursively copies keys from [default] that are absent in [target].
## Does not overwrite existing keys — preserves player data.
func _fill_missing_dict_keys(target: Dictionary, default: Dictionary) -> Dictionary:
	for key in default:
		if not target.has(key):
			target[key] = default[key]
		elif target[key] is Dictionary and default[key] is Dictionary:
			target[key] = _fill_missing_dict_keys(target[key], default[key])
	return target


## Read a file and return its contents as an array
func _read_file(file_path : String, mode : FileMode = FileMode.ENCRYPTED) -> Array:
	var file : FileAccess
	
	if mode == FileMode.ENCRYPTED:
		file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.READ, G.config.SAVE_ENCRYPT_KEY)
	else:
		file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		#push_error("Failed to read file: " + file_path)
		return []
	
	var contents : Array = []
	while file.get_position() < file.get_length():
		contents.append(file.get_var(true))
	
	return contents


## Write save_data to a file. Returns true on success.
func _write_file(file_path : String, data_array : Array, mode : FileMode = FileMode.ENCRYPTED) -> bool:
	var file : FileAccess
	
	if mode == FileMode.ENCRYPTED:
		file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.WRITE, G.config.SAVE_ENCRYPT_KEY)
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
