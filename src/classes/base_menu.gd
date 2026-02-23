## BaseMenu.gd
## Base class for all menu screens.
##
## Assumes the following Autoloads are registered:
##   - D  (DeviceTracker.gd)
##   - I  (InputService.gd)
##
## What this class handles automatically:
##   - Acquires an I context on open, releases it on close
##   - Grabs / releases UI focus based on the active input device
##   - Routes the "cancel" intent to _on_back_pressed()
##   - Restores focus to the previously focused node when closed
##   - Forwards device changes to _on_device_changed() for icon swapping, etc.
##
## Minimal usage — override only what you need:
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

## Which I context to acquire while this menu is open.
## Override per menu type: a pause menu uses PAUSE, a sub-dialog could use DIALOGUE.
@export var input_context: I.Context = I.Context.MENU

## Whether pressing the "cancel" intent triggers _on_back_pressed().
@export var handle_back_input: bool = true

## If set in the inspector, this node gets focus on open.
## You can also override _get_default_focus() in code instead.
@export var default_focus_node: NodePath = ""


# ─── Private state ────────────────────────────────────────────────────────────

var _context_handle: I.ContextHandle = null
var _previous_focus: Control = null


# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Snapshot whatever had focus before this menu stole the stage
	_previous_focus = get_viewport().gui_get_focus_owner()

	# Register with I — blocks lower-priority contexts (e.g. gameplay)
	_context_handle = I.acquire_context(input_context, self)

	# React to device changes
	D.method_changed.connect(_on_method_changed)

	# Apply current device state immediately (don't wait for the next input event)
	_on_method_changed(D.get_current_method())


func _exit_tree() -> void:
	# Release the input context so lower contexts (gameplay etc.) resume
	I.release_context(_context_handle)
	_context_handle = null

	if D.method_changed.is_connected(_on_method_changed):
		D.method_changed.disconnect(_on_method_changed)


func _process(_delta: float) -> void:
	if not handle_back_input:
		return
	# Use I so "cancel" respects context rules and rebinding
	if I.just_pressed("cancel"):
		_on_back_pressed()


# ─── Public API ───────────────────────────────────────────────────────────────

## Restores previous focus and frees this menu.
## Call this from _on_back_pressed() or a close button.
func close() -> void:
	_restore_previous_focus()
	queue_free()


## Use this instead of close() when you hide/show the menu rather than free it.
## Re-acquires the context and restores focus when shown again.
func reopen() -> void:
	show()
	if _context_handle == null:
		_context_handle = I.acquire_context(input_context, self)
	_on_method_changed(D.get_current_method())


## Hides the menu without freeing it, and releases the input context.
## Pair with reopen().
func suspend() -> void:
	I.release_context(_context_handle)
	_context_handle = null
	_restore_previous_focus()
	hide()


# ─── Overridable hooks ────────────────────────────────────────────────────────

## Return the Control that should receive focus when this menu opens (controller/KB).
## Override this, or set default_focus_node in the inspector.
func _get_default_focus() -> Control:
	if default_focus_node != NodePath(""):
		var node := get_node_or_null(default_focus_node)
		if node is Control:
			return node as Control
	return _find_first_focusable(self)


## Called when the player presses the "cancel" intent.
## Override to define what "back" means: close a dialog, go to previous scene, etc.
## Default is a no-op so menus that don't need back handling are safe to leave empty.
func _on_back_pressed() -> void:
	pass


## Called whenever D detects an input method change.
## Override to swap button prompt icons, toggle touch-specific UI, etc.
func _on_device_changed(_method: D.InputMethod) -> void:
	pass


# ─── Internal ─────────────────────────────────────────────────────────────────

func _on_method_changed(method: D.InputMethod) -> void:
	match method:
		D.InputMethod.GAMEPAD, \
		D.InputMethod.KEYBOARD_AND_MOUSE:
			_try_grab_focus()

		D.InputMethod.TOUCH:
			# No focus ring needed on touch — release if we currently own it
			var focused := get_viewport().gui_get_focus_owner()
			if focused and is_ancestor_of(focused):
				focused.release_focus()

	_on_device_changed(method)


func _try_grab_focus() -> void:
	if not is_inside_tree() or not is_visible_in_tree():
		return
	var target := _get_default_focus()
	if target and target.focus_mode == Control.FOCUS_ALL:
		target.grab_focus()


func _restore_previous_focus() -> void:
	if is_instance_valid(_previous_focus):
		_previous_focus.grab_focus()


func _find_first_focusable(node: Node) -> Control:
	for child in node.get_children():
		if not child.is_inside_tree():
			continue
		if child is Control:
			var c := child as Control
			if c.focus_mode == Control.FOCUS_ALL and c.visible and not c.is_queued_for_deletion():
				return c
		var found := _find_first_focusable(child)
		if found:
			return found
	return null
