extends Node


#region ACTIONS : semantic input layer
# Core actions, never edited by game devs
const _DEV_ACTIONS: Array = [
	"toggle_Dev_layer",
	"toggle_Expo_timer",
]

## Register additional allowed actions for an existing context.
func extend_context(context: Context, additional_actions: Array) -> void:
	if CONTEXT_RULES.has(context):
		for action in additional_actions:
			if action not in CONTEXT_RULES[context]:
				CONTEXT_RULES[context].append(action)


## Returns true if the action was just pressed this frame.
## Polling — call from _process() or _physics_process().
## Pass device_id for local multiplayer gamepad filtering.
func just_pressed(action: StringName, device_id: int = -1) -> bool:
	return _check_action(action, null, device_id, Input.is_action_just_pressed, false)


## Returns true if the action was just pressed, matching the given InputEvent.
## Event-driven — call from _input(event).
## Pass device_id to restrict to a specific gamepad.
func just_pressed_event(action: StringName, event: InputEvent, device_id: int = -1) -> bool:
	return _check_action(action, event, device_id, Input.is_action_just_pressed, false)


## Returns true if the action is currently held.
## Polling — call from _process() or _physics_process().
## Pass device_id for local multiplayer gamepad filtering.
func pressed(action: StringName, device_id: int = -1) -> bool:
	return _check_action(action, null, device_id, Input.is_action_pressed, false)


## Returns true if the action is currently held, matching the given InputEvent.
## Event-driven — call from _input(event).
## Pass device_id to restrict to a specific gamepad.
func pressed_event(action: StringName, event: InputEvent, device_id: int = -1) -> bool:
	return _check_action(action, event, device_id, Input.is_action_pressed, false)


## Returns true if the action was just released this frame.
## Polling — call from _process() or _physics_process().
## Pass device_id for local multiplayer gamepad filtering.
func just_released(action: StringName, device_id: int = -1) -> bool:
	return _check_action(action, null, device_id, Input.is_action_just_released, true)


## Returns true if the action was just released, matching the given InputEvent.
## Event-driven — call from _input(event).
## Pass device_id to restrict to a specific gamepad.
func just_released_event(action: StringName, event: InputEvent, device_id: int = -1) -> bool:
	return _check_action(action, event, device_id, Input.is_action_just_released, true)



func _check_action(action: StringName, event: InputEvent, device_id: int, polling_func: Callable, event_released: bool) -> bool:
	if not _is_action_allowed(action):
		return false
	var translated : StringName = translate_action(action, device_id)
	if event:
		if event_released:
			return event.is_action_released(translated)
		return event.is_action_pressed(translated)
	return polling_func.call(translated)


## Returns a normalized movement vector, filtered by the active context.
## Uses "move_up" as a context proxy — returns ZERO if movement is blocked or intents are unregistered.
## Pass device_id for gamepad — reads left stick directly.
## For touch, handle movement in D and pass the vector to your node.
func get_move_vector(device_id : int = -1) -> Vector2:
	if not _is_action_allowed("move_up"):
		return Vector2.ZERO
	
	if device_id >= 0:
		return Vector2(
			Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
		).normalized()
	
	if not (InputMap.has_action("move_up") and InputMap.has_action("move_down")
		and InputMap.has_action("move_left") and InputMap.has_action("move_right")):
		return Vector2.ZERO
	
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up"),
	).normalized()



## Translates a base action to a device-specific variant for local multiplayer.
## Lazily creates "action_0", "action_1" etc. in the InputMap on first call.
## Keyboard events are shared — only gamepad events are device-specific.
func translate_action(action: StringName, device_id: int) -> StringName:
	if device_id < 0:
		return action
	
	var device_action : StringName = StringName(action + "_" + str(device_id))
	
	if not InputMap.has_action(device_action):
		InputMap.add_action(device_action)
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				var new_event := event.duplicate()
				new_event.device = device_id
				InputMap.action_add_event(device_action, new_event)
	
	return device_action



func _is_action_allowed(action: String) -> bool:
	if action in _DEV_ACTIONS:
		return true
	
	if _active_context == null:
		return true
	var allowed: Array = CONTEXT_RULES[_active_context.context]
	return allowed.is_empty() or action in allowed
#endregion


#region CONTEXTS : modal input filtering
## A context is acquired by a node to restrict which actions are active.
## Automatically cleaned up when the owner node is freed.
## Priority is derived from the Context enum order — higher value wins.
## Only the highest active context is consulted; there is no action passthrough.

