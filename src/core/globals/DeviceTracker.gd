extends Node

# Time window (in seconds) to consider an input method "currently in use"
const ACTIVE_WINDOW : float = 0.1

enum InputMethod {
	NONE,
	KEYBOARD_AND_MOUSE,     # Keyboard & mouse (and touch, unless split out)
	GAMEPAD,
	TOUCH,
}

signal method_changed(new_method: InputMethod)
signal gamepad_connected(device_id: int)
signal gamepad_disconnected(device_id: int)

var last_input_method: InputMethod = InputMethod.NONE # sticky; never reset to NONE after first input
var used_keyboard: bool = false
var used_gamepad: bool = false

var _last_keyboard_time: float = -1.0
var _last_gamepad_time: float = -1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	method_changed.connect(show_cursor)


# --- Instant, sticky switching happens on input (no polling needed) ---
func _input(event: InputEvent) -> void:
	# GAMEPAD
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_last_gamepad_time = Time.get_unix_time_from_system()
		used_gamepad = true
		_set_method_if_changed(InputMethod.GAMEPAD)
		return

	# KEYBOARD
	if event is InputEventKey and event.pressed:
		_last_keyboard_time = Time.get_unix_time_from_system()
		used_keyboard = true
		_set_method_if_changed(InputMethod.KEYBOARD_AND_MOUSE)
		return

	# MOUSE (counts as KEYBOARD here)
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		_last_keyboard_time = Time.get_unix_time_from_system()
		used_keyboard = true
		_set_method_if_changed(InputMethod.KEYBOARD_AND_MOUSE)
		return

	# TOUCH (also counted as KEYBOARD unless you split it out)
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_last_keyboard_time = Time.get_unix_time_from_system()
		used_keyboard = true
		_set_method_if_changed(InputMethod.TOUCH)


func _set_method_if_changed(m: InputMethod) -> void:
	if m != last_input_method:
		last_input_method = m
		method_changed.emit(last_input_method)
		#print(last_input_method) # uncomment for debugging

# --- Public API ---

func is_gamepad_active() -> bool:
	var now : float = Time.get_unix_time_from_system()
	return _last_gamepad_time >= 0.0 and (now - _last_gamepad_time) <= ACTIVE_WINDOW


func is_keyboard_active() -> bool:
	var now : float = Time.get_unix_time_from_system()
	return _last_keyboard_time >= 0.0 and (now - _last_keyboard_time) <= ACTIVE_WINDOW


func has_used_both() -> bool:
	return used_keyboard and used_gamepad


func get_current_method() -> InputMethod:
	# Sticky: return last used method; NEVER NONE after first input
	return last_input_method

# Optional helpers
func seconds_since_gamepad() -> float:
	return INF if _last_gamepad_time < 0.0 else (Time.get_unix_time_from_system() - _last_gamepad_time)


func seconds_since_keyboard() -> float:
	return INF if _last_keyboard_time < 0.0 else (Time.get_unix_time_from_system() - _last_keyboard_time)


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		gamepad_connected.emit(device_id)
	else:
		gamepad_disconnected.emit(device_id)


func show_cursor(event_input_method : InputMethod):
	match event_input_method:
		InputMethod.NONE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		InputMethod.KEYBOARD_AND_MOUSE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		InputMethod.GAMEPAD:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

		InputMethod.TOUCH:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
