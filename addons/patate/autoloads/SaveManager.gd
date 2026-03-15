extends Node

signal data_is_ready

signal save_file_deleted
signal save_slot_selected

signal before_screenshot
signal after_screenshot

# each _save_data_list key is a used save_slot
# with its associated SaveData instances (decrypted save files)
var save_data_list: Dictionary[int, Array]

var current_save_file_path: String
var current_save_slot: int = 0


enum Mode {
	SAVING,
	LOADING,
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Initialize game folders (saves, settings, etc.)
	init_folders()
	
	# Warn if no encrypt key has been defined
	if G.config.SAVE_ENCRYPT_KEY.is_empty():
		push_warning("No encrypt key defined in project_config.tres, files will not be fully encrypted.")


func _process(delta: float) -> void:
	save_data.time_since_start += delta
	if not get_tree().paused:
		save_data.time_played += delta


func select_save_slot(save_slot_idx: int) -> void:
	if current_save_slot != save_slot_idx:
		current_save_slot = save_slot_idx
		save_slot_selected.emit()


func load_save_file(path: String) -> void:
	_load_data(path, true)


func unload() -> void:
	save_data = SaveData.new()


func create_new_save() -> void:
	await manual_save()


func overwrite_save(path: String) -> void:                                                                                                                                                                                                  
	await _save_data(path, SaveData.SaveType.MANUAL_SAVE)


## Called by the game at checkpoints, scene changes, timers, etc.
## Always creates a new file. Prunes oldest if over the limit.
func auto_save() -> void:
	var path := _build_save_path("autosave")
	await _save_data(path, SaveData.SaveType.AUTO_SAVE)
	_prune_saves("autosave", G.config.max_autosaves)


## Called by the player from a menu. Creates a new file each time.
## Prunes oldest if max_manual_saves > 0.
func manual_save(display_name : String = "") -> void:
	var path := _build_save_path("manual")
	if not display_name.is_empty():
		save_data.save_name = display_name
	await _save_data(path, SaveData.SaveType.MANUAL_SAVE)
	_prune_saves("manual", G.config.max_manual_saves)


## Called by the player via a keybind (F5 typically). No UI.
## Creates a new file. Prunes oldest if over the limit.
func quick_save() -> void:
	var path := _build_save_path("quicksave")
	await _save_data(path, SaveData.SaveType.QUICK_SAVE)
	_prune_saves("quicksave", G.config.max_quicksaves)


## Load the most recent quicksave (F9 typically). No UI.
func quick_load() -> void:
	var latest := _get_latest_save("quicksave")
	if latest.is_empty():
		push_warning("No quicksave found.")
		return
	_load_data(latest, true)


## Builds a filename like "slot0_autosave_2026-03-07_14-32.save"
func _build_save_path(type_prefix : String) -> String:
	var timestamp: String = Utils.format_datetime(Time.get_datetime_string_from_system(), Utils.TimeFormat.FILE_NAME_COMPATIBLE)
	var slot_prefix := "slot%d_" % current_save_slot if G.config.has_save_slots else ""
	var file_name := slot_prefix + type_prefix + "_" + timestamp + G.config.SAVE_FILE_EXTENSION
	return G.config.SAVE_DIR + file_name


## Returns all filenames matching a type prefix (and current slot if applicable)
func _list_saves_by_type(type_prefix : String, save_slot: int = current_save_slot) -> Array[String]:
	var dir := DirAccess.open(G.config.SAVE_DIR)
	if not dir:
		return []
	
	var slot_prefix := "slot%d_" % save_slot if G.config.has_save_slots else ""
	var full_prefix := slot_prefix + type_prefix
	var matching : Array[String] = []
	
	for file_name in dir.get_files():
		if file_name.begins_with(full_prefix) and file_name.ends_with(G.config.SAVE_FILE_EXTENSION):
			matching.append(G.config.SAVE_DIR + file_name)
	
