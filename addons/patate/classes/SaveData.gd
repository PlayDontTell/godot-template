## only export variables will be serialized (and so saved)
@tool
@icon("res://assets/art/ui/temp/game-icons/PNG/White/2x/save.png")
class_name SaveData
extends Resource

@export_storage var _is_empty: bool = true
@export_storage var game_name : String = ""

## Save slot index
@export_storage var save_slot: int = 0

# The image associated with this save (a screenshot thanks to SaveManager._capture_screenshot() )
@export_storage var save_image : Image = null

## Game Version of this save save_data
@export_storage var game_version: String

## Creation date of this save save_data
@export_storage var creation_date: String

## Last date this save save_data was played (to order saves in time)
@export_storage var date_saved: String

## Total amount of time (in seconds) spent in the game
@export_storage var time_since_start: float = 0.0

## Total amount of time (in seconds) spent in the game UNPAUSED
@export_storage var time_played: float = 0.0

enum SaveType {
	AUTO_SAVE,
	MANUAL_SAVE,
	QUICK_SAVE,
}
@export_storage var save_type: SaveType = SaveType.AUTO_SAVE	

## The list of events logged
@export_storage var event_log: Array = []

## Save slot name
@export var save_slot_name: String = "default"

## Save Name presented to the player
@export var save_name: String = "default"


func _init() -> void:
	game_version = ProjectSettings.get_setting("application/config/version")
	creation_date = Time.get_datetime_string_from_system()
	date_saved = Time.get_datetime_string_from_system()
	
	## Guarding against access to the G autoload, because this is a @tool script running in the editor.
	if not Engine.is_editor_hint() and G.config.DEFAULT_SAVE_IMAGE:
		save_image = G.config.DEFAULT_SAVE_IMAGE.get_image()


func get_save_type_name() -> String:
	return SaveType.keys()[save_type]
