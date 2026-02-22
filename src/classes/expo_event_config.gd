## Configuration resource for a single expo event.
## Create one .tres file per event — duplicate default_settings.tres as a starting point.
## Leave settings null to use project defaults (G.default_settings).
class_name ExpoEventConfig
extends Resource

@export_group("Event Info", "")
@export var city_name				: String		= "Geneva"
@export var event_name				: String		= "Vernier Ludique"
@export var event_year				: int			= Time.get_datetime_dict_from_system().year

## Timer system used to restart the game after max_idle_time has passed.
## A warning appears after critical_time to inform player that a key must be pressed for the timer to be reset
@export_group("Expo Timer", "")
@export var is_expo_timer_enabled	: bool			= true
@export var max_idle_time			: float			= 4.0	## Seconds before game restarts
@export var critical_time			: float			= 1.0	## Seconds before warning panel appears

@export_group("Game Settings", "")
## Leave null to use G.default_settings unchanged.
## Assign a GameSettings .tres to override any values for this event.
@export var game_settings			: GameSettings	= null

@export_group("", "")
