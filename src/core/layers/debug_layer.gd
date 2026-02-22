## Can be used in DEV and EXPO build profiles
extends CanvasLayer

@onready var placement: Control = %Placement
@onready var debug_panel: MarginContainer = %DebugPanel
@onready var frame_btns: MarginContainer = %FrameBtns
@onready var debug_window: VBoxContainer = %DebugWindow

@onready var tab_1: Button = %Tab1
@onready var tab_2: Button = %Tab2
@onready var tab_3: Button = %Tab3
@onready var tab_4: Button = %Tab4
@onready var tab_5: Button = %Tab5
@onready var tab_6: Button = %Tab6

@onready var collapse_expand_btn: Button = %CollapseExpandBtn
@onready var position_btns: GridContainer = %PositionBtns

@onready var debug_container: VBoxContainer = %DebugContainer

@onready var fps_value: Label = %FPSValue
@onready var time_since_start_value: Label = %TimeSinceStartValue
@onready var time_played_value: Label = %TimePlayedValue
@onready var process_delta_value: Label = %ProcessDeltaValue
@onready var physics_delta_value: Label = %PhysicsDeltaValue
@onready var time_scale_value: Label = %TimeScaleValue
@onready var time_scale_slider: HSlider = %TimeScaleSlider

@onready var memory_usage_value: Label = %MemoryUsageValue
@onready var node_count_value: Label = %NodeCountValue
@onready var tween_count_value: Label = %TweenCountValue

@onready var machine_value: Label = %MachineValue
@onready var os_value: Label = %OSValue
@onready var os_version_value: Label = %OSVersionValue
@onready var window_scale_value: Label = %WindowScaleValue
@onready var window_count_value: Label = %WindowCountValue
@onready var window_size_value: Label = %WindowSizeValue
@onready var visible_viewport_size_value: Label = %VisibleViewportSizeValue
@onready var viewport_size_value: Label = %ViewportSizeValue

@onready var build_profile_value: Label = %BuildProfileValue
@onready var version_value: Label = %VersionValue
@onready var locale_value: Label = %LocaleValue
@onready var core_scene_value: Label = %CoreSceneValue

@onready var mouse_position_value: Label = %MousePositionValue

@onready var pause_requests_value: Label = %PauseRequestsValue
@onready var pause_value: Label = %PauseValue
@onready var pause_resume_btn: Button = %PauseResumeBtn


@export var expanded_on_start: bool = true

enum StartPosition {TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT}
@export var position_on_start: StartPosition

@export var info_refresh_period : float = 2.

enum Tab {TIME=1, COSTS=2, MACHINE=4, GAME_STATE=8, INPUT_OUTPUT=16, PAUSE=32}
@export_flags("Time:1", "Costs:2", "Machine:4", "Game State:8", "Input/Output:16", "Pause:32") var active_tabs_on_start = 63


var info_refresh_timer : Timer


func _ready() -> void:
	G.new_core_scene_loaded.connect(set_core_scene_label)
	G.locale_changed.connect(set_locale_label)
	G.pause_state_changed.connect(set_pause_label)
	
	init()


func _process(delta: float) -> void:
	set_fps_label()
	set_time_since_start_label()
	set_time_played_label()
	
	set_process_delta_label(delta)


func _physics_process(delta: float) -> void:
	set_physics_delta_label(delta)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseMotion:
		set_mouse_position_label(event.position)
	
	if Input.is_action_just_pressed("toggle_Dev_layer"):
		display_debug_layer()