	matching.sort()
	return matching


## Deletes oldest files until count is within limit
func _prune_saves(type_prefix : String, max_count : int) -> void:
	if max_count <= 0:
		return
	
	var matching := _list_saves_by_type(type_prefix)
	
	while matching.size() > max_count:
		var oldest : String = matching.pop_front()
		delete_file(oldest, true)


## Returns the full path of the most recent save of a given type
func _get_latest_save(type_prefix : String) -> String:
	var matching := _list_saves_by_type(type_prefix)
	if matching.is_empty():
		return ""
	return matching.back()


func get_encrypt_key() -> String:
	return G.config.SAVE_ENCRYPT_KEY if G.config else ""

func get_save_dir() -> String:
	return G.config.SAVE_DIR if G.config else "user://saves/"

func get_bin_dir() -> String:
	return G.config.BIN_DIR if G.config else "user://bin/"

func get_files_extension() -> String:
	return G.config.SAVE_FILE_EXTENSION if G.config else ".data"

const TEMP_FILE_SUFFIX : String = ".tmp"

# Cannot be a constant since its needs parse time to initialize
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
	if event_data not in save_data.event_log:
		save_data.event_log.append(event_data)


## Save current game save_data with screenshot (async - must await)
## Uses temporary file for transaction safety to prevent corruption on crash.
## Returns true on success, false on failure.
func _save_data(file_path : String = current_save_file_path, save_type: SaveData.SaveType = SaveData.SaveType.AUTO_SAVE) -> bool:
	save_data.game_name = ProjectSettings.get_setting("application/config/name")
	save_data._is_empty = false
	save_data.save_slot = current_save_slot
	save_data.game_version = ProjectSettings.get_setting("application/config/version")
	save_data.date_saved = Time.get_datetime_string_from_system()
	save_data.save_type = save_type
	var save_image : Image = await _capture_screenshot()
	save_data.save_image = save_image
	
	# Write to temporary file first to prevent corruption if crash occurs during save
	var temp_path : String = file_path + TEMP_FILE_SUFFIX
	if not _write_file(temp_path, [save_data], FileMode.ENCRYPTED):
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


## Load save_data from a save file, optionally without setting it as current
func _load_data(file_path : String = current_save_file_path, set_as_current : bool = true) -> Array:
	var file_data : Array = _read_file(file_path, FileMode.ENCRYPTED)
	
	if file_data.is_empty():
		#push_error("Failed to load save file: " + file_path)
		var fallback := [SaveData.new()]
		if set_as_current:
			save_data = fallback[0]
			is_data_ready = true
			data_is_ready.emit()
		return fallback
	
	if file_data[0].game_name != ProjectSettings.get_setting("application/config/name"):
		push_warning("Save file '%s' belongs to a different game, skipping." % file_path)
		return []
	
	file_data[0] = update_save_data(file_data[0])
	
	if set_as_current:
		current_save_file_path = file_path
		save_data = file_data[0]
		is_data_ready = true
		data_is_ready.emit()
	
	return file_data


func list_save_data(directory: String = G.config.SAVE_DIR) -> Dictionary[int, Array]:
	save_data_list.clear()
	
	var save_data_instances: Array[Dictionary]
	
	# List all SaveData instances saved in directory
	for file in list_save_files(directory):
		for content in _read_file(file):
			if content is SaveData:
				save_data_instances.append(
					{
						"save_data": content,
						"file_path": file,
					}
				)
	
	# Associate each SaveData instance to a save_slot
	for save_data_element: Dictionary in save_data_instances:
		# If a save_slot has been been assigned yet, initiate it as an empty array
		if not save_data_list.has(save_data_element.save_data.save_slot):
			save_data_list[save_data_element.save_data.save_slot] = []
		
		save_data_list[save_data_element.save_data.save_slot].append(save_data_element)
	
	# Sort SaveData instances from newest to oldest, in each save_slot list
	for save_slot: int in save_data_list.keys():
		save_data_list[save_slot].sort_custom(func(a, b): return a.save_data.date_saved > b.save_data.date_saved)
	
