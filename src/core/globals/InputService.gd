extends Node


#region INTENTS : semantic input layer
## Maps intent names to their Godot Input Map action names.
## Gameplay code only ever reads intents — never raw action names.
## To support a second keyboard player, define p2_* actions in the Input Map
## and add them here. Two players on one keyboard is the practical limit.

const INTENTS : Dictionary = {
	# Dev Actions
	"toggle_Dev_layer" : ["toggle_Dev_layer"],
	"toggle_Expo_timer" : ["toggle_Expo_timer"],
	
	# Movement - player 1
	"move_up":    ["move_up",    "ui_up"],
	"move_down":  ["move_down",  "ui_down"],
	"move_left":  ["move_left",  "ui_left"],
	"move_right": ["move_right", "ui_right"],

	# Movement - player 2 (keyboard split, define in Input Map)

	# Actions
	"confirm":   ["ui_accept"],
	"cancel":    ["ui_cancel"],
	"pause":     ["pause"],
	"prev_tab":  ["ui_page_up"],
	"next_tab":  ["ui_page_down"],
}


## Returns true if the intent was just pressed.
## Polling (no event): call from _process() or _physics_process().
## Event-driven (with event): call from _input(event) — optionally filter by device_id.
func just_pressed(intent: String, event: InputEvent = null, device_id: int = -1) -> bool:
	return _check_intent(intent, Input.is_action_just_pressed, event, device_id)


## Returns true if the intent is currently held.
## Polling (no event): call from _process() or _physics_process().
## Event-driven (with event): call from _input(event) — optionally filter by device_id.
func pressed(intent: String, event: InputEvent = null, device_id: int = -1) -> bool:
	return _check_intent(intent, Input.is_action_pressed, event, device_id)


## Returns true if the intent was just released.
## Polling (no event): call from _process() or _physics_process().
## Event-driven (with event): call from _input(event) — optionally filter by device_id.
func just_released(intent: String, event: InputEvent = null, device_id: int = -1) -> bool:
	return _check_intent(intent, Input.is_action_just_released, event, device_id)


## Returns a normalized movement vector, filtered by the active context.
## Uses "move_up" as a proxy — if movement intents are blocked, returns ZERO.
## Pass device_id for gamepad — reads left stick directly.
## For touch, handle movement in D and pass the vector to your node.
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


func _check_intent(intent: String, check_func: Callable, event: InputEvent, device_id: int) -> bool:
	assert(INTENTS.has(intent), "I : Unknown intent '%s'" % intent)
	if not _is_intent_allowed(intent):
		return false

	for action: String in INTENTS[intent]:
		if event:
			# Event-driven: match this exact event, ignore global Input state.
			# device_id == -1 means accept any device.
			if device_id != -1 and event.device != device_id:
				continue
			# InputEvent has no "just pressed" vs "held" distinction —
			# is_action_pressed() covers both just_pressed() and pressed().
			# is_action_just_released() uses is_action_released() instead.
			var matched: bool = (check_func == Input.is_action_just_released)\
				and event.is_action_released(action)\
				or event.is_action_pressed(action)
			if matched:
				return true
		else:
			# Polling: query global Input state — valid in _process / _physics_process.
			if check_func.call(action):
				return true

	return false


func _is_intent_allowed(intent: String) -> bool:
	if _active_context == null:
		return true
	var allowed: Array = CONTEXT_RULES[_active_context.context]
	return allowed.is_empty() or intent in allowed
#endregion


#region CONTEXTS : modal input filtering
## A context is acquired by a node to restrict which intents are active.
## Automatically cleaned up when the owner node is freed.
## Priority is derived from the Context enum order — higher value wins.
## Only the highest active context is consulted; there is no intent passthrough.

enum Context {
	GAMEPLAY,  ## Default — all intents allowed (empty = unrestricted)
	MENU,      ## Full-screen menus (main menu, options, etc.)
	PAUSE,     ## In-game pause overlay
	DIALOGUE,  ## Confirm and cancel only
	CUTSCENE,  ## Skip only
	EXIT_DIALOG,
}

