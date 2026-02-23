## BaseMenu.gd
## Base class for all menu screens.
##
## Autoloads required:
##   - I  (InputService.gd)
##   - D  (DeviceTracker.gd)
##
## What this handles automatically:
##   - Acquires an I context on open, releases it on close
##   - Grabs / releases UI focus based on the active input device
##   - Routes the "cancel" intent to _on_back_pressed()
##   - Restores focus to the previously focused node when closed
##   - Forwards device changes to _on_device_changed()
##
## Minimal usage:
##
##   extends BaseMenu
##
##   func _get_default_focus() -> Control:
##       return $VBox/PlayButton
##
##   func _on_back_pressed() -> void:
##       close()
##
##   func _on_device_changed(method: D.InputMethod) -> void:
##       $Hints.update_icons(method)

class_name BaseMenu
extends Control


# ─── Exports ─────────────────────────────────────────────────────────────────

## Context acquired while this menu is open. Set in _ready() by subclass,
## or leave as MENU for standard full-screen menus.
@export var input_context: I.Context = I.Context.MENU

## Node to focus when this menu opens. If null, falls back to _get_default_focus().
@export var default_focus: Control = null


# ─── Private state ────────────────────────────────────────────────────────────

var _previous_focus: Control = null


# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	I.acquire_context(self, input_context)
	D.method_changed.connect(_on_method_changed)
	_on_method_changed(D.get_current_method())


func _exit_tree() -> void:
	I.release_context(self, input_context)
	D.method_changed.disconnect(_on_method_changed)


func _input(event: InputEvent) -> void:
	if I.is_action_pressed_in_event(event, "cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


# ─── Public API ───────────────────────────────────────────────────────────────

## Restores previous focus and frees this menu.
func close() -> void:
	_restore_previous_focus()
	queue_free()


## Suspends this menu without freeing it. Pair with reopen().
func suspend() -> void:
	I.release_context(self, input_context)
	D.method_changed.disconnect(_on_method_changed)
	_restore_previous_focus()
	hide()


## Resumes a suspended menu.
func reopen() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	show()
	I.acquire_context(self, input_context)
	D.method_changed.connect(_on_method_changed)
	_on_method_changed(D.get_current_method())


# ─── Overridable hooks ────────────────────────────────────────────────────────

## Return the Control that should receive focus on open.
## Only override if the default_focus export is not sufficient.
func _get_default_focus() -> Control:
	if is_instance_valid(default_focus):
		return default_focus
	return _find_first_focusable(self)


## Called when "cancel" is pressed. Define what back means for this menu.
func _on_back_pressed() -> void:
	pass


## Called when the active input device changes.
## Override to swap button prompt icons, toggle touch UI, etc.
func _on_device_changed(_method: D.InputMethod) -> void:
	pass


# ─── Internal ─────────────────────────────────────────────────────────────────

func _on_method_changed(method: D.InputMethod) -> void:
	match method:
		D.InputMethod.GAMEPAD, D.InputMethod.KEYBOARD_AND_MOUSE:
			_try_grab_focus()
		D.InputMethod.TOUCH:
			var focused := get_viewport().gui_get_focus_owner()
			if focused and is_ancestor_of(focused):
				focused.release_focus()
	_on_device_changed(method)


func _try_grab_focus() -> void:
	if not is_visible_in_tree():
		return
	
	# Only grab if nothing in this menu already has focus
	var current := get_viewport().gui_get_focus_owner()
	if current and is_ancestor_of(current):
		return
	
	var target := _get_default_focus()
	if target and target.focus_mode == Control.FOCUS_ALL:
		target.grab_focus()


func _restore_previous_focus() -> void:
	if is_instance_valid(_previous_focus):
		_previous_focus.grab_focus()


func _find_first_focusable(node: Node) -> Control:
	for child in node.find_children("*", "Control", true, false):
		var c := child as Control
		if c.focus_mode == Control.FOCUS_ALL and c.visible:
			return c
	return null
