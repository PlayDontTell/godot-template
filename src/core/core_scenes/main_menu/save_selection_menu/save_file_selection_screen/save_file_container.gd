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
var save_file_path : String


func _ready() -> void: # TODO improve global style
	var is_save_file_empty: bool = save_data and save_data._is_empty
	var is_new_save_file: bool = is_save_file_empty or not save_data
	
	if is_new_save_file:
		save_info.modulate.a = 0.
		save_name_value.hide()
		continue_btn.hide()
		delete_btn.hide()
	else:
		create_save_btn.hide()
		
		save_name_value.set_text(
			str(save_file_path.get_file())
		)
		date_saved_value.set_text(
			Utils.format_datetime(save_data.date_saved)
		)
		time_played_value.set_text(
			Utils.seconds_to_hours(save_data.time_played)
		)
		save_type_value.set_text(
			str(save_data.get_save_type_name())
		)
		game_version_value.set_text(
			str(save_data.game_version)
		)


func _on_delete_btn_pressed() -> void:
	request_delete_save.emit(save_file_path, save_data.save_name)


func _on_create_save_btn_pressed() -> void:
	# Create save file and play
	await SaveManager.create_new_save()
	G.request_core_scene.emit(&"GAME")


func _on_continue_btn_pressed() -> void:
	SaveManager.load_save_file(save_file_path)
	G.request_core_scene.emit(&"GAME")
