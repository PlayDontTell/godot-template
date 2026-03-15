class_name CustomConfirmationDialog
extends BaseMenu

signal outcome_received(confirmed: bool)

@export var statement_key: String
@export var confirm_btn_key: String
@export var cancel_btn_key: String = "SAVE_FILE_DELETION_DIALOG_CANCEL"

@onready var statement_label: Label = %StatementLabel
@onready var confirm_btn: Button = %ConfirmBtn
@onready var cancel_btn: Button = %CancelBtn

var format_dict: Dictionary = {}


func _ready() -> void:
	refresh()
	super._ready()


func refresh() -> void:
	LocaleManager.bind_translation(statement_label, statement_key, format_dict)
	confirm_btn.set_text(confirm_btn_key)
	cancel_btn.set_text(cancel_btn_key)


func _on_cancel_btn_pressed() -> void:
	deactivate()
	outcome_received.emit(false)


func _on_confirm_btn_pressed() -> void:
	deactivate()
	outcome_received.emit(true)
