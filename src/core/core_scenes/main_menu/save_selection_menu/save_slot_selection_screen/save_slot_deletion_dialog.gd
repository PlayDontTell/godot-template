extends BaseMenu

signal save_reset_requested

@onready var deletion_statement_label: Label = %DeletionStatementLabel


func _ready() -> void:
	refresh_label()
	super._ready()


func refresh_label(save_slot_idx: int = SaveManager.current_save_slot) -> void:
	LocaleManager.bind_translation(
		deletion_statement_label,
		"RESET_SAVE_SLOT_DIALOG_STATEMENT",
		{"save_slot_idx": save_slot_idx + 1}
	)


func _on_cancel_btn_pressed() -> void:
	deactivate()


func _on_reset_btn_pressed() -> void:
	save_reset_requested.emit()
