# Save System Test Suite

This test suite provides comprehensive testing for the G.gd save system script using the GUT (Godot Unit Test) framework.

## Test Files

1. **test_save_system.gd** - Unit tests for individual functions and features
2. **test_save_system_integration.gd** - Integration tests for complex workflows and edge cases

## Setup

### 1. Install GUT (Godot Unit Test)

You have two options:

#### Option A: Install from AssetLib (Recommended)
1. Open your Godot project
2. Go to AssetLib tab
3. Search for "GUT"
4. Download and install "Gut - Godot Unit Test"

#### Option B: Manual Installation
1. Download GUT from: https://github.com/bitwes/Gut
2. Extract to `res://addons/gut/`
3. Enable the plugin in Project Settings → Plugins

### 2. Add Test Files

1. Create a `tests` folder in your project: `res://tests/`
2. Copy both test files into this folder:
   - `test_save_system.gd`
   - `test_save_system_integration.gd`

### 3. Verify G.gd Path

Make sure the path to your save system script is correct in the test files:
```gdscript
var g_instance: Node = load("res://G.gd").new()
```

If your script is in a different location, update the path accordingly.

## Running Tests

### Method 1: Using GUT Panel (Recommended)

1. Open your Godot project
2. Look for the "Gut" panel at the bottom of the editor (next to Output, Debugger, etc.)
3. Click "Run All" to run all tests
4. Or select specific test files and click "Run"

### Method 2: Using Test Scene

1. Create a new scene
2. Add a Node2D or Control as root
3. Add "GutPanel" node as child (from addons/gut)
4. Configure the panel:
   - Set "Directory 1" to "res://tests/"
   - Set "Prefix" to "test_"
5. Run the scene (F6)

### Method 3: Command Line

Run tests from command line:
```bash
# Run all tests
godot --path /path/to/project -s addons/gut/gut_cmdln.gd

# Run specific test file
godot --path /path/to/project -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_save_system.gd
```

## Test Coverage

### Unit Tests (test_save_system.gd)

#### Folder Initialization
- ✓ Creates all required directories
- ✓ Handles repeated initialization

#### Settings System
- ✓ Creates default settings when missing
- ✓ Loads existing settings
- ✓ Persists changes across sessions
- ✓ Clamps values to valid ranges
- ✓ Formats setting text correctly

#### Save File Creation
- ✓ Creates new save files
- ✓ Sets metadata properly
- ✓ Handles name collisions
- ✓ Sanitizes invalid filenames
- ✓ Emits signals correctly

#### Save/Load Operations
- ✓ Updates metadata on save
- ✓ Preserves custom data
- ✓ Uses temporary files for safety
- ✓ Loads saved data correctly
- ✓ Sets current data when requested
- ✓ Returns fallback on errors
- ✓ Updates missing keys from old saves

#### File Management
- ✓ Lists all save files
- ✓ Filters by extension
- ✓ Deletes files
- ✓ Handles nonexistent files
- ✓ Moves files to archive

#### Event Logging
- ✓ Adds events to log
- ✓ Prevents duplicates
- ✓ Handles uninitialized data

#### Utility Functions
- ✓ Sanitizes strings
- ✓ Validates input
- ✓ Updates dictionaries recursively
- ✓ Rounds to decimals
- ✓ Generates circle points
- ✓ Applies saturation to colors

#### Pause System
- ✓ Pauses/unpauses game
- ✓ Handles multiple pause requests
- ✓ Resets pause state

#### Localization
- ✓ Changes locale
- ✓ Emits signals
- ✓ Handles invalid locales

### Integration Tests (test_save_system_integration.gd)

#### Save Lifecycle
- ✓ Complete create-modify-save-load cycle
- ✓ Multiple save sessions
- ✓ Corruption protection
- ✓ Concurrent operations

#### Data Migration
- ✓ Backward compatibility
- ✓ Version tracking
- ✓ Timestamp accuracy

#### Stress Tests
- ✓ Large datasets
- ✓ Deep nested structures
- ✓ Many event logs

#### Edge Cases
- ✓ Empty world names
- ✓ Very long names
- ✓ Special characters
- ✓ Null and empty values
- ✓ Simultaneous operations

#### Settings Integration
- ✓ Settings persist across instances
- ✓ Signal emission
- ✓ All setting types

#### Archive Functionality
- ✓ Preserves all data
- ✓ Handles partial failures

#### Memory & Performance
- ✓ Memory cleanup on multiple loads
- ✓ Rapid save operations

## Understanding Test Results

### Passing Tests
```
✓ test_create_save_file_creates_new_file
```
All assertions passed - feature works correctly

### Failing Tests
```
✗ test_save_data_updates_metadata
  Expected: not equal to "2024-01-01"
  Actual: "2024-01-01"
```
One or more assertions failed - indicates a bug

### Errors
```
ERROR in test_load_data_loads_saved_file
  Invalid path: res://G.gd
```
Test setup issue or critical failure

## Customizing Tests

### Adding New Tests

Add a new test function to either file:

```gdscript
func test_your_new_feature():
	# Setup
	var file_path = g_instance.create_save_file("TestWorld")
	
	# Execute
	g_instance.data.player.position = Vector2i(10, 20)
	await g_instance.save_data(file_path)
	
	# Verify
	var loaded = g_instance.load_data(file_path, false)
	assert_eq(loaded[0].player.position, Vector2i(10, 20), "Position should persist")
```

### Common Assertions

```gdscript
assert_true(value, "message")
assert_false(value, "message")
assert_eq(actual, expected, "message")
assert_ne(actual, not_expected, "message")
assert_gt(value, minimum, "message")
assert_lt(value, maximum, "message")
assert_almost_eq(actual, expected, epsilon, "message")
assert_true(value in array, "message")
```

### Testing Signals

```gdscript
var signal_watcher = watch_signals(g_instance)
g_instance.some_function()
assert_signal_emitted(g_instance, "signal_name")
assert_signal_emitted_with_parameters(g_instance, "signal_name", [param1, param2])
```

## Troubleshooting

### Tests Not Running
- Verify GUT is installed and enabled
- Check that test files are in the correct folder
- Ensure test functions start with `test_`
- Check the GUT output for errors

### Path Errors
- Update the path to G.gd in the test files
- Ensure G.gd is in your project

### File Access Errors
- Tests use `user://` directory which should be writable
- Check Godot has proper file permissions
- Try clearing the test directories manually if tests fail repeatedly

### Signal Not Emitted Errors
- Ensure the G instance is added to the scene tree (`add_child_autofree()`)
- Some signals require specific setup or tree processing

## Best Practices

1. **Run tests frequently** - After each change to G.gd
2. **Keep tests independent** - Each test should work in isolation
3. **Use descriptive names** - Test names should describe what they verify
4. **Add tests for bugs** - When fixing a bug, add a test to prevent regression
5. **Clean up resources** - Use `before_each()` and `after_each()` properly

## Contributing

When adding new features to G.gd:
1. Write tests first (TDD approach)
2. Implement the feature
3. Run all tests to ensure nothing broke
4. Add integration tests for complex workflows

## Additional Resources

- GUT Documentation: https://github.com/bitwes/Gut/wiki
- Godot Testing Guide: https://docs.godotengine.org/en/stable/tutorials/scripting/unit_testing.html
- GUT Video Tutorial: https://www.youtube.com/watch?v=vBbqlfmcAlc
