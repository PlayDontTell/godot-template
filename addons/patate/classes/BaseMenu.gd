## BaseMenu.gd
## Base class for all menu panels.
## Lifecycle is driven entirely by BaseMenuController.
## This class manages only its own context and device icon reactions.
##
## Usage:
##   extends BaseMenu
##
##   signal options_requested
##   signal back_requested
##
##   func _ready() -> void:
##       super._ready()
##       $OptionsBtn.pressed.connect(options_requested.emit)
##       $BackBtn.pressed.connect(back_requested.emit)
##
##   func _on_device_changed(method: D.InputMethod) -> void:
##       $Hints.update_icons(method)

class_name BaseMenu
extends Control

signal activated
signal deactivated

## Context acquired while this panel is active.
## Override in _ready() for non-standard panels (e.g. PAUSE, DIALOGUE).
@export var input_context: InputManager.Context = InputManager.Context.MENU

## Default node to focus when no focus memory exists for this panel.
## If null, falls back to the first focusable child in the tree.
@export var default_focus: Control = null

var _active: bool = false


func _ready() -> void:
	hide()
	DeviceManager.method_changed.connect(_on_method_changed)


# Public API — called by BaseMenuController
func activate() -> void:
	_active = true
	show()
	InputManager.acquire_context(self, input_context)
	activated.emit()

func deactivate() -> void:
	_active = false
	InputManager.release_context(self, input_context)
	hide()
	deactivated.emit()


## Focuses the default node for this panel.
## Called by BaseMenuController when no focus memory exists for this state.
func grab_default_focus() -> void:
	var target := _get_default_focus()
	if is_instance_valid(target) and target.focus_mode == Control.FOCUS_ALL:
		target.grab_focus()


#Overridable hooks

## Called when the active input device changes.
## Override to swap button prompt icons, show/hide touch UI, etc.
func _on_device_changed(_method: DeviceManager.InputMethod) -> void:
	pass


# Internal
func _on_method_changed(method: DeviceManager.InputMethod) -> void:
	if not _active:
		return
	_on_device_changed(method)

func _get_default_focus() -> Control:
	if is_instance_valid(default_focus):
		return default_focus
	for child in find_children("*", "Control", true, false):
		var c := child as Control
		if c.focus_mode == Control.FOCUS_ALL and c.visible:
			return c
	return null
