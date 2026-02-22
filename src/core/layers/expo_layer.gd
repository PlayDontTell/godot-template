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

var expo_timer : float = 0.
var is_expo_timer_critical: bool = false
var is_booth_session_active: bool = false


func _ready() -> void:
	init()


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_Expo_timer"):
		set_expo_timer_enabled(not is_expo_timer_enabled)
	
	if     (event is InputEventJoypadButton
		or  event is InputEventJoypadMotion
		or (event is InputEventKey and event.pressed)
		or  event is InputEventMouseButton
		or  event is InputEventMouseMotion
		or  event is InputEventScreenTouch
		or  event is InputEventScreenDrag):
		
		reset_expo_timer()
		set_booth_active()


func _physics_process(delta: float) -> void:
	var count_down: float = EXPO_MAX_IDLE_TIME - expo_timer
	
	if count_down <= 9.9:
		timer_label.set_text(
			tr("EXPO_TIMER_WARNING").format({"val": G.round_to_dec(count_down, 1)})
		)
	else:
		timer_label.set_text(
			tr("EXPO_TIMER_WARNING").format({"val": int(count_down)})
		)
	
	if G.build_profile == G.BuildProfile.EXPO and is_expo_timer_enabled:
		if is_booth_session_active:
			expo_timer += delta
			
			if expo_timer > EXPO_MAX_IDLE_TIME:
				G.request_game_restart.emit()
				reset_expo_timer()
				set_booth_active(false)
			
			elif expo_timer > EXPO_CRITICAL_TIME and not is_expo_timer_critical:
				is_expo_timer_critical = true
				display_critical_panel(true)


func init() -> void:
	EXPO_EVENT_NAME = G.sanitize_string(EXPO_EVENT_NAME)
	
	if not G.build_profile == G.BuildProfile.EXPO:
		self.queue_free()
		return
	
	display_critical_panel(false)
	display_expo_timer_disabled(not is_expo_timer_enabled)


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


func display_expo_timer_disabled(request_display: bool = not is_expo_timer_enabled) -> void:
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
			EXPO_MAX_IDLE_TIME - EXPO_CRITICAL_TIME + 0.5
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN).from(Vector2.ONE)
		
		critical_panel_tween.tween_property(
			timer_label,
			"modulate",
			Color.TOMATO,
			EXPO_MAX_IDLE_TIME - EXPO_CRITICAL_TIME + 0.5
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN).from(Color.WHITE)
	
	else:
		if press_any_key_tween != null:
			press_any_key_tween.stop()


func reset_expo_timer() -> void:
	expo_timer = 0.
	if is_expo_timer_critical:
		is_expo_timer_critical = false
		display_critical_panel(false)


func set_booth_active(request_active: bool = true) -> void:
	is_booth_session_active = request_active and is_expo_timer_enabled


func set_expo_timer_enabled(request_enabled: bool = true) -> void:
	is_expo_timer_enabled = request_enabled
	display_expo_timer_disabled()
	
	if not request_enabled:
		reset_expo_timer()