enum Context {
	GAMEPLAY,  ## Default — all actions allowed (empty = unrestricted)
	MENU,      ## Full-screen menus (main menu, options, etc.)
	PAUSE,     ## In-game pause overlay
	DIALOGUE,  ## Confirm and cancel only
	CUTSCENE,  ## Skip only
	EXIT_DIALOG,
}

## Which actions are allowed per context. Empty array means allow all.
var CONTEXT_RULES : Dictionary = {
	Context.MENU: [
		"ui_accept",
		"ui_cancel",
		"ui_up",
		"ui_down",
		"ui_left",
		"ui_right",
		"ui_page_up",
		"ui_page_down"
	],
	Context.PAUSE: [
		"ui_accept",
		"ui_cancel",
		"ui_up",
		"ui_down",
		"ui_left",
		"ui_right",
		"ui_page_up",
		"ui_page_down"
	],
	Context.DIALOGUE: [
		"ui_accept",
		"ui_cancel"
	],
	Context.CUTSCENE: [
		"ui_cancel"
	],
	Context.EXIT_DIALOG: [
		"ui_accept",
		"ui_cancel",
		"ui_up",
		"ui_down",
		"ui_left",
		"ui_right",
		"ui_page_up",
		"ui_page_down"
	],
	Context.GAMEPLAY: [
		
	],
}


class ContextHandle:
	var owner_node : Node
	var context    : int  # stored as int to avoid inner-class enum resolution issues
	var auto_release_callable: Callable
	
	func _init(p_owner: Node, p_context: int) -> void:
		owner_node = p_owner
		context    = p_context


var _context_stack: Array[ContextHandle] = []
var _active_context: ContextHandle = null  # cached — invalidated on any stack change


func get_context_actions(context : Context, rebindable_only : bool = false) -> Array:
	var actions : Array
	
	actions = CONTEXT_RULES[context].duplicate()
	
	if rebindable_only:
		for action in actions.duplicate():
			if action in _DEV_ACTIONS:
				actions.erase(action)
	
	return actions


## Acquires an input context tied to a node's lifetime.
## Returns early if this owner already holds this context.
## Priority is implicit: higher Context enum value always wins.
func acquire_context(owner_node: Node, context: Context) -> void:
	assert(is_instance_valid(owner_node), "I : Context owner must be a valid Node.")
	
	for existing: ContextHandle in _context_stack:
		if existing.owner_node == owner_node and existing.context == context:
			return  # already acquired
	
	var handle := ContextHandle.new(owner_node, context)
	
	# Auto-release when the owner leaves the tree — no manual cleanup needed.
	handle.auto_release_callable = _on_context_owner_exiting.bind(handle)
	owner_node.tree_exiting.connect(handle.auto_release_callable, CONNECT_ONE_SHOT)

	# Insert sorted: highest Context value first (highest priority at front).
	var inserted := false
	for i in range(_context_stack.size()):
		if context > _context_stack[i].context:
			_context_stack.insert(i, handle)
			inserted = true
			break
	if not inserted:
		_context_stack.append(handle)
	
	_active_context = _context_stack[0] if not _context_stack.is_empty() else null


## Manually releases a context. Optional — freed nodes are cleaned up automatically.
func release_context(owner_node: Node, context: Context) -> void:
	for i in range(_context_stack.size() - 1, -1, -1):
		var handle: ContextHandle = _context_stack[i]
		if handle.owner_node == owner_node and handle.context == context:
			# Disconnect auto-release if manually releasing early.
			if owner_node.tree_exiting.is_connected(handle.auto_release_callable):
				owner_node.tree_exiting.disconnect(handle.auto_release_callable)
			_context_stack.remove_at(i)
			break
	
	_active_context = _context_stack[0] if not _context_stack.is_empty() else null


func _on_context_owner_exiting(handle: ContextHandle) -> void:
	_context_stack.erase(handle)
	_active_context = _context_stack[0] if not _context_stack.is_empty() else null


func _get_active_context() -> ContextHandle:
	return _active_context  # no allocation, no filtering

#endregion


#region REBINDING : runtime key remapping, persisted through SettingsManager.settings
## Bindings are stored in G.config.BIN_DIR + "input_bindings.tres" as a InputBindingsData
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