	return save_data_list


## List all save files in the save directory (returns full paths)
func list_save_files(directory: String = G.config.SAVE_DIR) -> Array[String]:
	var files : Array[String] = []
	var dir : DirAccess = DirAccess.open(directory)
	
	if not dir:
		push_error("Failed to access save directory")
		return []
	
	for file_name in dir.get_files():
		if file_name.ends_with(G.config.SAVE_FILE_EXTENSION):
			files.append(directory + file_name)
	
	return files



## Move all save files to archive directory. Returns number of files successfully moved.
func archive_save_data() -> int:
	init_folders([G.config.ARCHIVE_SAVE_DIR])
	
	var moved_count : int = 0
	
	var existing_archived_save_files: Array[String] = list_save_files(G.config.ARCHIVE_SAVE_DIR)
	
	for file_path: String in list_save_files():
		var file_name : String = file_path.get_file()
		var destination : String = G.config.ARCHIVE_SAVE_DIR + file_name
		
		# If the file name already exists, find the smallest increment available
		# add to the name
		var incremented_destination: String = destination
		var name_increment: int = 1
		while incremented_destination in existing_archived_save_files:
			name_increment += 1
			incremented_destination = destination.trim_suffix(G.config.SAVE_FILE_EXTENSION) + "_" + str(name_increment) + G.config.SAVE_FILE_EXTENSION
		destination = incremented_destination
		
		# Create a readable json_file of the SaveData
		var json_destination : String = destination.trim_suffix(G.config.SAVE_FILE_EXTENSION) + ".json"
		var json_file : FileAccess = FileAccess.open(json_destination, FileAccess.WRITE)
		if not json_file:
			push_error("Failed to write JSON file: " + json_destination)
			continue
		
		var file_data_array: Array = _load_data(file_path, false)
		var file_data: SaveData = file_data_array[0]
		
		var save_data_dictionary: Dictionary = {}
		for property in file_data.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				save_data_dictionary[property.name] = file_data.get(property.name)
		
		var json_text : String = JSON.stringify(save_data_dictionary, "\t")
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
	return moved_count


## Delete a file at the given path. Returns true on success.
func delete_file(file_path : String, silent: bool = false) -> bool:
	if not FileAccess.file_exists(file_path):
		push_warning("Attempted to delete non-existent file: " + file_path)
		return false
	
	var error : Error = DirAccess.remove_absolute(file_path)
	if error != OK:
		push_error("Failed to delete file: " + file_path + " (Error: " + str(error) + ")")
		return false
	
	if file_path.ends_with(G.config.SAVE_FILE_EXTENSION) and not silent:
		save_file_deleted.emit()
	
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
		file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.READ, get_encrypt_key())
	else:
		file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		push_error("Failed to read file: " + file_path)
		return []
	
	var contents : Array = []
	while file.get_position() < file.get_length():
		contents.append(file.get_var(true))
	
	file.close()
	
	return contents


## Write save_data to a file. Returns true on success.
func _write_file(file_path : String, data_array : Array, mode : FileMode = FileMode.ENCRYPTED) -> bool:
	var file : FileAccess
	
	if mode == FileMode.ENCRYPTED:
		file = FileAccess.open_encrypted_with_pass(file_path, FileAccess.WRITE, get_encrypt_key())
	else:
		file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		push_error("Failed to write file: " + file_path)
		return false
	
	for element in data_array:
		file.store_var(element, true)
	
	file.close()
	
	return true


## Capture a screenshot and resize it for save files
func _capture_screenshot() -> Image:
	before_screenshot.emit()
	
	# Waiting 2 frames for elements to hide themselves during screenshot
	# Like the pause menu
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img : Image = get_viewport().get_texture().get_image()
	img.resize(G.config.SCREENSHOT_SIZE.x, G.config.SCREENSHOT_SIZE.y, Image.INTERPOLATE_NEAREST)
	
	after_screenshot.emit()
	
	return img
