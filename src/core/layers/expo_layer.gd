extends CanvasLayer

@onready var critical_panel: Control = %CriticalPanel
@onready var timer_label: Label = %TimerLabel
@onready var press_any_key_label: Label = %PressAnyKeyLabel
@onready var expo_timer_disabled: Control = %ExpoTimerDisabled

@export_global_dir var archive_save_files : String = "user://archive_saves/"
@export var expo_events : Array[ExpoEventConfig] = []
@export var active_event_index : int = 0
@onready var current_event : ExpoEventConfig = null

var expo_timer : float = 0.
var is_expo_timer_critical: bool = false
var is_booth_session_active: bool = false


func _ready() -> void:
	set_physics_process(false)
	init()


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_Expo_timer"):
		set_expo_timer_enabled(not current_event.is_expo_timer_enabled)
	
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
	var count_down: float = current_event.max_idle_time - expo_timer
	
	if count_down <= 9.9:
		timer_label.set_text(
			tr("EXPO_TIMER_WARNING").format({"val": G.round_to_dec(count_down, 1)})
		)
	else:
		timer_label.set_text(
			tr("EXPO_TIMER_WARNING").format({"val": int(count_down)})
		)
	
	var is_current_core_scene_an_exception : bool = G.core_scene in current_event.core_scene_exceptions
	if current_event.is_expo_timer_enabled and not is_current_core_scene_an_exception:
		if is_booth_session_active:
			expo_timer += delta
			
			if expo_timer > current_event.max_idle_time:
				G.request_game_restart.emit()
				reset_expo_timer()
				set_booth_active(false)
			
			elif expo_timer > current_event.critical_time and not is_expo_timer_critical:
				is_expo_timer_critical = true
				display_critical_panel(true)


func init() -> void:
	if expo_events.is_empty():
		expo_events.append(ExpoEventConfig.new())
	
	if not G.is_expo():
		self.queue_free()
		return
	
	current_event = expo_events[active_event_index] if not expo_events.is_empty() else null
	
	if not current_event:
		push_error("ExpoLayer: no ExpoEventConfig assigned.")
		self.queue_free()
		return
	
	set_physics_process(true)
	
	current_event.city_name = G.sanitize_string(current_event.city_name)
	current_event.event_name = G.sanitize_string(current_event.event_name)
	if current_event.game_settings:
		G.apply_settings(current_event.game_settings)
	
	display_critical_panel(false)
	display_expo_timer_disabled(not current_event.is_expo_timer_enabled)


func get_archive_folder() -> String:
	return current_event.get_event_label()


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


func display_expo_timer_disabled(request_display: bool) -> void:
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
			current_event.max_idle_time - current_event.critical_time + 0.5
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN).from(Vector2.ONE)
		
		critical_panel_tween.tween_property(
			timer_label,
			"modulate",
			Color.TOMATO,
			current_event.max_idle_time - current_event.critical_time + 0.5
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
	is_booth_session_active = request_active and current_event.is_expo_timer_enabled


func set_expo_timer_enabled(request_enabled: bool = true) -> void:
	current_event.is_expo_timer_enabled = request_enabled
	display_expo_timer_disabled(not current_event.is_expo_timer_enabled)
	
	if not request_enabled:
		reset_expo_timer()
