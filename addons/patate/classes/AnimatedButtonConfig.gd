class_name AnimatedButtonConfig
extends Resource

@export_group("Focus Animation")
@export var focus_scale : Vector2 = Vector2(1.08, 1.08)
@export var focus_duration : float = 0.1
@export var focus_ease : Tween.EaseType = Tween.EASE_OUT
@export var focus_trans : Tween.TransitionType = Tween.TRANS_BACK

@export_group("Unfocus Animation")
@export var unfocus_scale : Vector2 = Vector2.ONE
@export var unfocus_duration : float = 0.1
@export var unfocus_ease : Tween.EaseType = Tween.EASE_IN_OUT
@export var unfocus_trans : Tween.TransitionType = Tween.TRANS_SINE
