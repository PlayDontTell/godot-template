extends Node


#region INTENTS : semantic input layer
## Maps intent names to their Godot Input Map action names.
## Gameplay code only ever reads intents — never raw action names.
## To support a second keyboard player, define p2_* actions in the Input Map
## and add them here. Two players on one keyboard is the practical limit.

const INTENTS : Dictionary = {
	# Movement — player 1
	"move_up":    ["move_up",    "ui_up"],
	"move_down":  ["move_down",  "ui_down"],
	"move_left":  ["move_left",  "ui_left"],
	"move_right": ["move_right", "ui_right"],
	
	# Movement — player 2 (keyboard split, define in Input Map)
	
	# Actions
	"confirm": ["ui_accept"],
	"cancel":  ["ui_cancel"],
	"pause":   ["pause"],
}


## Returns true if the intent was just pressed this frame.
## Pass device_id for gamepad players (from ID.gamepad_connected signal).
## Keyboard players use default (-1). Touch: use InputDetector directly.
func just_pressed(intent : String, device_id : int = -1) -> bool:
	return _check_intent(intent, device_id, Input.is_action_just_pressed)


## Returns true if the intent is currently held.
func pressed(intent : String, device_id : int = -1) -> bool:
	return _check_intent(intent, device_id, Input.is_action_pressed)


## Returns true if the intent is currently held.
func just_released(intent : String, device_id : int = -1) -> bool:
	return _check_intent(intent, device_id, Input.is_action_just_released)


## Returns a normalized movement vector, filtered by the active context.
## Uses "move_up" as a proxy — if movement intents are blocked, returns ZERO.
## Pass device_id for gamepad — reads left stick directly.
## For touch, handle movement in InputDetector and pass the vector to your node.
func get_move_vector(device_id : int = -1) -> Vector2:
	if not _is_intent_allowed("move_up"):
		return Vector2.ZERO
	
	if device_id >= 0:
		return Vector2(
			Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
		).normalized()
	
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()


func _check_intent(intent : String, device_id : int, check_func : Callable) -> bool:
	assert(INTENTS.has(intent), "InputService : Unknown intent '%s'" % intent)
	
	if not _is_intent_allowed(intent):
		return false
	
	for action : String in INTENTS[intent]:
		if device_id >= 0:
			for event : InputEvent in InputMap.action_get_events(action):
				if (event is InputEventJoypadButton or event is InputEventJoypadMotion) \
				and event.device == device_id \
				and check_func.call(action):
					return true
		else:
			if check_func.call(action):
				return true
	
	return false


func _is_intent_allowed(intent : String) -> bool:
	# TODO : restrict to relevant CoreScenes once gameplay scenes are defined.
	var active := _get_active_context()
	if active == null:
		return true
	var allowed : Array = CONTEXT_RULES[active.context]
	return allowed.is_empty() or intent in allowed

#endregion


#region CONTEXTS : modal input filtering
## A context is acquired by a node to restrict which intents are active.
## Automatically cleaned up when the owner node is freed.
## Priority determines which context wins — only the highest is consulted.
## Lower contexts are not checked — there is no intent passthrough.

enum Context {
	GAMEPLAY,  ## Default — all intents allowed
	PAUSE,     ## Navigation and confirm/cancel only
	DIALOGUE,  ## Confirm only
}

## Which intents are allowed per context. Empty array means allow all.
const CONTEXT_RULES : Dictionary = {
	Context.GAMEPLAY : [],
	Context.PAUSE    : ["confirm", "cancel", "move_up", "move_down"],
	Context.DIALOGUE : ["confirm"],
}


class ContextHandle:
	var context  : Context
	var owner_node    : Node
	var priority : int
	
	func _init(p_context : Context, p_owner : Node, p_priority : int) -> void:
		context  = p_context
		owner_node    = p_owner
		priority = p_priority


var _context_stack : Array[ContextHandle] = []


## Acquires an input context tied to a node's lifetime.
## Returns an existing handle if this owner already holds this context.
func acquire_context(context : Context, owner_node : Node, priority : int = 0) -> ContextHandle:
	assert(is_instance_valid(owner_node), "InputService : Context owner must be a valid Node.")
	
	for existing : ContextHandle in _context_stack:
		if existing.owner_node == owner_node and existing.context == context:
			return existing
	
	var handle := ContextHandle.new(context, owner_node, priority)
	
	var inserted := false
	for i : int in range(_context_stack.size()):
		if priority > _context_stack[i].priority:
			_context_stack.insert(i, handle)
			inserted = true
			break
	if not inserted:
		_context_stack.append(handle)
	
	return handle


## Manually releases a context.
## Optional — the owner being freed cleans it up automatically on the next query.
func release_context(handle : ContextHandle) -> void:
	if handle == null:
		return
	_context_stack.erase(handle)


func _get_active_context() -> ContextHandle:
	for i : int in range(_context_stack.size() - 1, -1, -1):
		if not is_instance_valid(_context_stack[i].owner_node):
			_context_stack.remove_at(i)
	return _context_stack[0] if not _context_stack.is_empty() else null

#endregion


#region REBINDING : runtime key remapping, persisted through G.settings
## Bindings are stored in G.settings.input_bindings as a Dictionary
## mapping action name (String) → Array[InputEvent].
##
## Example usage from a settings UI node:
##
##   # Show current binding in a label:
##   var ev : InputEvent = I.get_binding("move_up")
##   label.text = ev.as_text() if ev else "Unbound"
##
##   # Wait for the player to press a new key, then apply it:
##   func _input(event : InputEvent) -> void:
##       if event is InputEventKey or event is InputEventJoypadButton:
##           I.rebind("move_up", event)
##           set_process_input(false)
##
##   # Reset all bindings to Input Map defaults:
##   I.reset_bindings()


## Rebinds an intent's primary action to a new input event and saves to G.settings.
## Only replaces the first action — secondary fallbacks (ui_up etc.) are preserved.
func rebind(intent : String, new_event : InputEvent) -> void:
	assert(INTENTS.has(intent), "InputService : Unknown intent '%s'" % intent)
	var action : String = INTENTS[intent][0]
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, new_event)
	_save_bindings()


## Returns the current primary InputEvent bound to an intent, or null if unbound.
func get_binding(intent : String) -> InputEvent:
	assert(INTENTS.has(intent), "InputService : Unknown intent '%s'" % intent)
	var events := InputMap.action_get_events(INTENTS[intent][0])
	return events[0] if not events.is_empty() else null


## Restores saved bindings from G.settings into the live InputMap.
## Call from game_manager.gd on startup, after G.load_settings().
func load_bindings() -> void:
	for action : String in G.settings.input_bindings:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
			for event : InputEvent in G.settings.input_bindings[action]:
				InputMap.action_add_event(action, event)


## Clears all custom bindings and resets to Input Map project defaults.
func reset_bindings() -> void:
	InputMap.load_from_project_settings()
	G.settings.input_bindings = {}
	G.save_settings()


func _save_bindings() -> void:
	var bindings : Dictionary = {}
	for intent : String in INTENTS:
		var action : String = INTENTS[intent][0]
		if InputMap.has_action(action):
			bindings[action] = InputMap.action_get_events(action)
	G.settings.input_bindings = bindings
	G.save_settings()

#endregion
