extends BaseMenu

const SAVE_FILE_CONTAINER = preload("uid://dotpmhbkow5vm")

signal back_requested

@onready var save_file_list: VBoxContainer = %SaveFileList
@onready var save_file_deletion_dialog: Control = %SaveFileDeletionDialog


func _ready() -> void:
	self.deactivated.connect(save_file_deletion_dialog.deactivate)
	super._ready()


func _on_back_btn_pressed() -> void:
	save_file_deletion_dialog.deactivate()
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
		save_file_list.add_child(new_save_file_container)


func _ask_save_file_deletion(save_file_path : String, _save_name : String) -> void:
	save_file_deletion_dialog.save_file_name_to_delete = save_file_path.get_file()
	save_file_deletion_dialog.refresh_label()
	save_file_deletion_dialog.activate()
	
	await save_file_deletion_dialog.save_deletion_requested
	
	SaveManager.delete_file(save_file_path)
	
	save_file_deletion_dialog.deactivate()
