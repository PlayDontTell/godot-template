extends WorldEnvironment

@onready var debug_layer: CanvasLayer = %DevLayer
@onready var expo_layer: CanvasLayer = %ExpoLayer

# Nodes that are not removed when changing Core Scene.
@export var persistent_nodes : Array[Node] = []
@export var config : ProjectConfig = preload("res://project_config.tres")

var target_scene_path: String = ""
var loading_progress: Array = [0.0]
var loading_instance: Control = null
var is_loading: bool = false


# To autoquit, deal with the close request.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()


func _ready() -> void:
	InputManager.register_intents({
		"move_up":    ["move_up", "ui_up"],
		"move_down":  ["move_down", "ui_down"],
		"move_left":  ["move_left", "ui_left"],
		"move_right": ["move_right", "ui_right"],
	})

	InputManager.extend_context(InputManager.Context.GAMEPLAY, [
		"move_up",
		"move_down",
		"move_left",
		"move_right",
		"confirm",
		"cancel",
		"pause",
	])
	
	init_game_manager()
	
	 #Load pre-existing settings file, and apply settings
	SettingsManager.load_settings() # TODO : Move settings saving/loading to SettingsManager ?
	
	 #Load custom player bindings if there are any in settings file
	InputManager.load_bindings()
	
	#If settings are loaded, apply them
	SettingsManager.apply_settings()
	
	restart_game()


func _process(delta: float) -> void:
	# Update the loading visual of the loading scene (a ProgresBar node)
	update_loading(delta)


func init_game_manager() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# By default, process is paused, so that update_loading is only called if needed.
	set_process(false)
	
	# Autoquit the game when asked to.
	get_tree().auto_accept_quit = false
	
	# Any scene can call G.request_core_scene to change among the G.CoreScene
	G.request_core_scene.connect(request_core_scene)
	
	# Needed to set environment adjustments
	SettingsManager.adjust_brightness.connect(self.environment.set_adjustment_brightness)
	SettingsManager.adjust_contrast.connect(self.environment.set_adjustment_contrast)
	SettingsManager.adjust_saturation.connect(self.environment.set_adjustment_saturation)
	
	# Requests to restart the game
	G.request_game_restart.connect(restart_game)


func restart_game() -> void:
	G.reset_variables()
	
	if G.config.auto_start_game:
		match G.config.build_profile:
			G.BuildProfile.DEV:
				request_core_scene(G.config.dev_start_scene)
			G.BuildProfile.RELEASE:
				request_core_scene(G.config.release_start_scene)
			G.BuildProfile.EXPO:
				SaveManager.create_save_file("default_name")
				SaveManager.save_data = expo_layer.get_default_save_data()
				G.config.ARCHIVE_SAVE_DIR = "user://archive/" + expo_layer.get_archive_folder() + "/"
				SaveManager.archive_save_data()
				request_core_scene(G.config.expo_start_scene)


# Select between main game scenes (main menu, game)
func request_core_scene(new_core_scene: StringName) -> void:
	# Avoid overlapping loads
	if is_loading:
		push_warning("select_game_scene called while a load is already in progress; ignoring.")
		return
	
	# Clear existing game scenes
	clear_game_scenes()
	
	# When loading a new game scene, the node who requested pauses are destroyed,
	# So we have to clear the list of nodes requesting a pause.
	PauseManager.reset_pause_state()
	
	# Set publicly the new game scene
	G.core_scene = new_core_scene
	
	# Memorizing the path of the current loading game_scene
	target_scene_path = G.config.get_scene(G.core_scene).resource_path
	# Start loading the scene, before displaying it
	start_threaded_load()


# Load the scene with a loading screen, so that the game doesn't freeze while loading.
func start_threaded_load() -> void:
	
	# If no path is declared, error
	if target_scene_path == "":
		#push_error("No target scene path set for loading.")
		return
	
	show_loading_screen()
	
	var err: int = ResourceLoader.load_threaded_request(target_scene_path)
	if err != OK:
		push_error("Failed to start threaded load for %s (error %d)" % [target_scene_path, err])
		clear_loading_state()
		return
	
	is_loading = true
	set_process(true)


func update_loading(_delta: float) -> void:
	# Function only applies if something is loading
	if not is_loading or target_scene_path == "":
		return
	
	var status: int = ResourceLoader.load_threaded_get_status(target_scene_path, loading_progress)
	
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			update_loading_progress(loading_progress[0])
		
		ResourceLoader.THREAD_LOAD_LOADED:
			var res: Resource = ResourceLoader.load_threaded_get(target_scene_path)
			var packed: PackedScene = res as PackedScene
			if packed == null:
				# Defensive in case the resource is not what we expect.
				push_error("Loaded resource is not a PackedScene: %s" % target_scene_path)
				clear_loading_state()
				return
			finish_game_scene_change(packed)
		
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Failed to load game scene: %s" % target_scene_path)
			clear_loading_state()


func update_loading_progress(v: float) -> void:
	if is_instance_valid(loading_instance) and loading_instance.has_method("set_progress"):
		loading_instance.call("set_progress", v)


# When the target game scene (G.core_scene) is loaded :
func finish_game_scene_change(packed: PackedScene) -> void:
	# Remove loading overlay first so the new scene is clean.
	if is_instance_valid(loading_instance):
		loading_instance.queue_free()
		loading_instance = null
	
	var instance: Node = packed.instantiate()
	self.add_child(instance)
	
	# Notify the rest of the game that the scene really changed.
	G.new_core_scene_loaded.emit(G.core_scene)
	print("Loaded " + G.core_scene)
	
	clear_loading_state()


# Reset loading information, for next loading session
func clear_loading_state() -> void:
	is_loading = false
	target_scene_path = ""
	loading_progress[0] = 0.0
	
	if is_instance_valid(loading_instance):
		loading_instance.queue_free()
	loading_instance = null
	
	# We don't need to update loading information, so we stop _process()
	set_process(false)


# Add the loading scene
func show_loading_screen() -> void:
	var scene : PackedScene = G.config.get_scene(G.LOADING)
	if not scene:
		push_error("GameManager: no scene registered for LOADING.")
		return
	loading_instance = scene.instantiate()
	self.add_child(loading_instance)


func clear_game_scenes() -> void:
	for child in self.get_children():
		if child in persistent_nodes:
			continue
		child.queue_free()
