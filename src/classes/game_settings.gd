class_name GameSettings
extends Resource

@export var music_volume	: float			= 0.0	## float : default is 0., muted is -80.
@export var sfx_volume		: float			= 0.0	## float : default is 0., muted is -80.
@export var ui_volume		: float			= 0.0	## float : default is 0., muted is -80.
@export var ambient_volume	: float			= 0.0	## float : default is 0., muted is -80.

@export var brightness		: float			= 1.0	## float : from 0. to 2., default is 1.
@export var contrast		: float			= 1.0	## float : from 0. to 2., default is 1.
@export var saturation		: float			= 1.0	## float : from 0. to 2., default is 1.

@export var fullscreen		: bool			= false	## Bool : fullscreen or windowed mode

@export var input_bindings	: Dictionary	= {}	## Dictionary : action name → Array[InputEvent]
