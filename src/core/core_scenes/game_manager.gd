extends WorldEnvironment


var target_scene_path: String = ""
var loading_progress: Array = [0.0]
var loading_instance: Control = null
var is_loading: bool = false


# To autoquit, deal with the close request.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# By default, process is paused, so that update_loading is only called if needed.
	set_process(false)
	
	# Autoquit the game when asked to.
	get_tree().auto_accept_quit = false
	
	# Any scene can call G.request_core_scene to change among the G.CoreScenes
	G.request_core_scene.connect(request_core_scene)
	
	# When ready, launch the main menu of the game.
	request_core_scene(G.CoreScenes.MAIN_MENU)
	
	G.adjust_brightness.connect(self.environment.set_adjustment_brightness)
	G.adjust_contrast.connect(self.environment.set_adjustment_contrast)
	G.adjust_saturation.connect(self.environment.set_adjustment_saturation)


func _process(delta: float) -> void:
	# Update the loading visual of the loading scene (a ProgresBar node)
	update_loading(delta)


# Select between main game scenes (main menu, game)
func request_core_scene(new_core_scene: G.CoreScenes) -> void:
	# Avoid overlapping loads
	if is_loading:
		push_warning("select_game_scene called while a load is already in progress; ignoring.")
		return
	
	# Clear existing game scenes
	clear_game_scenes()
	
	# When loading a new game scene, the node who requested pauses are destroyed,
	# So we have to clear the list of nodes requesting a pause.
	G.reset_pause_state()
	
	# Set publicly the new game scene
	G.core_scene = new_core_scene
	
	# Memorizing the path of the current loading game_scene
	target_scene_path = G.CoreScenesPaths[G.core_scene]
	
	# Start loading the scene, before displaying it
	start_threaded_load()


# Load the scene with a loading screen, so that the game doesn't freeze while loading.
func start_threaded_load() -> void:
	
	# If no path is declared, error
	if target_scene_path == "":
		push_error("No target scene path set for loading.")
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
	print("Loaded " + G.CoreScenes.keys()[G.core_scene])
	
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
	var path: String = G.CoreScenesPaths[G.CoreScenes.LOADING]
	var packed: PackedScene = load(path) as PackedScene
	
	loading_instance = packed.instantiate()
	
	self.add_child(loading_instance)


# Remove every scene under the Game Manager (except if mentionned in EXCEPTIONS)
const EXCEPTIONS : Array = []
func clear_game_scenes() -> void:
	for child in self.get_children():
		if child in EXCEPTIONS:
			continue
		child.queue_free()
