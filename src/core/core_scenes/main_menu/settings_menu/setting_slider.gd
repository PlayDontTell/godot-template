@tool
extends HBoxContainer

@onready var setting_label: Label = %SettingLabel
@onready var slider: HSlider = %Slider
@onready var value_label: Label = %ValueLabel
@onready var reset_btn: Button = %ResetBtn
@onready var v_separator: VSeparator = %VSeparator
@onready var left_btn: AnimatedButton = %LeftBtn
@onready var right_btn: AnimatedButton = %RightBtn

@export var setting_name : String
@export var label_text : String

var slider_is_initiated : bool = false

#enum DisplayType {
	#CONSOLE,
	#CLASSIC
#}
#@export var display_type : DisplayType = DisplayType.CLASSIC:
	#set(value):
		#display_type = value
		#apply_display_type(value)


func _ready() -> void:
	var slider_properties: Dictionary = Utils.get_hint_range_info(SettingsManager.settings, setting_name)
	if slider_properties.is_empty():
		push_error("setting_slider: no range hint found for '%s'" % setting_name)
		return
	
	slider.min_value = slider_properties.min_value
	slider.max_value = slider_properties.max_value
	slider.step = slider_properties.step
	slider.tick_count = slider_properties.tick_count
	
	setting_label.set_text(label_text)
	
	if setting_name in SettingsManager.default_settings:
		set_slider()
	
	slider_is_initiated = true


#func apply_display_type(new_display_type : DisplayType = display_type) -> void:
	#slider.hide()
	#v_separator.hide()
	#left_btn.hide()
	#right_btn.hide()
	#reset_btn.hide()
	#
	#match new_display_type:
		#DisplayType.CONSOLE:
			#v_separator.show()
			#left_btn.show()
			#right_btn.show()
		#
		#DisplayType.CLASSIC:
			#reset_btn.show()
			#slider.show()


func _on_slider_value_changed(value: float) -> void:
	if not slider_is_initiated or not setting_name in SettingsManager.default_settings:
		return
	
	SettingsManager.apply_setting(setting_name, value)
	set_slider()


func set_slider(new_value : float = SettingsManager.settings[setting_name]) -> void:
	reset_btn.disabled = new_value == SettingsManager.default_settings[setting_name]
	slider.set_value_no_signal(new_value)
	value_label.set_text(SettingsManager.settings.get_setting_text(setting_name))


func _on_reset_btn_pressed() -> void:
	if setting_name in SettingsManager.default_settings:
		_on_slider_value_changed(SettingsManager.default_settings[setting_name])
