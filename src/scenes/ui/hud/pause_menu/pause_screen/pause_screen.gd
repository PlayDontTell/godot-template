extends BaseMenu

signal resume_requested
signal settings_requested
signal main_menu_requested
signal exit_dialog_requested
signal save_requested
signal load_requested

@onready var save_btn: AnimatedButton = %SaveBtn
@onready var load_btn: AnimatedButton = %LoadBtn


func _ready() -> void:
	if not G.config.manual_saving_enabled:
		save_btn.hide()
	
	if not G.config.manual_loading_enabled:
		load_btn.hide()
	
	super._ready()


func _on_resume_btn_pressed() -> void:
	resume_requested.emit()


func _on_settings_btn_pressed() -> void:
	settings_requested.emit()


func _on_main_menu_btn_pressed() -> void:
	main_menu_requested.emit()


func _on_exit_btn_pressed() -> void:
	exit_dialog_requested.emit()


func _on_save_btn_pressed() -> void:
	save_requested.emit()


func _on_load_btn_pressed() -> void:
	load_requested.emit()
