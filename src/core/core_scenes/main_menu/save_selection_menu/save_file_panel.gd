extends PanelContainer

signal request_delete_save(save_file_path : String, save_name : String)


@onready var continue_btn: Button = %ContinueBtn
@onready var create_save_btn: Button = %CreateSaveBtn
@onready var delete_btn: Button = %DeleteBtn

@onready var save_name_value: Label = %SaveNameValue

@onready var save_info: GridContainer = %SaveInfo

@onready var date_saved_value: Label = %DateSavedValue
@onready var time_played_value: Label = %TimePlayedValue
@onready var save_type_value: Label = %SaveTypeValue
@onready var game_version_value: Label = %GameVersionValue

@export var save_data : SaveData
var _save_file_path : String


func _ready() -> void:
	var is_save_file_empty: bool = save_data.time_played == 0.
	var is_new_save_file: bool = is_save_file_empty or not save_data
	
	save_info.visible = not is_new_save_file
	save_name_value.visible = not is_new_save_file
	continue_btn.visible = not is_new_save_file
	delete_btn.visible = not is_new_save_file
	
	create_save_btn.visible = is_new_save_file
	
	if save_data:
		save_name_value.set_text(
			str(save_data.save_name)
		)
		date_saved_value.set_text(
			str(save_data.date_saved)
		)
		time_played_value.set_text(
			str(save_data.time_played)
		)
		save_type_value.set_text(
			str(save_data.get_save_type_name())
		)
		game_version_value.set_text(
			str(save_data.game_version)
		)


func _on_delete_btn_pressed() -> void:
	request_delete_save.emit(_save_file_path, save_data.save_name)


func _on_create_save_btn_pressed() -> void:
	pass
