extends BaseMenu

signal cancel_requested
signal exit_game_requested

@onready var exit_statement_label: Label = %ExitStatementLabel


func _ready() -> void:
	exit_statement_label.set_text(
			tr("EXIT_DIALOG_STATEMENT").format({
				"game_name": ProjectSettings.get_setting("application/config/name"),
			})
		)


func _on_cancel_btn_pressed() -> void:
	cancel_requested.emit()


func _on_exit_btn_pressed() -> void:
	exit_game_requested.emit()
