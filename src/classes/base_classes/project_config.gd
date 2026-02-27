## Project-level configuration resource.
## Edit res://config/project_config.tres in the inspector to configure your project.
## This is the single place a developer needs to look when setting up or deploying the game.
class_name ProjectConfig
extends Resource

## Returns the PackedScene for a given CoreScene, or null if not found.
func get_scene(core_scene : G.CoreScene) -> PackedScene:
	for entry : CoreSceneEntry in core_scenes:
		if entry.id == core_scene:
			return entry.scene
	push_warning("ProjectConfig: no scene registered for CoreScene %s" % G.CoreScene.keys()[core_scene])
	return null


@export_group("Build")
## The current build profile. Switch between DEV, RELEASE and EXPO before exporting.
@export var build_profile : G.BuildProfile = G.BuildProfile.DEV

@export_group("Core Scenes")
## One entry per CoreScene enum value. Order does not matter.
@export var core_scenes : Array[CoreSceneEntry] = []

@export_group("Start Scenes")
## Scene to load on startup in DEV build profile.
@export var dev_start_scene : G.CoreScene = G.CoreScene.MAIN_MENU
## Scene to load on startup in RELEASE build profile.
@export var release_start_scene : G.CoreScene = G.CoreScene.MAIN_MENU
## Scene to load on startup in EXPO build profile.
@export var expo_start_scene : G.CoreScene = G.CoreScene.MAIN_MENU
## If true, the start scene loads automatically on game start and restart.
## If false, your code is responsible for calling request_core_scene manually.
@export var auto_start_game : bool = true

@export_group("Save System")
## Whether the save system uses named slots (e.g. RPG profiles).
## If false, saves are managed as a flat list of files.
@export var has_save_slots : bool = false
## Encryption key for save files. Change this before shipping — never share it publicly.
@export var SAVE_ENCRYPT_KEY : String = "&Fr4GMt8T!0n.5%eR52:r&/iPJKl3s?,nnr"
## File extension used for all save and settings files.
@export var FILES_EXTENSION : String = ".data"
## Directory for internal binary files (settings, etc.).
@export var BIN_DIR : String = "user://bin/"
## Directory where save files are stored.
@export var SAVE_DIR : String = "user://saves/"
## Directory where archived saves are moved (e.g. on expo restart).
@export var ARCHIVE_SAVE_DIR : String = "user://archive/"
