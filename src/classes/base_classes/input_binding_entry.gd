# input_binding_entry.gd
class_name InputBindingEntry
extends Resource

## The Input Map action name this binding overrides (e.g. "move_up").
@export var action : String = ""
## The input event to bind to this action.
@export var event : InputEvent = null
