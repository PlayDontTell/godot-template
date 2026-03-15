extends BaseMenu

signal cancel_requested
signal exit_game_requested

@onready var exit_statement_label: Label = %ExitStatementLabel


func _ready() -> void:
	LocaleManager.bind_translation(
		exit_statement_label,
		"SAVE_AND_EXIT_DIALOG_STATEMENT",
		{"game_name": ProjectSettings.get_setting("application/config/name")}
	)
	super._ready()


func _on_cancel_btn_pressed() -> void:
	cancel_requested.emit()


func _on_exit_btn_pressed() -> void:
	exit_game_requested.emit()
