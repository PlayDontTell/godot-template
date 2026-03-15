extends HBoxContainer

signal rebind_requested(action: StringName)
signal reset_requested(action: StringName)

@onready var action_label: Label = %ActionLabel
@onready var binding_btn: Button = %BindingBtn
@onready var reset_btn: Button = $ResetBtn

var action: StringName
var input_methods: Array[DeviceManager.InputMethod]


func _ready() -> void:
	if input_methods.is_empty():
		input_methods.append(DeviceManager.InputMethod.NONE)
	refresh()


func refresh() -> void:
	action_label.text = " ".join(Array(action.split("_")).map(func(w): return w.capitalize()))
	
	var event : InputEvent = _get_current_event()
	
	_update_binding_btn(event)
	
	var default_event : InputEvent = _get_default_event()
	var is_default: bool = (event == null and default_event == null) or \
		(event != null and default_event != null and event.is_match(default_event))
	
	reset_btn.disabled = is_default


func set_listening(is_listening: bool) -> void:
	if is_listening:
		binding_btn.text = "SETTINGS_BINDINGS_PRESS_A_KEY"
		binding_btn.icon = null
		binding_btn.set_theme_type_variation("Button")
	else:
		_update_binding_btn(_get_current_event())
	reset_btn.disabled = is_listening


func _get_current_event() -> InputEvent:
	for method in input_methods:
		var event : InputEvent = InputManager.get_binding_for_device(action, method)
		if event != null:
			return event
	return null


func _get_default_event() -> InputEvent:
	var default_events : Array = ProjectSettings.get_setting("input/" + action, {}).get("events", [])
	for event in default_events:
		if DeviceManager.get_input_method_from_event(event) in input_methods:
			return event
	return null


func _on_rebind_btn_pressed() -> void:
	rebind_requested.emit(action)


func _on_reset_btn_pressed() -> void:
	reset_requested.emit(action)


func _update_binding_btn(event: InputEvent) -> void:
	if event == null:
		binding_btn.icon = null
		binding_btn.text = "SETTINGS_BINDINGS_UNBOUND"
		binding_btn.set_theme_type_variation("Button")
		return
	var device_id : int = -1
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		var joypads : Array = Input.get_connected_joypads()
		if not joypads.is_empty():
			device_id = joypads[0]
	var texture : Texture2D = InputPrompts.get_texture(event, device_id)
	if texture:
		binding_btn.icon = texture
		binding_btn.text = ""
		binding_btn.set_theme_type_variation("ImageButton")
	else:
		binding_btn.icon = null
		binding_btn.text = event.as_text()
		binding_btn.set_theme_type_variation("Button")
