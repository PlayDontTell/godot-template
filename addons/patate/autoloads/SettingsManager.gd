extends Node
## To change project defaults, edit "res://addons/patate/classes/game_settings.gd"

var default_settings: GameSettings = GameSettings.new()
var settings: GameSettings = GameSettings.new()

signal setting_adjusted(setting: String, value: Variant)

## Signals to tell the WorldEnvironment node to set itself
signal adjust_brightness(intensity : float)
signal adjust_contrast(intensity : float)
signal adjust_saturation(intensity : float)


func apply_setting(setting: String, value: Variant) -> void:
	save_setting_value(
		setting,
		settings.adjust_setting(setting, value),
	)


func apply_settings(settings_to_apply: GameSettings = settings) -> void:
	for property in settings_to_apply.get_property_list():
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		
		if property.name == "input_bindings":
			continue	# handled separately by InputManager
		
		var validated := settings.adjust_setting(property.name, settings_to_apply.get(property.name))
		if validated != null:
			settings.set(property.name, validated)
	
	save_settings()



func save_setting_value(setting: String, value: Variant) -> void:
	if value == null:
		return
	
	if settings.get(setting) != value:
		settings.set(setting, value)
		setting_adjusted.emit(setting, value)
	
	# don't save settings if in expo mode, because we don't need to save settings between games
	if not G.is_expo():
		save_settings()


func load_settings() -> bool:
	var settings_path: String = G.config.BIN_DIR + "game_settings.cfg"
	var cfg := ConfigFile.new()
	
	if cfg.load(settings_path) != OK:
		return false
	
	for section in cfg.get_sections():
		for key in cfg.get_section_keys(section):
			var value = cfg.get_value(section, key)
			if settings.get(key) != null:
				settings.set(key, value)
	return true


func save_settings() -> void:
	var settings_path: String = G.config.BIN_DIR + "game_settings.cfg"
	
	var cfg := ConfigFile.new()
	for property in settings.get_property_list():
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		if property.name == "input_bindings":
			continue
		cfg.set_value("settings", property.name, settings.get(property.name))
	cfg.save(settings_path)
