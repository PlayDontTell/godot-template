extends Node

var config: ProjectConfig = preload("res://project_config.tres")

enum ReleaseMode {
	DEV, ## For game development, testing, debugging
	PLAYTEST, ## controlled playtesting sessions
	EXPO, ## For game presentation booths at conventions and events
	RELEASE, ## For public releases
}

## Emitted to request a game restart
@warning_ignore("unused_signal")
signal request_game_restart

## Emitted to request a scene change
@warning_ignore("unused_signal")
signal request_core_scene(requested_core_scene : StringName)

## Emitted when Core Scene changed and is loaded
@warning_ignore("unused_signal")
signal new_core_scene_loaded(new_core_scene : StringName)

const LOADING := &"LOADING"
const MAIN_MENU := &"MAIN_MENU"

## Current Core Scene
var core_scene : StringName


func _ready() -> void:
	set_process(false)


## Quickly test if game is run for dev or debugging
func is_dev() -> bool:
	assert(config != null, "Missing Project config file (project_config.tres).")
	return config.release_mode == ReleaseMode.DEV

## Quickly test if game is run for a UX/Design playtest
func is_playtest() -> bool:
	assert(config != null, "Missing Project config file (project_config.tres).")
	return config.release_mode == ReleaseMode.PLAYTEST

## Quickly test if game is run for an expo event
func is_expo() -> bool:
	assert(config != null, "Missing Project config file (project_config.tres).")
	return config.release_mode == ReleaseMode.EXPO

## Quickly test if game is run as release version
func is_release() -> bool:
	assert(config != null, "Missing Project config file (project_config.tres).")
	return config.release_mode == ReleaseMode.RELEASE
