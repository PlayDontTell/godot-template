## All player-configurable settings with their default values.
## Add a new setting here — nothing else needs updating for save/load to work.
## Side effects (audio bus, display mode, etc.) are handled in adjust_setting().

@icon("res://assets/art/ui/temp/game-icons/PNG/White/2x/gear.png")
class_name GameSettings
extends Resource


@export_group("General Settings", "")
## The game language (interface, dialogue, texts, etc.) - everything that is localized
@export var lang: String = LocaleManager.get_OS_default_locale()

@export_group("Audio Volumes", "")
## dB : 0 = full, -80 = muted
@export_range(-80.0, 8.0, 8.) var music_volume: float = 0.0
@export_range(-80.0, 8.0, 8.) var sfx_volume: float = 0.0
@export_range(-80.0, 8.0, 8.) var ui_volume: float = 0.0
@export_range(-80.0, 8.0, 8.) var ambient_volume: float = 0.0

@export_group("Render Settings", "")
## 0.0 – 2.0, default 1.0
@export_range(0.75, 1.25, 0.05) var contrast: float = 1.0
@export_range(0.75, 1.25, 0.05) var brightness: float = 1.0
@export_range(0.5, 1.5, 0.1) var saturation: float = 1.0

@export_group("Window Settings", "")
## Fullscreen/Windowed mode switch
@export var fullscreen: bool = false

## Screen Resolutions Options
const RESOLUTIONS : Dictionary = {
	# 16:9
	"1024x600 (16:9)"   : Vector2i(1024, 600),
	"1280x720 (16:9)"   : Vector2i(1280, 720),
	"1366x768 (16:9)"   : Vector2i(1366, 768),
	"1536x864 (16:9)"   : Vector2i(1536, 864),
	"1600x900 (16:9)"   : Vector2i(1600, 900),
	"1920x1080 (16:9)"  : Vector2i(1920, 1080),
	"2560x1440 (16:9)"  : Vector2i(2560, 1440),
	"3840x2160 (16:9)"  : Vector2i(3840, 2160),
	# 21:9
	"2560x1080 (21:9)"  : Vector2i(2560, 1080),
	# 16:10
	"1280x800 (16:10)"  : Vector2i(1280, 800),
	"1440x900 (16:10)"  : Vector2i(1440, 900),
	"1920x1200 (16:10)" : Vector2i(1920, 1200),
	"2560x1600 (16:10)" : Vector2i(2560, 1600),
	# 4:3
	"640x480 (4:3)"     : Vector2i(640,  480),
	"800x600 (4:3)"     : Vector2i(800,  600),
	"1024x768 (4:3)"    : Vector2i(1024, 768),
}

@export var screen_resolution: String = get_default_resolution()


## Interface/UI scale : 0.5 - 2.0, default 1.0
@export_range(0.75, 1.5, 0.25) var ui_scale: float = 1.

@export_group("Input Bindings", "")
## action name → Array[InputEvent]. Empty = use Input Map defaults.
@export var input_bindings: Array[InputBindingEntry] = []

@export_group("", "")


func _validate_property(property: Dictionary) -> void:
	if property.name == "screen_resolution":
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(RESOLUTIONS.keys())


func get_default_resolution() -> String:
	var screen_size : Vector2i = DisplayServer.screen_get_size()
	var best_key : String = RESOLUTIONS.keys()[0]
	var best_area : int = 0
	
	for key in RESOLUTIONS:
		var res : Vector2i = RESOLUTIONS[key]
		if res.x <= screen_size.x and res.y <= screen_size.y:
			var area : int = res.x * res.y
			if area > best_area:
				best_area = area
				best_key = key
	
	return best_key


const AUDIO_BUSES : Dictionary = {
	"music_volume"   : "music",
	"sfx_volume"     : "sfx",
	"ui_volume"      : "ui",
	"ambient_volume" : "ambient",
}

func adjust_setting(setting : String, value : Variant) -> Variant:
	match setting:
		"lang":
			if value is String:
				var new_locale: String = value
				if new_locale in LocaleManager.get_available_locales():
					
					LocaleManager.set_locale(new_locale)
					
					return new_locale
		
		"music_volume", "sfx_volume", "ui_volume", "ambient_volume":
			if value is float or value is int:
				var hint_range: Dictionary = Utils.get_hint_range_info(self, setting)
				var new_audio_volume : float = clampf(value, hint_range.min_value, hint_range.max_value)
				
				AudioServer.set_bus_volume_db(
					AudioServer.get_bus_index(AUDIO_BUSES[setting]),
					new_audio_volume
				)
				
				return new_audio_volume
		
		"brightness", "contrast", "saturation":
			if value is float or value is int:
				
				var hint_range: Dictionary = Utils.get_hint_range_info(self, setting)
				var intensity : float = clampf(value, hint_range.min_value, hint_range.max_value)
				match setting:
					"brightness": SettingsManager.adjust_brightness.emit(intensity)
					"contrast": SettingsManager.adjust_contrast.emit(intensity)
					"saturation": SettingsManager.adjust_saturation.emit(intensity)
				
				return intensity
		
		"screen_resolution":
			if value is String:
				if RESOLUTIONS.keys().has(value):
					var screen_resolution : Vector2i = RESOLUTIONS[value]
					# HACK subtracting Vector2i(1, 1) so that window does not go fullscreen
					# automatically if window size is set to the screen max resolution (on
					# Linux Mint, maybe other OS too).
					if OS.get_name() == "Linux":
						DisplayServer.window_set_size(screen_resolution - Vector2i(1, 1))
					else:
						DisplayServer.window_set_size(screen_resolution)
					
					@warning_ignore("integer_division")
					var screen_center: Vector2i = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
					var window_size: Vector2i = DisplayServer.window_get_size_with_decorations()
					
					@warning_ignore("integer_division")
					DisplayServer.window_set_position(screen_center - window_size / 2)
					var tree: MainLoop = Engine.get_main_loop() as SceneTree
					tree.root.call_deferred("propagate_notification", Node.NOTIFICATION_WM_SIZE_CHANGED)
					
					return value
		
		"fullscreen":
			if value is bool:
				var is_fullscreen_mode : bool = value
				if is_fullscreen_mode:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
				else:
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				
				return is_fullscreen_mode
		
		"ui_scale":
			if value is float:
				var hint_range: Dictionary = Utils.get_hint_range_info(self, setting)
				var scale : float = clampf(value, hint_range.min_value, hint_range.max_value)
				var tree: MainLoop = Engine.get_main_loop() as SceneTree
				tree.root.call_deferred("set_content_scale_factor", scale)
				
				return scale
	
	return null


func get_setting_text(setting : String) -> String:
	var value : Variant = get(setting)
	if value == null:
		push_warning("GameSettings.get_setting_text : unknown property '%s'" % setting)
		return ""
	
	match setting:
		"music_volume", "sfx_volume", "ui_volume", "ambient_volume":
			# -80dB is 0%, 0dB is 100% (8dB step represents 10%)
			return "%3d" % int(value * (100. / 80.) + 100.) + "%"	
		
		"brightness", "contrast", "saturation":
			return "%3d" % int(value * 100.) + "%"
		
		"screen_resolution":
			return value
		
		"fullscreen":
			return "FULLSCREEN" if value else "WINDOWED"
		
		"input_bindings":
			push_warning("No Text can be rendered for this setting.")
			return ""
		
		"ui_scale":
			return str(value)
		
		"lang":
			return value
	
	return ""
