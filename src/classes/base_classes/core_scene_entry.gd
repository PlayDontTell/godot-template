# core_scene_entry.gd
class_name CoreSceneEntry
extends Resource

## The CoreScene enum value this entry corresponds to.
@export var id : G.CoreScene = G.CoreScene.MAIN_MENU
## The PackedScene to load for this CoreScene.
@export var scene : PackedScene = null
