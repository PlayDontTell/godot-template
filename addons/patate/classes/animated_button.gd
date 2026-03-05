@tool
class_name AnimatedButton
extends Button

@export_group("Focus Animation")
@export var focus_scale : Vector2 = Vector2(1.05, 1.05)
@export var focus_duration : float = 0.08
@export var focus_ease : Tween.EaseType = Tween.EASE_OUT
@export var focus_trans : Tween.TransitionType = Tween.TRANS_BACK

@export_group("Unfocus Animation")
@export var unfocus_scale : Vector2 = Vector2.ONE
@export var unfocus_duration : float = 0.08
@export var unfocus_ease : Tween.EaseType = Tween.EASE_IN_OUT
@export var unfocus_trans : Tween.TransitionType = Tween.TRANS_SINE

var _tween : Tween


func _ready() -> void:
	_center_pivot()
	
	focus_entered.connect(_on_focused)
	focus_exited.connect(_on_unfocused)
	mouse_entered.connect(_on_focused)
	mouse_exited.connect(_on_unfocused)
	resized.connect(_center_pivot)


func _center_pivot() -> void:
	pivot_offset = size / 2.0


func _on_focused() -> void:
	_animate(focus_scale, focus_duration, focus_ease, focus_trans)


func _on_unfocused() -> void:
	_animate(unfocus_scale, unfocus_duration, unfocus_ease, unfocus_trans)


func _animate(target_scale : Vector2, duration : float, ease_type : Tween.EaseType, trans_type : Tween.TransitionType) -> void:
	if is_instance_valid(_tween):
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(self, "scale", target_scale, duration) \
		.set_ease(ease_type) \
		.set_trans(trans_type)
