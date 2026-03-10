extends BaseMenu

signal save_deletion_requested

@onready var deletion_statement_label: Label = %DeletionStatementLabel

var save_file_name_to_delete: String = ""


func _ready() -> void:
	refresh_label()
	super._ready()


func refresh_label() -> void:
	LocaleManager.bind_translation(
		deletion_statement_label,
		"SAVE_FILE_DELETION_DIALOG_STATEMENT",
		{"save_file_name": save_file_name_to_delete}
	)


func _on_cancel_btn_pressed() -> void:
	deactivate()


func _on_delete_btn_pressed() -> void:
	save_deletion_requested.emit()
