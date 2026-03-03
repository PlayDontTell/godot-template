extends Node
## To change project defaults, edit res://config/default_settings.tres in the inspector.

var default_settings : GameSettings = GameSettings.new()
var settings : GameSettings = GameSettings.new()

signal setting_adjusted(setting : String, value : Variant)

## Signals to tell the WorldEnvironment node to set itself
signal adjust_brightness(intensity : float)
signal adjust_contrast(intensity : float)
signal adjust_saturation(intensity : float)

const AUDIO_BUSES : Dictionary = {
	"music_volume"   : "music",
	"sfx_volume"     : "sfx",
	"ui_volume"      : "ui",
	"ambient_volume" : "ambient",
}

func apply_settings(settings_to_apply : GameSettings = settings) -> void:
	for property in settings_to_apply.get_property_list():
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		
		if property.name == "input_bindings":
			continue	# handled separately by InputService
		
		adjust_setting(property.name, settings_to_apply.get(property.name))


func adjust_setting(setting : String, value : Variant) -> void:
	match setting:
		"music_volume", "sfx_volume", "ui_volume", "ambient_volume":
			if value is float or value is int:
				var new_audio_volume : float = value # TODO use hint_range of GameSettings
				
				AudioServer.set_bus_volume_db(
					AudioServer.get_bus_index(AUDIO_BUSES[setting]),
					new_audio_volume
				)
				
				save_setting_value(setting, new_audio_volume)
		
		"brightness", "contrast", "saturation":
			if value is float or value is int:
				var intensity : float = clampf(value, 0., 2.) # TODO use hint_range of GameSettings
				if setting == "brightness":
					adjust_brightness.emit(intensity)
				elif setting == "contrast":
					adjust_contrast.emit(intensity)
				elif setting == "saturation":
					adjust_saturation.emit(intensity)
				
				save_setting_value(setting, intensity)
		
		"screen_resolution":
			if value is String:
				if SettingsManager.settings.RESOLUTIONS.keys().has(value):
					var screen_resolution : Vector2i = SettingsManager.settings.RESOLUTIONS[value]
					# HACK substracting Vector2i(1, 1) so that window does not go fullscreen
					# automatically if window size is set to the screen max resolution (on
					# Linux Mint, maybe other OS too).
					DisplayServer.window_set_size(screen_resolution - Vector2i(1, 1))
					
					@warning_ignore("integer_division")
					var screen_center: Vector2i = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
					var window_size: Vector2i = get_window().get_size_with_decorations()
					@warning_ignore("integer_division")
					DisplayServer.window_set_position(screen_center - window_size / 2)
					get_tree().root.call_deferred("propagate_notification", NOTIFICATION_WM_SIZE_CHANGED)
					
					save_setting_value(setting, value)
		
		"fullscreen":
			if value is bool:
				var is_fullscreen_mode : bool = value
				if is_fullscreen_mode:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
				else:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				
				save_setting_value(setting, is_fullscreen_mode)
		
		"ui_scale":
			if value is float:
				var scale : float = clampf(value, 0.5, 2.) # TODO use hint_range of GameSettings
				get_window().call_deferred("set_content_scale_factor", scale)
				
				save_setting_value(setting, scale)


func save_setting_value(setting : String, value : Variant) -> void:
	if settings.get(setting) != value:
		settings.set(setting, value)
		setting_adjusted.emit(setting, value)
	
	# don't save settings if in expo mode, because we don't need to save settings between games
	if not G.is_expo():
		save_settings()


func get_setting_text(setting : String) -> String:
	var value : Variant = settings.get(setting)
	if value == null:
		push_warning("G.get_setting_text : unknown property '%s'" % setting)
		return ""
	
	match setting:
		"music_volume", "sfx_volume", "ui_volume", "ambient_volume":
			return "%3d" % int(value * (100. / 80.) + 100.) + "%"
		
		"brightness", "contrast", "saturation":
			return "%3d" % int(value * 100.) + "%"
		
		"screen_resolution":
			return value
		
		"fullscreen":
			return "Fullscreen" if value else "Windowed"
		
		"input_bindings":
			push_warning("No Text can be rendered for this setting.")
		
		"ui_scale":
			return str(value)
	
	return ""


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
	#ResourceSaver.save(settings, settings_path)
#
#
##func save_settings() -> void:
	if G.is_expo():
		return
	var cfg := ConfigFile.new()
	for property in settings.get_property_list():
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		if property.name == "input_bindings":
			continue
		cfg.set_value("settings", property.name, settings.get(property.name))
	cfg.save(settings_path)
