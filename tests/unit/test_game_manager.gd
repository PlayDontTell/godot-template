extends GutTest
# tests/unit/test_game_manager.gd

var GameManager = preload("uid://bgbw0k1p81eif")
var gm

func before_each():
	gm = GameManager.instantiate()

func test_overlapping_load_prevention():
	gm.is_loading = true
	gm.target_scene_path = "test://path"
	
	# Should do nothing when already loading
	gm.request_core_scene(G.CoreScenes.GAME)
	
	# Path should remain unchanged
	assert_eq(gm.target_scene_path, "test://path")

func test_clear_loading_state_resets_all_flags():
	gm.is_loading = true
	gm.target_scene_path = "test://scene"
	gm.loading_progress[0] = 0.5
	
	gm.clear_loading_state()
	
	assert_false(gm.is_loading)
	assert_eq(gm.target_scene_path, "")
	assert_eq(gm.loading_progress[0], 0.0)

func test_empty_scene_path_error_handling():
	gm.target_scene_path = ""
	
	# Should handle gracefully
	gm.start_threaded_load()
	
	assert_false(gm.is_loading)
