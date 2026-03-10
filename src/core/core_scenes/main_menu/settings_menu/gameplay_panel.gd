extends ScrollContainer

@onready var lang_option_button: HBoxContainer = $VBoxContainer/LangOptionButton


func _ready() -> void:
	lang_option_button.add_options(LocaleManager.get_available_locales())
	
	# Add flag icons to languages
	for i in range(lang_option_button.option_button.item_count):
		var option: String = lang_option_button.option_button.get_item_text(i)
		var icon: Texture2D = LocaleManager.get_flag_icon(option)
		if icon:
			lang_option_button.option_button.set_item_icon(i, icon)
		
