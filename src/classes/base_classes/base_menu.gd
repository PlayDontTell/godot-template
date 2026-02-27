## BaseMenu.gd
## Base class for all menu panels.
## Lifecycle is driven entirely by BaseMenuController.
## This class manages only its own context and device icon reactions.
##
## Autoloads required:
##   - I  (InputService.gd)
##   - D  (DeviceTracker.gd)
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


## Context acquired while this panel is active.
## Override in _ready() for non-standard panels (e.g. PAUSE, DIALOGUE).
@export var input_context: I.Context = I.Context.MENU

## Default node to focus when no focus memory exists for this panel.
## If null, falls back to the first focusable child in the tree.
@export var default_focus: Control = null

var _active: bool = false


func _ready() -> void:
	hide()
	D.method_changed.connect(_on_method_changed)


func _exit_tree() -> void:
	if _active:
		I.release_context(self, input_context)
	
	if D.method_changed.is_connected(_on_method_changed):
		D.method_changed.disconnect(_on_method_changed)


# Public API — called by BaseMenuController
func activate() -> void:
	_active = true
	show()
	I.acquire_context(self, input_context)

func deactivate() -> void:
	_active = false
	I.release_context(self, input_context)
	hide()


## Focuses the default node for this panel.
## Called by BaseMenuController when no focus memory exists for this state.
func grab_default_focus() -> void:
	var target := _get_default_focus()
	if is_instance_valid(target) and target.focus_mode == Control.FOCUS_ALL:
		target.grab_focus()


#Overridable hooks

## Called when the active input device changes.
## Override to swap button prompt icons, show/hide touch UI, etc.
func _on_device_changed(_method: D.InputMethod) -> void:
	pass


# Internal
func _on_method_changed(method: D.InputMethod) -> void:
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
