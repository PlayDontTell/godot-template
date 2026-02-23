## All player-configurable settings with their default values.
## Add a new setting here — nothing else needs updating for save/load to work.
## Side effects (audio bus, display mode, etc.) are handled in G.adjust_setting().
class_name GameSettings
extends Resource

@export_group("Audio Volumes", "")
## dB : 0 = full, -80 = muted
@export var music_volume: float = 0.0

## dB : 0 = full, -80 = muted
@export var sfx_volume: float = 0.0

## dB : 0 = full, -80 = muted
@export var ui_volume: float = 0.0

## dB : 0 = full, -80 = muted
@export var ambient_volume: float = 0.0

@export_group("Render Settings", "")
## 0.0 – 2.0, default 1.0
@export var brightness: float = 1.0

## 0.0 – 2.0, default 1.0
@export var contrast: float = 1.0

## 0.0 – 2.0, default 1.0
@export var saturation: float = 1.0

@export_group("Window Settings", "")
## Fullscreen/Windowed mode switch
@export var fullscreen: bool = false

@export_group("Input Bindings", "")
## action name → Array[InputEvent]. Empty = use Input Map defaults.
@export var input_bindings: Dictionary = {}

@export_group("", "")
