extends HBoxContainer

@onready var label: Label = %Label
@onready var option_button: OptionButton = %OptionButton

@export var setting_name : String
@export var label_text : String

var options : Array = []

func _ready() -> void:
	for p in SettingsManager.settings.get_property_list():
		if p.name == setting_name:
			if p.hint == PROPERTY_HINT_ENUM:
				options = p.hint_string.split(",")
	
	label.set_text(label_text)


func add_options(requested_options: Array) -> void:
	for requested_option in requested_options:
		if not requested_option in options:
			options.append(requested_option)
	
	option_button.clear()
	
	for option in options:
		option_button.add_item(option)
	
	if setting_name in SettingsManager.default_settings:
		option_button.select(options.find(SettingsManager.settings[setting_name]))


func _on_option_button_item_selected(index: int) -> void:
	if setting_name in SettingsManager.default_settings:
		SettingsManager.apply_setting(setting_name, options[index])
