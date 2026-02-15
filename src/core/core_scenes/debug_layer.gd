extends CanvasLayer

@onready var collapse_expand_btn: Button = %CollapseExpandBtn

@onready var debug_container: VBoxContainer = %DebugContainer

@onready var fps_value: Label = %FPSValue
@onready var core_scene_value: Label = %CoreSceneValue
@onready var locale_value: Label = %LocaleValue
@onready var pause_requests_value: Label = %PauseRequestsValue
@onready var pause_value: Label = %PauseValue
@onready var version_value: Label = %VersionValue
@onready var time_since_start_value: Label = %TimeSinceStartValue
@onready var time_played_value: Label = %TimePlayedValue
@onready var process_delta_value: Label = %ProcessDeltaValue
@onready var physics_delta_value: Label = %PhysicsDeltaValue

@onready var memory_usage_value: Label = %MemoryUsageValue
@onready var node_count_value: Label = %NodeCountValue

@onready var time_scale_value: Label = %TimeScaleValue
@onready var time_scale_slider: HSlider = %TimeScaleSlider

@onready var pause_resume_btn: Button = %PauseResumeBtn

@export var info_refresh_period : float = 1.
var info_refresh_timer : Timer


func _ready() -> void:
	G.new_core_scene_loaded.connect(set_core_scene_label)
	G.locale_changed.connect(set_locale_label)
	G.pause_state_changed.connect(set_pause_label)
	
	init()


func _process(delta: float) -> void:
	if G.is_debug():
		set_fps_label()
		set_time_since_start_label()
		set_time_played_label()
	
	set_process_delta_label(delta)


func _physics_process(delta: float) -> void:
	set_physics_delta_label(delta)


func init() -> void:
	self.visible = G.is_debug()
	
	set_core_scene_label()
	set_locale_label()
	set_version_label()
	set_pause_label()
	
	_on_pause_resume_btn_toggled(pause_resume_btn.button_pressed)
	_on_collapse_expand_btn_toggled(collapse_expand_btn.button_pressed)
	
	refresh_stats()
	
	if info_refresh_timer == null:
		info_refresh_timer = Timer.new()
		info_refresh_timer.autostart = true
		info_refresh_timer.wait_time = info_refresh_period
		info_refresh_timer.ignore_time_scale = true
		info_refresh_timer.one_shot = false
		info_refresh_timer.timeout.connect(refresh_stats)
		self.add_child(info_refresh_timer)


func set_fps_label(fps : float = Engine.get_frames_per_second()) -> void:
	var label_text : String = str(fps)
	fps_value.set_text(label_text)


func set_core_scene_label(core_scene : G.CoreScenes = G.core_scene) -> void:
	var label_text : String = str(G.CoreScenes.find_key(core_scene))
	core_scene_value.set_text(label_text)


func set_locale_label(locale : String = G.current_locale) -> void:
	var label_text : String = str(locale)
	locale_value.set_text(label_text)


func set_version_label(version : String = ProjectSettings.get_setting("application/config/version")) -> void:
	var label_text : String = str(version)
	version_value.set_text(label_text)


func set_time_since_start_label() -> void:
	if G.data.has("meta"):
		var time_since_start : float = G.round_to_dec(G.data.meta.time_since_start, 2)
		var label_text : String = str(time_since_start)
		time_since_start_value.set_text(label_text)


func set_time_played_label() -> void:
	if G.data.has("meta"):
		var time_played : float = G.round_to_dec(G.data.meta.time_played, 2)
		var label_text : String = str(time_played)
		time_played_value.set_text(label_text)


func set_process_delta_label(delta : float = 99.) -> void:
	var rounded_delta : float = G.round_to_dec(delta * 1000., 2)
	var label_text : String = str(rounded_delta) + " ms"
	process_delta_value.set_text(label_text)


func set_physics_delta_label(delta : float = 99.) -> void:
	var rounded_delta : float = G.round_to_dec(delta * 1000., 2)
	var label_text : String = str(rounded_delta) + " ms"
	physics_delta_value.set_text(label_text)


func set_pause_label(pause_state : bool = get_tree().paused) -> void:
	if G.data.has("meta"):
		var label_text : String = str(pause_state)
		pause_value.set_text(label_text)
		pause_requests_value.set_text(str(G.request_pause_objects.size()))
		
		if pause_state:
			pause_value.modulate = Color.GREEN
			pause_requests_value.modulate = Color.GREEN
		else:
			pause_value.modulate = Color.TOMATO
			pause_requests_value.modulate = Color.TOMATO


func _on_pause_resume_btn_toggled(toggled_on: bool) -> void:
	if toggled_on:
		pause_resume_btn.icon = preload("uid://dwi38q3spugmy")
		pause_resume_btn.text = "Pause"
		G.request_pause(pause_resume_btn, false)
	else:
		pause_resume_btn.icon = preload("uid://vrok71kbmo3u")
		pause_resume_btn.text = "Resume"
		G.request_pause(pause_resume_btn, true)


func _on_collapse_expand_btn_toggled(toggled_on: bool) -> void:
	if toggled_on:
		collapse_expand_btn.icon = preload("uid://csfspd6lrbrl8")
		#collapse_expand_btn.text = "Collapse"
		#collapse_expand_btn.expand_icon = true
		debug_container.visible = true
	else:
		collapse_expand_btn.icon = preload("uid://d1cqgv5o7t1if")
		#collapse_expand_btn.text = "Expand"
		#collapse_expand_btn.expand_icon = false
		debug_container.visible = false
	


func _on_time_scale_slider_value_changed(value: float) -> void:
	var label_text : String = str(value)
	time_scale_value.set_text(label_text)
	Engine.time_scale = value



func refresh_stats() -> void:
	memory_usage_value.set_text(
		"%.2f MB" % (OS.get_static_memory_usage() / 1048576.0)
	)
	node_count_value.set_text(
		str(get_tree().get_node_count())
	)
