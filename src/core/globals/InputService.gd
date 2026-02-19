extends Node


#region INTENTS : semantic input layer
## Maps intent names to their Input Map actions.
## Contexts filter intents — gameplay code only ever reads intents.

const INTENTS : Dictionary = {
	# Movement
	"move_up":    ["move_up",    "ui_up"],
	"move_down":  ["move_down",  "ui_down"],
	"move_left":  ["move_left",  "ui_left"],
	"move_right": ["move_right", "ui_right"],
	
	# Actions
	"confirm":    ["ui_accept"],
	"cancel":     ["ui_cancel"],
	"pause":      ["pause"],
}

## Returns true if the intent was just pressed this frame.
func just_pressed(intent : String) -> bool:
	assert(INTENTS.has(intent), "InputService : Unknown intent '%s'" % intent)
	
	if not _is_intent_allowed(intent):
		return false
	
	for action : String in INTENTS[intent]:
		if Input.is_action_just_pressed(action):
			return true
	
	return false


## Returns true if the intent is currently held.
func pressed(intent : String) -> bool:
	assert(INTENTS.has(intent), "InputService : Unknown intent '%s'" % intent)
	
	if not _is_intent_allowed(intent):
		return false
	
	for action : String in INTENTS[intent]:
		if Input.is_action_pressed(action):
			return true
	
	return false


## Returns a normalized movement vector from movement intents.
func get_move_vector() -> Vector2:
	if not _is_input_globally_allowed():
		return Vector2.ZERO
	
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()

#endregion


#region CONTEXTS : modal input filtering
## A context is acquired by a node to restrict what intents are available.
## Contexts are automatically cleaned up when their owner is freed.
## Priority determines which context is active when multiple are held.

enum Context {
	GAMEPLAY,  ## Default — all intents allowed
	PAUSE,     ## Only ui_confirm / ui_cancel
	DIALOGUE,  ## Only confirm
	DEBUG,     ## All intents allowed (bypasses everything)
}

## Defines which intent groups are allowed per context.
## Intents not listed in a context's allowed set are blocked.
## Empty allows all
const CONTEXT_RULES : Dictionary = {
	Context.GAMEPLAY:  [],              # empty = allow all
	Context.PAUSE:     ["confirm", "cancel", "move_up", "move_down"],
	Context.DIALOGUE:  ["confirm"],
	Context.DEBUG:     [],              # empty = allow all
}


class ContextHandle:
	var context  : Context
	var owner    : Node
	var priority : int
	
	func _init(p_context : Context, p_owner : Node, p_priority : int) -> void:
		context  = p_context
		owner    = p_owner
		priority = p_priority


var _context_stack : Array[ContextHandle] = []


## Acquires an input context tied to a node's lifetime.
## If the owner already holds this context, returns the existing handle.
func acquire_context(context : Context, owner : Node, priority : int = 0) -> ContextHandle:
	assert(is_instance_valid(owner), "InputService : Context owner must be a valid Node.")
	
	for existing : ContextHandle in _context_stack:
		if existing.owner == owner and existing.context == context:
			return existing
	
	var handle := ContextHandle.new(context, owner, priority)
	
	# Insert at the right position to keep stack sorted by priority (highest first)
	var inserted := false
	for i : int in range(_context_stack.size()):
		if priority > _context_stack[i].priority:
			_context_stack.insert(i, handle)
			inserted = true
			break
	if not inserted:
		_context_stack.append(handle)
	
	return handle


## Manually releases a context. Not required if the owner will be freed naturally.
func release_context(handle : ContextHandle) -> void:
	if handle == null:
		return
	_context_stack.erase(handle)

#endregion


#region PRIVATE HELPERS

func _is_input_globally_allowed() -> bool:
	# Macro-level gate : only allow input when a game scene is active.
	return G.core_scene == G.CoreScenes.GAME


func _is_intent_allowed(intent : String) -> bool:
	if not _is_input_globally_allowed():
		return false
	
	var active := _get_active_context()
	if active == null:
		return true
	
	# DEBUG context bypasses all rules
	if active.context == Context.DEBUG:
		return true
	
	var allowed_intents : Array = CONTEXT_RULES[active.context]
	
	# Empty array means "allow all"
	if allowed_intents.is_empty():
		return true
	
	return intent in allowed_intents


func _get_active_context() -> ContextHandle:
	_cleanup_dead_contexts()
	return _context_stack[0] if not _context_stack.is_empty() else null


func _cleanup_dead_contexts() -> void:
	for i : int in range(_context_stack.size() - 1, -1, -1):
		if not is_instance_valid(_context_stack[i].owner):
			_context_stack.remove_at(i)

#endregion
