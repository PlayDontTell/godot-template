extends BaseMenu

signal play_requested
signal settings_requested
signal credits_requested
signal exit_dialog_requested

@onready var title_label: Label = %TitleLabel


func _ready() -> void:
	title_label.set_text(ProjectSettings.get_setting("application/config/name"))


func _on_play_btn_pressed() -> void:
	play_requested.emit()


func _on_settings_btn_pressed() -> void:
	settings_requested.emit()


func _on_credits_btn_pressed() -> void:
	credits_requested.emit()


func _on_exit_btn_pressed() -> void:
	exit_dialog_requested.emit()
