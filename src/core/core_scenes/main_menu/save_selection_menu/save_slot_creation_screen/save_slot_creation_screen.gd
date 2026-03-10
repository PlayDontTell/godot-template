extends BaseMenu

signal back_requested


func _on_back_btn_pressed() -> void:
	back_requested.emit()
