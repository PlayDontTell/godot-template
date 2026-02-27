extends HBoxContainer

@onready var setting_label: Label = %SettingLabel
@onready var slider: HSlider = %Slider
@onready var value_label: Label = %ValueLabel
@onready var reset_btn: Button = %ResetBtn

@export var setting_name : String
@export var label_text : String

var slider_is_initiated : bool = false


func _ready() -> void:
	for p in G.settings.get_property_list():
		if p.name == setting_name:
			if p.hint == PROPERTY_HINT_RANGE:
				var parts = p.hint_string.split(",")
				var min_val = float(parts[0])
				var max_val = float(parts[1])
				var step = float(parts[2])
				
				# Initialize the Slider parameters
				slider.min_value = min_val
				slider.max_value = max_val
				slider.step = step
				@warning_ignore("narrowing_conversion")
				slider.tick_count = (max_val - min_val) / step + 1
	
	setting_label.set_text(tr(label_text))
	
	if setting_name in G.default_settings:
		set_slider()
	
	slider_is_initiated = true


func _on_slider_value_changed(value: float) -> void:
	if not slider_is_initiated or not setting_name in G.default_settings:
		return
	
	G.adjust_setting(setting_name, value)
	set_slider()


func set_slider(new_value : float = G.settings[setting_name]) -> void:
	reset_btn.disabled = new_value == G.default_settings[setting_name]
	slider.set_value_no_signal(new_value)
	value_label.set_text(G.get_setting_text(setting_name))


func _on_reset_btn_pressed() -> void:
	if setting_name in G.default_settings:
		_on_slider_value_changed(G.default_settings[setting_name])