func init() -> void:
	if not G.build_profile in [
		G.BuildProfile.DEV,
		G.BuildProfile.EXPO,
	]:
		self.queue_free()
		return
	
	self.visible = G.is_debug()
	
	set_core_scene_label()
	set_locale_label()
	set_version_label()
	set_build_profile_label()
	set_pause_label()
	
	collapse_expand_btn.button_pressed = expanded_on_start
	_on_collapse_expand_btn_toggled(collapse_expand_btn.button_pressed)
	_on_pause_resume_btn_toggled(pause_resume_btn.button_pressed)
	_on_time_scale_slider_value_changed()
	
	refresh_stats()
	
	if info_refresh_timer == null:
		info_refresh_timer = Timer.new()
		info_refresh_timer.autostart = true
		info_refresh_timer.wait_time = info_refresh_period
		info_refresh_timer.ignore_time_scale = true
		info_refresh_timer.one_shot = false
		info_refresh_timer.timeout.connect(refresh_stats)
		self.add_child(info_refresh_timer)
	
	await get_tree().process_frame
	match position_on_start:
		StartPosition.TOP_LEFT:
			_on_nw_pressed()
		StartPosition.TOP_RIGHT:
			_on_ne_pressed()
		StartPosition.BOTTOM_LEFT:
			_on_sw_pressed()
		StartPosition.BOTTOM_RIGHT:
			_on_se_pressed()
	
	machine_value.set_text(
		str(OS.get_model_name())
	)
	os_value.set_text(
		str(OS.get_name())
	)
	os_version_value.set_text(
		str(OS.get_version())
	)
	
	tab_1.toggle(bool(active_tabs_on_start & Tab.TIME))
	tab_2.toggle(bool(active_tabs_on_start & Tab.COSTS))
	tab_3.toggle(bool(active_tabs_on_start & Tab.MACHINE))
	tab_4.toggle(bool(active_tabs_on_start & Tab.GAME_STATE))
	tab_5.toggle(bool(active_tabs_on_start & Tab.INPUT_OUTPUT))
	tab_6.toggle(bool(active_tabs_on_start & Tab.PAUSE))


func display_debug_layer() -> void:
	self.visible = not self.visible


func set_fps_label(fps : float = Engine.get_frames_per_second()) -> void:
	var label_text : String = str(fps)
	fps_value.set_text(label_text)


func set_core_scene_label(core_scene : G.CoreScene = G.core_scene) -> void:
	var label_text : String = str(G.CoreScene.find_key(core_scene))
	core_scene_value.set_text(label_text)


func set_locale_label(locale : String = G.current_locale) -> void:
	var label_text : String = str(locale)
	locale_value.set_text(label_text)


func set_version_label(version : String = ProjectSettings.get_setting("application/config/version")) -> void:
	var label_text : String = str(version)
	version_value.set_text(label_text)


func set_time_since_start_label() -> void:
	if G.data.has("meta"):
		var time_since_start : float = G.round_to_dec(G.data.meta.time_since_start, 1)
		var label_text : String = str(time_since_start) + " s"
		time_since_start_value.set_text(label_text)


func set_time_played_label() -> void:
	if G.data.has("meta"):
		var time_played : float = G.round_to_dec(G.data.meta.time_played, 1)
		var label_text : String = str(time_played) + " s"
		time_played_value.set_text(label_text)


func set_process_delta_label(delta : float = 99.) -> void:
	var rounded_delta : float = G.round_to_dec(delta * 1000., 2)
	var label_text : String = str(rounded_delta) + " ms"
	process_delta_value.set_text(label_text)


func set_physics_delta_label(delta : float = 99.) -> void:
	var rounded_delta : float = G.round_to_dec(delta * 1000., 2)
	var label_text : String = str(rounded_delta) + " ms"
	physics_delta_value.set_text(label_text)


func set_mouse_position_label(mouse_position: Vector2) -> void:
	var mouse_position_rounded: Vector2i = Vector2i(mouse_position)
	var label_text : String = stringify_vector2(mouse_position_rounded)
	mouse_position_value.set_text(label_text)


func set_build_profile_label(build_profile: G.BuildProfile = G.build_profile) -> void:
	var label_text : String = str(G.BuildProfile.find_key(build_profile))
	build_profile_value.set_text(label_text)


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
		position_btns.visible = true
	else:
		collapse_expand_btn.icon = preload("uid://d1cqgv5o7t1if")
		#collapse_expand_btn.text = "Expand"
		#collapse_expand_btn.expand_icon = false
		debug_container.visible = false
		position_btns.visible = false


