extends VBoxContainer

const BINDING_ROW = preload("uid://46qikc2s4pbi")

@export var input_methods : Array[DeviceManager.InputMethod]

var _listening_row: Control = null
var _listening_action: StringName = ""


func _ready() -> void:
	set_process_input(false)
	update()
	
	DeviceManager.input_prompts_changed.connect(_refresh_all)


func _input(event: InputEvent) -> void:
	if not _listening_row:
		return
	
	get_viewport().set_input_as_handled()
	
	if not event.is_pressed():
		return
	
	if not DeviceManager.get_input_method_from_event(event) in input_methods:
		_cancel_listening()
		return
	
	
	var new_method : DeviceManager.InputMethod = DeviceManager.get_input_method_from_event(event)
	for method in input_methods:
		if method != new_method:
			InputManager.unbind(_listening_action, method)
	
	InputManager.rebind(_listening_action, event)
	_cancel_listening()


func _refresh_all() -> void:
	for binding_row in self.get_children():
		binding_row.refresh()


func _cancel_listening() -> void:
	_listening_row.refresh()
	_listening_row = null
	_listening_action = ""
	set_process_input(false)


func update() -> void:
	for binding_row in self.get_children():
		binding_row.queue_free()
	
	var actions : Array = InputManager.get_context_actions(
		InputManager.Context.GAMEPLAY, true
	)
	
	for action in actions:
		var new_binding_row : Control = BINDING_ROW.instantiate()
		new_binding_row.action = action
		new_binding_row.input_methods = input_methods.duplicate()
		new_binding_row.rebind_requested.connect(_on_rebind_requested)
		new_binding_row.reset_requested.connect(_on_reset_requested)

		self.add_child(new_binding_row)


func _on_rebind_requested(action: StringName) -> void:
	if _listening_row:
		_listening_row.set_listening(false)
	
	for binding_row in self.get_children():
		if binding_row.action == action:
			_listening_row = binding_row
			_listening_action = action
			_listening_row.set_listening(true)
			set_process_input(true)


func _on_reset_requested(action: StringName) -> void:
	var _default_event : InputEvent
	
	for binding_row in self.get_children():
		if binding_row.action == action:
			_default_event = binding_row._get_default_event()
			if _default_event:
				InputManager.rebind(action, _default_event)
			else:
				for input_method in input_methods:
					InputManager.unbind(action, input_method)
			binding_row.refresh()
			break
