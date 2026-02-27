extends HBoxContainer

@onready var label: Label = %Label
@onready var option_button: OptionButton = %OptionButton

@export var setting_name : String
@export var label_text : String

var options : Array = []

func _ready() -> void:
	for p in G.settings.get_property_list():
		if p.name == setting_name:
			if p.hint == PROPERTY_HINT_ENUM:
				options = p.hint_string.split(",")
	
	for option in options:
		option_button.add_item(option)
	
	label.set_text(tr(label_text))
	
	if setting_name in G.default_settings:
		option_button._select_int(options.find(G.settings[setting_name]))


func _on_option_button_item_selected(index: int) -> void:
	if setting_name in G.default_settings:
		G.adjust_setting(setting_name, options[index])
