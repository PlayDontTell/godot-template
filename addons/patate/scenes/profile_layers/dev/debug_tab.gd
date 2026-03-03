extends Button


@export var info_panel : MarginContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.toggled.connect(enable_tab)


func toggle(request_toggle_state : bool = true) -> void:
	enable_tab(request_toggle_state)
	self.button_pressed = request_toggle_state


func enable_tab(toggled_on: bool) -> void:
	info_panel.visible = toggled_on
