extends CanvasLayer

@onready var critical_panel: Control = %CriticalPanel
@onready var timer_label: Label = %TimerLabel
@onready var press_any_key_label: Label = %PressAnyKeyLabel
@onready var expo_timer_disabled: Control = %ExpoTimerDisabled


@export var EXPO_EVENT_NAME : String = "CITY-EVENT-YEAR"

@export_group("Expo Timer", "")
@export var is_expo_timer_enabled: bool = true

## the duration before restarting the game after no input
@export var EXPO_MAX_IDLE_TIME : float = 150.

## The duration before showing the critical screen asking for any key to be pressed
@export var EXPO_CRITICAL_TIME : float = 120.
@export_group("", "")

func _ready() -> void:
	init()


func _physics_process(_delta: float) -> void:
	var count_down: float = G.EXPO_MAX_IDLE_TIME - G.expo_timer
	
	if count_down <= 9.9:
		timer_label.set_text(
			tr("EXPO_TIMER_WARNING").format({"val": G.round_to_dec(count_down, 1)})
		)
	else:
		timer_label.set_text(
			tr("EXPO_TIMER_WARNING").format({"val": int(count_down)})
		)


func init() -> void:
	G.EXPO_EVENT_NAME = G.sanitize_string(EXPO_EVENT_NAME)
	G.EXPO_MAX_IDLE_TIME = EXPO_MAX_IDLE_TIME
	G.EXPO_CRITICAL_TIME = EXPO_CRITICAL_TIME
	G.is_expo_timer_enabled = is_expo_timer_enabled
	
	if not G.build_profile == G.BuildProfiles.EXPO:
		self.queue_free()
		return
	
	display_critical_panel(false)
	G.expo_timer_critical.connect(display_critical_panel)
	
	display_expo_timer_disabled(not G.is_expo_timer_enabled)
	G.enabled_expo_timer.connect(display_expo_timer_disabled)


var press_any_key_tween: Tween
func tween_press_any_key_label() -> void:
	if press_any_key_tween != null:
		press_any_key_tween.stop()
	press_any_key_tween = create_tween()
	
	press_any_key_tween.tween_property(
		press_any_key_label,
		"modulate:a",
		0.25,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	press_any_key_tween.tween_property(
		press_any_key_label,
		"modulate:a",
		1.,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await press_any_key_tween.finished
	tween_press_any_key_label()


func display_expo_timer_disabled(request_display: bool = not G.is_expo_timer_enabled) -> void:
	expo_timer_disabled.visible = request_display


var critical_panel_tween: Tween
func display_critical_panel(request_display: bool = true) -> void:
	critical_panel.visible = request_display
	
	if request_display:
		tween_press_any_key_label()
		
		if critical_panel_tween != null:
			critical_panel_tween.stop()
		critical_panel_tween = create_tween()
		
		critical_panel_tween.set_parallel(true)
		
		critical_panel_tween.tween_property(
			critical_panel,
			"modulate:a",
			1.,
			2.
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).from(0.)
		
		critical_panel_tween.tween_property(
			critical_panel,
			"scale",
			Vector2.ONE * 2.,
			G.EXPO_MAX_IDLE_TIME - G.EXPO_CRITICAL_TIME + 0.5
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN).from(Vector2.ONE)
		
		critical_panel_tween.tween_property(
			timer_label,
			"modulate",
			Color.TOMATO,
			G.EXPO_MAX_IDLE_TIME - G.EXPO_CRITICAL_TIME + 0.5
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN).from(Color.WHITE)
	
	else:
		if press_any_key_tween != null:
			press_any_key_tween.stop()
