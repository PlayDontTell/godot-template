extends HBoxContainer

@onready var label: Label = %Label
@onready var toggle_btn: CheckButton = %ToggleBtn

@export var setting_name : String
@export var label_text : String


func _ready() -> void:
	label.set_text(tr(label_text))
	
	if setting_name in G.default_settings:
		toggle_btn.set_pressed_no_signal(G.settings[setting_name])


func _on_toggle_btn_toggled(toggled_on: bool) -> void:
	if setting_name in G.default_settings:
		G.adjust_setting(setting_name, toggled_on)