## Rebinds an action
## Only replaces the first action — secondary fallbacks (ui_up etc.) are preserved.
func rebind(action: StringName, new_event: InputEvent) -> bool:
	assert(InputMap.has_action(action), "InputManager: Unknown action '%s'" % action)
	
	var conflicts: Array[String] = get_conflicting_action(new_event)
	if not (conflicts.is_empty() or conflicts == [String(action)]):
		if G.config.block_duplicate_bindings:
			push_warning("InputManager: '%s' already bound to '%s', blocked." % [new_event.as_text(), conflicts])
			return false
		else:
			push_warning("InputManager: '%s' already bound to '%s', but duplicates are allowed." % [new_event.as_text(), conflicts])
	
	var new_method : DeviceManager.InputMethod = DeviceManager.get_input_method_from_event(new_event)
	for existing_event in InputMap.action_get_events(action):
		if DeviceManager.get_input_method_from_event(existing_event) == new_method:
			InputMap.action_erase_event(action, existing_event)
	
	InputMap.action_add_event(action, new_event)
	_save_bindings()
	return true

## Removes the binding for a specific device type from an action.                                                                                                                                                                           
func unbind(action: StringName, method: DeviceManager.InputMethod) -> void:
	assert(InputMap.has_action(action), "InputManager: Unknown action '%s'" % action)                                                                                                                                                       
	for event in InputMap.action_get_events(action).duplicate():
		if DeviceManager.get_input_method_from_event(event) == method:
			InputMap.action_erase_event(action, event)
	_save_bindings()


## Find what actions already use an InputEvent as a trigger (conflicts)
## Each action has events (InputEvents)
func get_conflicting_action(new_event: InputEvent) -> Array[String]:
	var conflicting_actions: Array[String] = []
	var checked: Array[String] = []  # avoid duplicate checks
	
	for actions in CONTEXT_RULES.values():
		for action: String in actions:
			if action in checked:
				continue
			checked.append(action)
			for existing_event in InputMap.action_get_events(action):
				if existing_event.is_match(new_event):
					conflicting_actions.append(action)
					break
	
	return conflicting_actions


## Returns the current primary InputEvent bound to an action, or null if unbound.
func get_binding(action: StringName) -> InputEvent:
	assert(InputMap.has_action(action), "InputManager: Unknown action '%s'" % action)
	var events := InputMap.action_get_events(action)
	return events[0] if not events.is_empty() else null


## Returns the InputEvent bound to an action for a specific device type, or null if unbound.
func get_binding_for_device(action: StringName, method: DeviceManager.InputMethod) -> InputEvent:
	assert(InputMap.has_action(action), "InputManager: Unknown action '%s'" % action)
	for event in InputMap.action_get_events(action):
		if DeviceManager.get_input_method_from_event(event) == method:
			return event
	return null


## Restores saved bindings from G.config.BIN_DIR + "input_bindings.tres" into the live InputMap.
## Call from game_manager.gd on startup, after SettingsManager.load_settings().
func load_bindings() -> void:
	var path : String = G.config.BIN_DIR + "input_bindings.tres"
	if not ResourceLoader.exists(path):
		return
	
	var data : InputBindingsData = ResourceLoader.load(path) as InputBindingsData
	
	if not data:
		return
	
	for entry in data.entries:                                                                                                                                                                                                                  
		if InputMap.has_action(entry.action) and entry.event != null:                                                                                                                                                                           
			var method := DeviceManager.get_input_method_from_event(entry.event)
			for existing in InputMap.action_get_events(entry.action).duplicate():
				if DeviceManager.get_input_method_from_event(existing) == method:
					InputMap.action_erase_event(entry.action, existing)
			InputMap.action_add_event(entry.action, entry.event)


## Clears all custom bindings and resets to Input Map project defaults.
func reset_bindings() -> void:
	InputMap.load_from_project_settings()
	var data : InputBindingsData = InputBindingsData.new()
	ResourceSaver.save(data, G.config.BIN_DIR + "input_bindings.tres")


func _save_bindings() -> void:
	var bindings: Array[InputBindingEntry] = []
	var saved: Array[String] = []  # avoid duplicates
	
	for actions in CONTEXT_RULES.values():
		for action: String in actions:
			if action in saved or not InputMap.has_action(action):
				continue
			saved.append(action)
			var events : Array = InputMap.action_get_events(action)
			
			if not events.is_empty():
				for event in events:
					var entry : InputBindingEntry = InputBindingEntry.new()
					entry.action = action
					entry.event = event
					bindings.append(entry)
	
	var data : InputBindingsData = InputBindingsData.new()
	data.entries = bindings
	ResourceSaver.save(data, G.config.BIN_DIR + "input_bindings.tres")
	
	DeviceManager.input_prompts_changed.emit()     

#endregion
