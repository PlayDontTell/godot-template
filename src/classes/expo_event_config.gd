@tool
## Configuration resource for a single expo event.
## Create one .tres file per event — duplicate default_settings.tres as a starting point.
## Leave settings null to use project defaults (G.default_settings).
class_name ExpoEventConfig
extends Resource

@export_group("Event Info", "")
## A description only meant to store info about event config, not used by the game itself.
@export_multiline() var event_description : String

## The city the vent is happening in.
@export var city_name : String = "Vernier" :
	set(v):
		city_name = v.validate_filename()
		resource_name = get_event_label()

## The name of the event.
@export var event_name : String = "Vernier Ludique" :
	set(v):
		event_name = v.validate_filename()
		resource_name = get_event_label()

## The year during which the event starts.
@export var event_year : int = Time.get_datetime_dict_from_system().year :
	set(v):
		event_year = v
		resource_name = get_event_label()

## The month during which the event starts.
@export_range(1, 12, 1) var event_month : int = Time.get_datetime_dict_from_system().month :
	set(v):
		event_month = v
		resource_name = get_event_label()

@export_group("Expo Timer", "")
## Timer system used to restart the game after max_idle_time has passed.
## A warning appears after critical_time to inform player that a key must be pressed for the timer to be reset
@export var is_expo_timer_enabled: bool = false

## Seconds before game restarts
@export var max_idle_time: float = 150.0

## Seconds before warning panel appears
@export var critical_time: float = 120.0

@export var core_scene_exceptions: Array[G.CoreScene] = [ ## Core Scenes that do not trigger expo timer
	G.CoreScene.INTRO_CREDITS,
	G.CoreScene.EXPO_INTRO_VIDEO,
	G.CoreScene.LOADING,
] 

@export_group("Game Settings", "")
## Leave null to use G.default_settings unchanged.
## Assign a GameSettings .tres to override any values for this event.
@export var game_settings: GameSettings = null

@export_group("", "")


func _init():
	event_year = Time.get_datetime_dict_from_system().year
	event_month = Time.get_datetime_dict_from_system().month
	resource_name = get_event_label()


func get_event_label() -> String:
	return str(event_year) + "-" + str(event_month).lpad(2, "0") + " " + event_name.replace(" ", "-").validate_filename() + " [" + city_name.validate_filename() + "]"
