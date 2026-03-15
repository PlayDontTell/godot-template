extends BaseMenu

const SAVE_FILE_CONTAINER = preload("uid://dotpmhbkow5vm")

signal back_requested
signal save_completed

@onready var save_file_list: VBoxContainer = %SaveFileList

@onready var create_anyway_dialog: CustomConfirmationDialog = %CreateAnywayDialog
@onready var load_anyway_dialog: CustomConfirmationDialog = %LoadAnywayDialog
@onready var overwrite_dialog: CustomConfirmationDialog = %OverwriteDialog
@onready var save_file_deletion_dialog: CustomConfirmationDialog = %SaveFileDeletionDialog

var mode : SaveManager.Mode = SaveManager.Mode.LOADING


func _ready() -> void:
	super._ready()


func _on_back_btn_pressed() -> void:
	back_requested.emit()


func update() -> void:
	# Remove existing save slot containers
	for save_file_container in save_file_list.get_children():
		if save_file_container.request_delete_save.is_connected(_ask_save_file_deletion):
			save_file_container.request_delete_save.disconnect(_ask_save_file_deletion)
		save_file_container.queue_free()
	
	var save_data_elements_to_load: Array = []
	
	# Add an empty entry to create a new save file if there are only save files and no save slots
	var save_files_only: bool = not G.config.has_save_slots
	var a_save_is_loaded: bool = not SaveManager.save_data._is_empty
	if save_files_only or a_save_is_loaded:
		save_data_elements_to_load.append({"save_data": SaveData.new(), "file_path": ""})
	
	if SaveManager.save_data_list.has(SaveManager.current_save_slot):
		# Add a save file container for each SaveData instance available
		for save_instance: Dictionary in SaveManager.save_data_list[SaveManager.current_save_slot]:
			save_data_elements_to_load.append(save_instance)
	
	for save_data_element in save_data_elements_to_load:
		var new_save_file_container = SAVE_FILE_CONTAINER.instantiate()
		new_save_file_container.save_data = save_data_element.save_data
		new_save_file_container.save_file_path = save_data_element.file_path
		new_save_file_container.request_delete_save.connect(_ask_save_file_deletion)
		new_save_file_container.request_create_save_file.connect(_ask_create_file)
		new_save_file_container.request_load_save_file.connect(_ask_load_file)
		new_save_file_container.mode = mode
		save_file_list.add_child(new_save_file_container)


func _ask_save_file_deletion(save_file_path : String, _save_name : String) -> void:
	save_file_deletion_dialog.format_dict = {"save_file_name": save_file_path.get_file()}
	save_file_deletion_dialog.refresh()
	save_file_deletion_dialog.activate()
	
	var confirmed: bool = await save_file_deletion_dialog.outcome_received
	if not confirmed:
		return
	
	SaveManager.delete_file(save_file_path)


func _ask_create_file() -> void:
	match mode:
		SaveManager.Mode.LOADING:
			if not SaveManager.save_data._is_empty:
				create_anyway_dialog.activate()
				
				var confirmed: bool = await create_anyway_dialog.outcome_received
				if not confirmed:
					return
			
			await SaveManager.create_new_save()
			G.request_core_scene.emit(&"GAME")
		
		SaveManager.Mode.SAVING:
			await SaveManager.manual_save()
			save_completed.emit()


func _ask_load_file(save_file_path: String, save_data: SaveData) -> void:
	match mode:
		SaveManager.Mode.LOADING:
			if not SaveManager.save_data._is_empty:
				load_anyway_dialog.format_dict = {"save_file_name": save_file_path}
				load_anyway_dialog.refresh()
				load_anyway_dialog.activate()
				
				var confirmed: bool = await load_anyway_dialog.outcome_received
				if not confirmed:
					return
			
			SaveManager.load_save_file(save_file_path)
			G.request_core_scene.emit(&"GAME")
		
		SaveManager.Mode.SAVING:
			if save_data != null and not save_data._is_empty:
				overwrite_dialog.format_dict = {"save_file_name": save_file_path}
				overwrite_dialog.refresh()
				overwrite_dialog.activate()
				
				var confirmed: bool = await overwrite_dialog.outcome_received
				if not confirmed:
					return
			
			await SaveManager.overwrite_save(save_file_path)
			save_completed.emit()
