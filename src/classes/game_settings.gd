## All player-configurable settings with their default values.
## Add a new setting here — nothing else needs updating for save/load to work.
## Side effects (audio bus, display mode, etc.) are handled in G.adjust_setting().
class_name GameSettings
extends Resource

@export var music_volume	: float		= 0.0	## dB : 0 = full, -80 = muted
@export var sfx_volume		: float		= 0.0	## dB : 0 = full, -80 = muted
@export var ui_volume		: float		= 0.0	## dB : 0 = full, -80 = muted
@export var ambient_volume	: float		= 0.0	## dB : 0 = full, -80 = muted

@export var brightness		: float		= 1.0	## 0.0 – 2.0, default 1.0
@export var contrast		: float		= 1.0	## 0.0 – 2.0, default 1.0
@export var saturation		: float		= 1.0	## 0.0 – 2.0, default 1.0

@export var fullscreen		: bool		= false

@export var input_bindings	: Dictionary = {}	## action name → Array[InputEvent]. Empty = use Input Map defaults.
