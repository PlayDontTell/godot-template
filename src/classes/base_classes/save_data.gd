@tool
@icon("res://assets/art/ui/temp/game-icons/PNG/White/2x/save.png")
class_name SaveData
extends Resource

## Save slot index
@export_range(1, 3, 1) var save_slot: int = 0

## Save Name presented to the player
@export var save_name: String = "default"

## Game Version of this save save_data
@export var game_version: String = ProjectSettings.get_setting("application/config/version")

## Creation date of this save save_data
@export var creation_date: String = Time.get_datetime_string_from_system()

## Last date this save save_data was played (to order saves in time)
@export var date_saved: String = Time.get_datetime_string_from_system()

## Total amount of time (in seconds) spent in the game
@export var time_since_start: float = 0.0

## Total amount of time (in seconds) spent in the game UNPAUSED
@export var time_played: float = 0.0

enum SaveType {
	AUTO_SAVE,
	MANUAL_SAVE,
	QUICK_SAVE,
}
const SAVE_TYPE_NAMES = ["Auto Save", "Manual Save", "Quick Save"]
@export_enum("Auto Save", "Manual Save", "Quick Save") var save_type: int = 0

## The list of events logged
@export var event_log: Array = []


func _init() -> void:
	game_version = ProjectSettings.get_setting("application/config/version")
	creation_date = Time.get_datetime_string_from_system()
	date_saved = Time.get_datetime_string_from_system()


func get_save_type_name() -> String:
	return SAVE_TYPE_NAMES[save_type]
