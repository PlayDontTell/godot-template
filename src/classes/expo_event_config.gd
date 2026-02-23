@tool
## Configuration resource for a single expo event.
## Create one .tres file per event — duplicate default_settings.tres as a starting point.
## Leave settings null to use project defaults (G.default_settings).
class_name ExpoEventConfig
extends Resource

@export_group("Event Info", "")
@export var city_name : String = "Vernier" :
	set(v):
		city_name = v
		resource_name = get_event_label()

@export var event_name : String = "Vernier-Ludique" :
	set(v):
		event_name = v
		resource_name = get_event_label()

@export var event_year : int = Time.get_datetime_dict_from_system().year :
	set(v):
		event_year = v
		resource_name = get_event_label()

## Timer system used to restart the game after max_idle_time has passed.
## A warning appears after critical_time to inform player that a key must be pressed for the timer to be reset
@export_group("Expo Timer", "")
@export var is_expo_timer_enabled: bool = false
@export var max_idle_time: float = 150.0	## Seconds before game restarts
@export var critical_time: float = 120.0	## Seconds before warning panel appears
@export var core_scene_exceptions: Array[G.CoreScene] = [ ## Core Scenes that do not trigger expo timer
	G.CoreScene.INTRO_CREDITS,
	G.CoreScene.EXPO_INTRO_VIDEO,
	G.CoreScene.LOADING,
] 

@export_group("Game Settings", "")
## Leave null to use G.default_settings unchanged.
## Assign a GameSettings .tres to override any values for this event.
@export var game_settings			: GameSettings	= null

@export_group("", "")


func _init():
	event_year = Time.get_datetime_dict_from_system().year
	resource_name = get_event_label()


func get_event_label() -> String:
	return str(event_year) + "_" + event_name + "_" + city_name
