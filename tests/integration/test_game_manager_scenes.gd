extends GutTest
# tests/integration/test_game_manager_scenes.gd

var game_manager
var test_scene

func before_each():
	game_manager = preload("uid://bgbw0k1p81eif").instantiate()
	game_manager.auto_start_game = false
	add_child_autofree(game_manager)
	
	# Create test scene
	test_scene = Node.new()
	test_scene.name = "TestScene"

func test_clear_game_scenes_removes_children():
	game_manager.add_child(test_scene)
	
	game_manager.clear_game_scenes()
	
	await wait_frames(2)
	assert_eq(game_manager.get_child_count(), 0)

func test_scene_change_resets_pause():
	# Setup: Add pause request
	var obj = Node.new()
	G.request_pause(obj, true)
	assert_true(get_tree().paused)
	
	# Act: Request scene change
	game_manager.request_core_scene(G.CoreScenes.MAIN_MENU)
	await wait_frames(1)
	
	# Assert: Pause should be reset
	assert_false(get_tree().paused)
