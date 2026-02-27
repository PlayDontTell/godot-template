## All player-configurable settings with their default values.
## Add a new setting here — nothing else needs updating for save/load to work.
## Side effects (audio bus, display mode, etc.) are handled in G.adjust_setting().

@icon("res://assets/art/ui/temp/game-icons/PNG/White/2x/gear.png")
class_name GameSettings
extends Resource


@export_group("Audio Volumes", "")
## dB : 0 = full, -80 = muted
@export_range(-80.0, 8.0, 8.) var music_volume: float = 0.0
@export_range(-80.0, 8.0, 8.) var sfx_volume: float = 0.0
@export_range(-80.0, 8.0, 8.) var ui_volume: float = 0.0
@export_range(-80.0, 8.0, 8.) var ambient_volume: float = 0.0

@export_group("Render Settings", "")
## 0.0 – 2.0, default 1.0
@export_range(0.0, 2.0, 0.2) var brightness: float = 1.0
@export_range(0.0, 2.0, 0.2) var contrast: float = 1.0
@export_range(0.0, 2.0, 0.2) var saturation: float = 1.0

@export_group("Window Settings", "")
## Fullscreen/Windowed mode switch
@export var fullscreen: bool = false

## Screen Resolutions Options
const RESOLUTIONS : Dictionary = {
	# 4:3
	"640x480 (4:3)"     : Vector2i(640,  480),
	"800x600 (4:3)"     : Vector2i(800,  600),
	"1024x768 (4:3)"    : Vector2i(1024, 768),
	# 16:10
	"1280x800 (16:10)"  : Vector2i(1280, 800),
	"1440x900 (16:10)"  : Vector2i(1440, 900),
	"1920x1200 (16:10)" : Vector2i(1920, 1200),
	"2560x1600 (16:10)" : Vector2i(2560, 1600),
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
}

@export_enum(
	"640x480 (4:3)",
	"800x600 (4:3)",
	"1024x768 (4:3)",
	
	"1280x800 (16:10)",
	"1440x900 (16:10)",
	"1920x1200 (16:10)",
	"2560x1600 (16:10)",
	
	"1024x600 (16:9)",
	"1280x720 (16:9)",
	"1366x768 (16:9)",
	"1536x864 (16:9)",
	"1600x900 (16:9)",
	"1920x1080 (16:9)",
	"2560x1440 (16:9)",
	"3840x2160 (16:9)",
	
	"2560x1080 (21:9)"
) var screen_resolution : String = get_default_resolution()

## Interface/UI scale : 0.5 - 2.0, default 1.0
@export_range(0.5, 2.0, 0.5) var ui_scale: float = 1.

@export_group("Input Bindings", "")
## action name → Array[InputEvent]. Empty = use Input Map defaults.
@export var input_bindings: Dictionary = {}

@export_group("", "")


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
