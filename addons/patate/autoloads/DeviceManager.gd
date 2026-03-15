extends Node

# Time window (in seconds) to consider an input method "currently in use"
const ACTIVE_WINDOW : float = 0.1

enum InputMethod {
	NONE,
	MOUSE,
	KEYBOARD,
	GAMEPAD,
	TOUCH,
}

signal new_input
signal input_prompts_changed
signal method_changed(new_method: InputMethod)
signal gamepad_connected(device_id: int)
signal gamepad_disconnected(device_id: int)

var last_input_method: InputMethod = InputMethod.NONE # sticky; never reset to NONE after first input

var used_mouse: bool = false
var used_keyboard: bool = false
var used_gamepad: bool = false
var used_touch: bool = false

var _last_mouse_time: float = -1.0
var _last_keyboard_time: float = -1.0
var _last_gamepad_time: float = -1.0
var _last_touch_time: float = -1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	method_changed.connect(show_cursor)


# Instant, switching happens on input (no polling needed)
func _input(event: InputEvent) -> void:
	var event_input_method : InputMethod = get_input_method_from_event(event)
	
	match event_input_method:
		InputMethod.GAMEPAD:
			_last_gamepad_time = Time.get_unix_time_from_system()
			used_gamepad = true
			_set_method_if_changed(InputMethod.GAMEPAD)
		
		InputMethod.KEYBOARD:
			_last_keyboard_time = Time.get_unix_time_from_system()
			used_keyboard = true
			_set_method_if_changed(InputMethod.KEYBOARD)
		
		InputMethod.MOUSE:
			_last_mouse_time = Time.get_unix_time_from_system()
			used_mouse = true
			_set_method_if_changed(InputMethod.MOUSE)
	
		InputMethod.TOUCH:
			_last_touch_time = Time.get_unix_time_from_system()
			used_touch = true
			_set_method_if_changed(InputMethod.TOUCH)


func get_input_method_from_event(event: InputEvent) -> InputMethod:
	if event is InputEventKey:
		return InputMethod.KEYBOARD
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return InputMethod.GAMEPAD
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return InputMethod.TOUCH
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		return InputMethod.MOUSE
	return InputMethod.NONE


func _set_method_if_changed(m: InputMethod) -> void:
	new_input.emit()
	input_prompts_changed.emit()
	
	if m != last_input_method:
		last_input_method = m
		method_changed.emit(last_input_method)
		#print(last_input_method) # uncomment for debugging


# Public API
func is_mouse_active() -> bool:
	var now : float = Time.get_unix_time_from_system()
	return _last_mouse_time >= 0.0 and (now - _last_mouse_time) <= ACTIVE_WINDOW


func is_keyboard_active() -> bool:
	var now : float = Time.get_unix_time_from_system()
	return _last_keyboard_time >= 0.0 and (now - _last_keyboard_time) <= ACTIVE_WINDOW


func is_gamepad_active() -> bool:
	var now : float = Time.get_unix_time_from_system()
	return _last_gamepad_time >= 0.0 and (now - _last_gamepad_time) <= ACTIVE_WINDOW


func is_touch_active() -> bool:
	var now : float = Time.get_unix_time_from_system()
	return _last_touch_time >= 0.0 and (now - _last_touch_time) <= ACTIVE_WINDOW


func has_used_both() -> bool:
	return (used_keyboard or used_mouse) and used_gamepad


func get_current_method() -> InputMethod:
	# Sticky: return last used method; NEVER NONE after first input
	return last_input_method


# Optional helpers
func seconds_since_mouse() -> float:
	return INF if _last_mouse_time < 0.0 else (Time.get_unix_time_from_system() - _last_mouse_time)


func seconds_since_gamepad() -> float:
	return INF if _last_gamepad_time < 0.0 else (Time.get_unix_time_from_system() - _last_gamepad_time)


func seconds_since_keyboard() -> float:
	return INF if _last_keyboard_time < 0.0 else (Time.get_unix_time_from_system() - _last_keyboard_time)


func seconds_since_touch() -> float:
	return INF if _last_touch_time < 0.0 else (Time.get_unix_time_from_system() - _last_touch_time)


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	input_prompts_changed.emit()
	
	if connected:
		gamepad_connected.emit(device_id)
	else:
		gamepad_disconnected.emit(device_id)


func show_cursor(event_input_method : InputMethod) -> void:
	match event_input_method:
		InputMethod.NONE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		InputMethod.MOUSE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		InputMethod.KEYBOARD:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		InputMethod.GAMEPAD:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

		InputMethod.TOUCH:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