## Which intents are allowed per context. Empty array means allow all.
const CONTEXT_RULES : Dictionary = {
	Context.GAMEPLAY: [
		"toggle_Dev_layer",
		"toggle_Expo_timer",
	],
	Context.MENU: [
		"toggle_Dev_layer",
		"toggle_Expo_timer",
		
		"confirm",
		"cancel",
		"move_up",
		"move_down",
		"move_left",
		"move_right",
		"prev_tab",
		"next_tab",
	],
	Context.PAUSE: [
		"toggle_Dev_layer",
		"toggle_Expo_timer",
		
		"confirm",
		"cancel",
		"move_up",
		"move_down",
		"move_left",
		"move_right",
		"prev_tab",
		"next_tab",
	],
	Context.DIALOGUE: [
		"toggle_Dev_layer",
		"toggle_Expo_timer",
		
		"confirm",
		"cancel",
	],
	Context.CUTSCENE: [
		"toggle_Dev_layer",
		"toggle_Expo_timer",
		
		"cancel",
	],
	Context.EXIT_DIALOG: [
		"toggle_Dev_layer",
		"toggle_Expo_timer",
		
		"confirm",
		"cancel",
		"move_up",
		"move_down",
		"move_left",
		"move_right",
		"prev_tab",
		"next_tab",
	],
}


class ContextHandle:
	var owner_node : Node
	var context    : int  # stored as int to avoid inner-class enum resolution issues

	func _init(p_owner: Node, p_context: int) -> void:
		owner_node = p_owner
		context    = p_context


var _context_stack: Array[ContextHandle] = []
var _active_context: ContextHandle = null  # cached — invalidated on any stack change


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
	owner_node.tree_exiting.connect(_on_context_owner_exiting.bind(handle), CONNECT_ONE_SHOT)

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
			if owner_node.tree_exiting.is_connected(_on_context_owner_exiting):
				owner_node.tree_exiting.disconnect(_on_context_owner_exiting)
			_context_stack.remove_at(i)
			break

	_active_context = _context_stack[0] if not _context_stack.is_empty() else null


func _on_context_owner_exiting(handle: ContextHandle) -> void:
	_context_stack.erase(handle)
	_active_context = _context_stack[0] if not _context_stack.is_empty() else null


func _get_active_context() -> ContextHandle:
	return _active_context  # no allocation, no filtering

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
	assert(INTENTS.has(intent), "I : Unknown intent '%s'" % intent)
	var action : String = INTENTS[intent][0]
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, new_event)
	_save_bindings()


## Returns the current primary InputEvent bound to an intent, or null if unbound.
func get_binding(intent : String) -> InputEvent:
	assert(INTENTS.has(intent), "I : Unknown intent '%s'" % intent)
	var events := InputMap.action_get_events(INTENTS[intent][0])
	return events[0] if not events.is_empty() else null


## Restores saved bindings from G.settings into the live InputMap.
## Call from game_manager.gd on startup, after G.load_settings().
func load_bindings() -> void:
	for entry : InputBindingEntry in G.settings.input_bindings:
		if InputMap.has_action(entry.action) and entry.event != null:
			InputMap.action_erase_events(entry.action)
			InputMap.action_add_event(entry.action, entry.event)


## Clears all custom bindings and resets to Input Map project defaults.
func reset_bindings() -> void:
	InputMap.load_from_project_settings()
	G.settings.input_bindings = []
	G.save_settings()


func _save_bindings() -> void:
	var bindings : Array[InputBindingEntry] = []
	for intent : String in INTENTS:
		var action : String = INTENTS[intent][0]
		if InputMap.has_action(action):
			var events := InputMap.action_get_events(action)
			if not events.is_empty():
				var entry := InputBindingEntry.new()
				entry.action = action
				entry.event = events[0]
				bindings.append(entry)
	G.settings.input_bindings = bindings
	G.save_settings()

#endregion