func _on_time_scale_slider_value_changed(value: float = time_scale_slider.value) -> void:
	var label_text : String = str(value)
	time_scale_value.set_text(label_text)
	Engine.time_scale = value



func refresh_stats() -> void:
	memory_usage_value.set_text(
		"%.2f MB" % (
			OS.get_static_memory_usage() / 1048576.0
		)
	)
	node_count_value.set_text(
		str(
			get_tree().get_node_count()
		)
	)
	tween_count_value.set_text(
		str(
			get_tree().get_processed_tweens().size()
		)
	)
	window_scale_value.set_text(
		str(ProjectSettings.get_setting("display/window/stretch/scale"))
	)
	
	window_count_value.set_text(
		str(DisplayServer.get_screen_count())
	)
	window_size_value.set_text(
		str(
			stringify_vector2(
				Vector2i(
					DisplayServer.screen_get_size()
				)
			)
		)
	)
	visible_viewport_size_value.set_text(
		str(
			stringify_vector2(
				Vector2i(
					get_viewport().get_visible_rect().size
				)
			)
		)
	)
	viewport_size_value.set_text(
		str(
			stringify_vector2(
				Vector2i(
					ProjectSettings.get_setting("display/window/size/viewport_width"),
					ProjectSettings.get_setting("display/window/size/viewport_height"),
				)
			)
		)
	)


func _on_nw_pressed() -> void:
	placement.set_anchors_and_offsets_preset(Control.LayoutPreset.PRESET_TOP_LEFT, Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE, 0)
	debug_panel.set_anchors_and_offsets_preset(Control.LayoutPreset.PRESET_TOP_LEFT, Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE, 0)
	collapse_expand_btn.set_h_size_flags(Control.SIZE_SHRINK_BEGIN)
	position_btns.set_h_size_flags(Control.SIZE_SHRINK_END)
	debug_container.move_to_front()
	debug_window.set_v_size_flags(Control.SIZE_SHRINK_BEGIN)


func _on_ne_pressed() -> void:
	placement.set_anchors_and_offsets_preset(Control.LayoutPreset.PRESET_TOP_RIGHT, Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE, 0)
	debug_panel.set_anchors_and_offsets_preset(Control.LayoutPreset.PRESET_TOP_RIGHT, Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE, 0)
	collapse_expand_btn.set_h_size_flags(Control.SIZE_SHRINK_END)
	position_btns.set_h_size_flags(Control.SIZE_SHRINK_BEGIN)
	debug_container.move_to_front()
	debug_window.set_v_size_flags(Control.SIZE_SHRINK_BEGIN)


func _on_sw_pressed() -> void:
	placement.set_anchors_and_offsets_preset(Control.LayoutPreset.PRESET_BOTTOM_LEFT, Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE, 0)
	debug_panel.set_anchors_and_offsets_preset(Control.LayoutPreset.PRESET_BOTTOM_LEFT, Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE, 0)
	collapse_expand_btn.set_h_size_flags(Control.SIZE_SHRINK_BEGIN)
	position_btns.set_h_size_flags(Control.SIZE_SHRINK_END)
	frame_btns.move_to_front()
	debug_window.set_v_size_flags(Control.SIZE_SHRINK_END)


func _on_se_pressed() -> void:
	placement.set_anchors_and_offsets_preset(Control.LayoutPreset.PRESET_BOTTOM_RIGHT, Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE, 0)
	debug_panel.set_anchors_and_offsets_preset(Control.LayoutPreset.PRESET_BOTTOM_RIGHT, Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE, 0)
	collapse_expand_btn.set_h_size_flags(Control.SIZE_SHRINK_END)
	position_btns.set_h_size_flags(Control.SIZE_SHRINK_BEGIN)
	frame_btns.move_to_front()
	debug_window.set_v_size_flags(Control.SIZE_SHRINK_END)


func stringify_vector2(vector2i : Vector2i) -> String:
	return "(" + str(vector2i.x).lpad(4) + ", " + str(vector2i.y).lpad(4) + ")"
