extends BaseMenu

signal back_requested


func _ready() -> void:
	super._ready()


func _on_back_btn_pressed() -> void:
	back_requested.emit()
