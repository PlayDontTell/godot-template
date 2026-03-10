extends MarginContainer

signal request_save_slot_selection(save_slot_index: int)
signal request_save_slot_reset(save_slot_index: int)

@onready var reset_btn: AnimatedButton = %ResetBtn
@onready var select_btn: AnimatedButton = %SelectBtn

@onready var save_info_container: GridContainer = %SaveInfoContainer

@onready var save_slot_index_value: Label = %SaveSlotIndexValue
@onready var date_saved_value: Label = %DateSavedValue
@onready var time_played_value: Label = %TimePlayedValue
@onready var game_version_value: Label = %GameVersionValue

var save_data: SaveData


func _ready() -> void:
	if not save_data:
		save_data = SaveData.new()
	
	date_saved_value.set_text(
		Utils.format_datetime(save_data.date_saved)
	)
	time_played_value.set_text(
		Utils.seconds_to_hours(save_data.time_played)
	)
	game_version_value.set_text(
		str(save_data.game_version)
	)
	
	save_slot_index_value.set_text(
		str(save_data.save_slot + 1)
	)
	
	if save_data.save_image:
		select_btn.icon = ImageTexture.create_from_image(save_data.save_image)
	
	if save_data._is_empty:
		save_info_container.modulate.a = 0.
		reset_btn.hide()


func _on_select_btn_pressed() -> void:
	request_save_slot_selection.emit(save_data.save_slot)


func _on_reset_btn_pressed() -> void:
	request_save_slot_reset.emit(save_data.save_slot)
