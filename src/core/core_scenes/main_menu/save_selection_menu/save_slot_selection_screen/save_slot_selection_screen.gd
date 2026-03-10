extends BaseMenu

const SAVE_SLOT_CONTAINER = preload("uid://sm1lek67emkb")

signal save_slot_selected
signal back_requested

@onready var save_slot_list: GridContainer = %SaveSlotList
@onready var save_slot_reset_dialog: Control = %SaveSlotResetDialog


func _ready() -> void:
	self.deactivated.connect(save_slot_reset_dialog.deactivate)
	super._ready()


func _on_back_btn_pressed() -> void:
	save_slot_reset_dialog.deactivate()
	back_requested.emit()


func update() -> void:
	# Remove existing save slot containers
	for save_slot_container in save_slot_list.get_children():
		if save_slot_container.request_save_slot_selection.is_connected(_select_save_slot):
			save_slot_container.request_save_slot_selection.disconnect(_select_save_slot)
		if save_slot_container.request_save_slot_reset.is_connected(_ask_save_slot_reset):
			save_slot_container.request_save_slot_reset.disconnect(_ask_save_slot_reset)
		save_slot_container.queue_free()
	
	# Add a save slot container for each save slot possible
	for save_slot_idx in range(G.config.max_save_slots):
		var save_data: SaveData
		
		var save_slot_is_listed: bool = SaveManager.save_data_list.has(save_slot_idx)
		var save_slot_has_save_data_instances: bool = false
		if save_slot_is_listed:
			save_slot_has_save_data_instances = SaveManager.save_data_list[save_slot_idx].size() > 0
		
		if save_slot_has_save_data_instances:
			save_data = SaveManager.save_data_list[save_slot_idx][0].save_data
		else:
			save_data = SaveData.new()
			save_data.save_slot = save_slot_idx
		
		var new_save_slot_container = SAVE_SLOT_CONTAINER.instantiate()
		new_save_slot_container.save_data = save_data
		new_save_slot_container.request_save_slot_selection.connect(_select_save_slot)
		new_save_slot_container.request_save_slot_reset.connect(_ask_save_slot_reset)
		
		save_slot_list.add_child(new_save_slot_container)


func _select_save_slot(save_slot_idx: int) -> void:
	SaveManager.select_save_slot(save_slot_idx)
	save_slot_selected.emit()


func _ask_save_slot_reset(save_slot_idx: int) -> void:
	if not SaveManager.save_data_list.has(save_slot_idx):
		return
	
	save_slot_reset_dialog.refresh_label(save_slot_idx)
	save_slot_reset_dialog.activate()
	
	await save_slot_reset_dialog.save_reset_requested
	
	for save_element in SaveManager.save_data_list[save_slot_idx]:
		SaveManager.delete_file(save_element.file_path)
	
	save_slot_reset_dialog.deactivate()
