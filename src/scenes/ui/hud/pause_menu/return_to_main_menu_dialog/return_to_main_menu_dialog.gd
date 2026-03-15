extends BaseMenu

signal cancel_requested
signal main_menu_requested

@onready var exit_statement_label: Label = %ExitStatementLabel


func _ready() -> void:
	super._ready()


func _on_cancel_btn_pressed() -> void:
	cancel_requested.emit()


func _on_main_menu_btn_pressed() -> void:
	main_menu_requested.emit()
