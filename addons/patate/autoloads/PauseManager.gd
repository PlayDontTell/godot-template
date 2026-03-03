extends Node

## Emited when pause state changes
signal pause_state_changed(is_game_paused)

## All objects requesting pause
var request_pause_objects : Array = []


func declare_pause() -> void:
	var declaring_pause : bool = request_pause_objects.size() > 0
	if declaring_pause != get_tree().paused:
		get_tree().paused = declaring_pause
		pause_state_changed.emit(declaring_pause)


## Adds/Removes an object requesting pause, and setting pause accordingly
func request_pause(object : Object = null, requests_pause : bool = true) -> void:
	if is_instance_valid(object):
		if requests_pause and not request_pause_objects.has(object):
			request_pause_objects.append(object)
		elif not requests_pause and request_pause_objects.has(object):
			request_pause_objects.erase(object)
	declare_pause()


## Resets game pause (clear all pause requests and reset pause)
func reset_pause_state() -> void:
	request_pause_objects.clear()
	declare_pause()
