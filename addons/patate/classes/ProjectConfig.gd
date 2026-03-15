## Project-level configuration resource.
## Edit res://project_config.tres in the inspector to configure your project.
## This is the single place a developer needs to look when setting up or deploying the game.
class_name ProjectConfig
extends Resource

## Returns the PackedScene for a given CoreScene, or null if not found.
func get_scene(core_scene : StringName) -> PackedScene:
	if core_scenes.has(core_scene):
		return core_scenes[core_scene]
	push_warning("ProjectConfig: no scene registered for CoreScene %s" % core_scene)
	return null

## The current release mode. Switch between DEV, RELEASE and EXPO before exporting.
@export var release_mode : G.ReleaseMode = G.ReleaseMode.DEV

@export_group("Core Scenes")
## One entry per CoreScene enum value. Order does not matter.
@export var core_scenes : Dictionary[StringName, PackedScene] = {
	&"GAME": preload("res://src/core/core_scenes/game/game.tscn"),
	G.LOADING: preload("res://src/core/core_scenes/loading/loading_screen.tscn"),
	G.MAIN_MENU: preload("res://src/core/core_scenes/main_menu/main_menu.tscn"),
}

@export_group("Start Scenes")
## Scene to load on startup in DEV release mode.
@export var dev_start_scene : StringName = G.MAIN_MENU
## Scene to load on startup in PLAYTEST release mode.
@export var playtest_start_scene : StringName = G.MAIN_MENU
## Scene to load on startup in RELEASE release mode.
@export var release_start_scene : StringName = G.MAIN_MENU
## Scene to load on startup in EXPO release mode.
@export var expo_start_scene : StringName = G.MAIN_MENU
## If true, the start scene loads automatically on game start and restart.
## If false, your code is responsible for calling request_core_scene manually.
@export var auto_start_game : bool = true

@export_group("Directories", "")
## Directory for internal binary files (settings, etc.).
@export var BIN_DIR : String = "user://bin/"
## Directory where save files are stored.
@export var SAVE_DIR : String = "user://saves/"
## Directory where archived saves are moved (e.g. on expo restart).
@export var ARCHIVE_SAVE_DIR : String = "user://archive/"


@export_group("Save System")
@export_subgroup("Save System Configuration", "")
## When enabled, the player can load saves manually (e.g. from a menu button).
## When disabled, the game handles loading automatically —
## no load button is shown, and the player never chooses a save file.
@export var manual_loading_enabled : bool = false
## When enabled, the player can trigger saves manually (e.g. from a menu button).
## When disabled, the game handles saving entirely through autosaves —
## no save button is shown, and the player never chooses when to save.
## Both modes can coexist: a game with manual saving can also autosave.
@export var manual_saving_enabled : bool = false
## When enabled, the player picks a slot (profile) before playing.
## Each slot can contain one or more save files depending on your design.
## When disabled, saves are stored in a flat list — no slot selection screen.
@export var has_save_slots : bool = false
## If save slot are customized, with a name for example.
## Every property to adjust should live in SaveData as @export variables
@export var save_slots_need_setup: bool = false
## Number of available save slots. Only used when has_save_slots is true.
@export_range(1, 100) var max_save_slots : int = 3

@export_subgroup("Save File Limits", "")
## Maximum autosave files to keep per slot (oldest pruned). 0 = no autosaves.
@export_range(0, 50) var max_autosaves : int = 3
## Maximum quicksave files to keep per slot (oldest pruned). 0 = no quicksaves.
@export_range(0, 50) var max_quicksaves : int = 1
## Maximum manual save files per slot. 0 = unlimited.
@export_range(0, 200) var max_manual_saves : int = 100

@export_subgroup("Save Files Properties", "")
## Encryption key for save files. Leave empty to disable encryption.
## Set a unique key before shipping a RELEASE build. Never share it publicly.
@export var SAVE_ENCRYPT_KEY : String = ""
## File extension used for all save and settings files.
@export var SAVE_FILE_EXTENSION : String = ".save"
## The default image used to associate with saves
@export var DEFAULT_SAVE_IMAGE : Texture2D = preload("res://assets/art/ui/temp/cursors/Vector/Basic/line_cross.svg")
## The size of save file screenshots by default
@export var SCREENSHOT_SIZE : Vector2i = Vector2i(80, 40)


@export_group("Input Bindings")
## Are duplicate input bindings blocked or simply warned ?
@export var block_duplicate_bindings: bool = true
