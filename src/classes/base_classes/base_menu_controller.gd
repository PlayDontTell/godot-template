## BaseMenuController.gd
## Base class for menu controllers.
## Owns all navigation, focus memory, and device-aware focus logic.
##
## Usage:
##   extends BaseMenuController
##
##   enum State { MAIN, OPTIONS, CREDITS }
##
##   @onready var panel_main:    BaseMenu = $MainPanel
##   @onready var panel_options: BaseMenu = $OptionsPanel
##   @onready var panel_credits: BaseMenu = $CreditsPanel
##
##   func _ready() -> void:
##       _panels = {
##           State.MAIN:    panel_main,
##           State.OPTIONS: panel_options,
##           State.CREDITS: panel_credits,
##       }
##       _initial_state = State.MAIN
##
##       panel_main.options_requested.connect(go_to.bind(State.OPTIONS))
##       panel_options.back_requested.connect(go_back)
##
##       super._ready()  ## always last

class_name BaseMenuController
extends Control


# To set before super._ready()
## Maps State enum values (int) to BaseMenu nodes.
## Populate in _ready() before calling super._ready().
var _panels: Dictionary = {}

## The state to activate on startup.
## Set in _ready() before calling super._ready().
var _initial_state: int = 0


# Private state
var _current: int = -1
var _history: Array[int] = []

## Stores the last focused Control per state, for restoration on go_back().
var _focus_memory: Dictionary = {}  # int -> Control


func _ready() -> void:
	D.method_changed.connect(_on_method_changed)
	go_to(_initial_state)


func _exit_tree() -> void:
	D.method_changed.disconnect(_on_method_changed)


# Public API

## Navigate to a new state, pushing the current one onto the history stack.
func go_to(state: int) -> void:
	var previous := _current
	_save_focus(previous)
	_current = state
	_panels[_current].activate()
	_grab_focus(_current)
	if previous != -1:
		_panels[previous].deactivate()
		_history.push_back(previous)


## Return to the previous state. Does nothing if history is empty.
func go_back() -> void:
	if _history.is_empty():
		return
	var previous := _current
	_save_focus(previous)
	_current = _history.pop_back()
	_panels[_current].activate()
	_grab_focus(_current)
	_panels[previous].deactivate()


# Internal

func _grab_focus(state: int) -> void:
	if D.last_input_method == D.InputMethod.MOUSE or D.last_input_method == D.InputMethod.TOUCH:
		return
	var remembered: Control = _focus_memory.get(state, null)
	if is_instance_valid(remembered):
		remembered.grab_focus()
	else:
		_panels[state].grab_default_focus()


func _save_focus(state: int) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focused):
		_focus_memory[state] = focused


func _on_method_changed(method: D.InputMethod) -> void:
	match method:
		D.InputMethod.GAMEPAD, D.InputMethod.KEYBOARD:
			if _current != -1:
				_grab_focus(_current)
		D.InputMethod.TOUCH, D.InputMethod.MOUSE:
			var focused := get_viewport().gui_get_focus_owner()
			if is_instance_valid(focused):
				focused.release_focus()
