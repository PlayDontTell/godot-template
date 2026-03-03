@tool
extends Node

var config: ProjectConfig = preload("res://project_config.tres")

enum BuildProfile {
	DEV, ## For game development, testing, debugging
	PLAYTEST, ## controlled playtesting sessions
	EXPO, ## For game presentation booths at conventions and events
	RELEASE, ## For public releases
}

## Emited to request a game restart
@warning_ignore("unused_signal")
signal request_game_restart

## Emited to request a scene change
@warning_ignore("unused_signal")
signal request_core_scene(requested_core_scene : StringName)

## Emited when Core Scene changed and is loaded
@warning_ignore("unused_signal")
signal new_core_scene_loaded(new_core_scene : StringName)

const LOADING := &"LOADING"
const MAIN_MENU := &"MAIN_MENU"

## Current Core Scene
var core_scene : StringName


func _ready() -> void:
	set_process(false)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	reset_variables()
	
	# Initialize game folders (saves, settings, etc.)
	SaveManager.init_folders()
	
	# Process should only start when save_data has been initialized, so that save_data.meta exists.
	set_process(true)


func _process(delta: float) -> void:
	SaveManager.save_data.time_since_start += delta
	if not get_tree().paused:
		SaveManager.save_data.time_played += delta


func reset_variables() -> void:
	pass


## Quickly test if game is run for dev or debugging
func is_dev() -> bool:
	assert(config != null, "Missing Project config file (project_config.tres).")
	return config.build_profile == BuildProfile.DEV

## Quickly test if game is run for a UX/Design playtest
func is_playtest() -> bool:
	assert(config != null, "Missing Project config file (project_config.tres).")
	return config.build_profile == BuildProfile.PLAYTEST

## Quickly test if game is run for an expo event
func is_expo() -> bool:
	assert(config != null, "Missing Project config file (project_config.tres).")
	return config.build_profile == BuildProfile.EXPO

## Quickly test if game is run as release version
func is_release() -> bool:
	assert(config != null, "Missing Project config file (project_config.tres).")
	return config.build_profile == BuildProfile.RELEASE
