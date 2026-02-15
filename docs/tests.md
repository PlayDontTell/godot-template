# GUT Testing Guide

A practical guide for testing Godot projects with [GUT (Godot Unit Test)](https://gut.readthedocs.io/).

## Quick Install

### Install GUT from AssetLib
1. Open your Godot project
2. Click **AssetLib** tab (top of editor)
3. Search for **"GUT"**
4. Click **Download** → **Install**
5. Enable the plugin: **Project → Project Settings → Plugins** → Check "Gut"

## Folder Structure

Organize your tests by separating unit tests (pure logic) from integration tests (file I/O, external dependencies):

```
your_project/
├── scripts/
│   └── your_script.gd          # Your game scripts
└── tests/
	├── unit/                    # Unit tests: Fast (milliseconds), run frequently during development
	│   ├── test_player.gd
	│   ├── test_inventory.gd
	│   └── test_utils.gd
	└── integration/             # Integration tests: Slower (seconds), run before commits or deployment
		├── test_save_system.gd
		├── test_game_flow.gd
		└── test_settings.gd
```

## Writing Your First Test

### 1. Create a Test File

Create `res://tests/unit/test_example.gd`:

```gdscript
extends GutTest

# Test functions must start with "test_"

func test_passes():
	# this test will pass because 1 does equal 1
	assert_eq(1, 1)

func test_fails():
	# this test will fail because those strings are not equal
	assert_eq('hello', 'goodbye')
```

### 2. Test Your Own Script

```gdscript
extends GutTest

# Load the script you want to test
var Player = preload("res://scripts/player.gd")
var player

# Runs before each test
func before_each():
	player = Player.new()

# Runs after each test
func after_each():
	player.free()

func test_player_starts_with_full_health():
	assert_eq(player.health, 100, "Player should start with 100 health")

func test_player_takes_damage():
	player.take_damage(30)
	assert_eq(player.health, 70, "Player should have 70 health after taking 30 damage")

func test_player_dies_at_zero_health():
	player.take_damage(100)
	assert_true(player.is_dead, "Player should be dead at 0 health")
```

## Running Tests

### Using GUT Panel (Easiest)
1. Look for the **"Gut"** panel at the bottom of Godot (next to Output, Debugger)
2. It should auto-detect tests in `res://tests/`
3. Click **"Run All"** or select specific folders/files

### Using Command Line
```bash
# Run all tests
godot -s addons/gut/gut_cmdln.gd -gdir=res://tests

# Run only unit tests
godot -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit

# Run only integration tests
godot -s addons/gut/gut_cmdln.gd -gdir=res://tests/integration

# Run specific file
godot -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_player.gd
```

For more command line options, see the [GUT CLI documentation](https://gut.readthedocs.io/en/latest/Command-Line.html).

## Common Assertions

```gdscript
# Equality
assert_eq(actual, expected, "optional message")
assert_ne(actual, not_expected, "optional message")

# Boolean
assert_true(value, "optional message")
assert_false(value, "optional message")

# Null checks
assert_null(value, "optional message")
assert_not_null(value, "optional message")

# Comparison
assert_gt(value, minimum, "greater than")
assert_lt(value, maximum, "less than")
assert_true(value >= minimum, "greater than or equal")
assert_true(value <= maximum, "less than or equal")

# Floats (with tolerance)
assert_almost_eq(actual, expected, epsilon, "message")
assert_almost_ne(actual, expected, epsilon, "message")

# Collections
assert_true(item in array, "check if item in array")
assert_eq(array.size(), 5, "check array size")

# Signals
var signal_watcher = watch_signals(object)
# ... trigger signal ...
assert_signal_emitted(object, "signal_name")
assert_signal_emitted_with_parameters(object, "signal_name", [param1, param2])
```

See the [full list of assertions](https://gut.readthedocs.io/en/latest/Asserts-and-Methods.html) in the GUT documentation.

## Test Lifecycle Hooks

```gdscript
extends GutTest

# Runs once before all tests in this file
func before_all():
	print("Setting up test suite")

# Runs before each individual test
func before_each():
	print("Setting up test")

# Runs after each individual test
func after_each():
	print("Cleaning up test")

# Runs once after all tests in this file
func after_all():
	print("Tearing down test suite")

func test_something():
	assert_true(true)
```

## Unit vs Integration Tests

### Unit Tests
**What:** Test individual functions/methods in isolation  
**Characteristics:**
- No file I/O
- No network calls
- No scene tree dependencies (unless testing nodes)
- Fast execution (milliseconds)
- Mock external dependencies

**Example:**
```gdscript
# tests/unit/test_inventory.gd
extends GutTest

var Inventory = preload("res://scripts/inventory.gd")
var inventory

func before_each():
	inventory = Inventory.new()

func test_add_item():
	inventory.add_item("sword")
	assert_eq(inventory.get_item_count("sword"), 1)

func test_remove_item():
	inventory.add_item("sword")
	inventory.remove_item("sword")
	assert_eq(inventory.get_item_count("sword"), 0)
```

### Integration Tests
**What:** Test how multiple components work together  
**Characteristics:**
- May involve file I/O
- May use scene tree
- Test real interactions between systems
- Slower execution (seconds)
- Use real dependencies

**Example:**
```gdscript
# tests/integration/test_save_system.gd
extends GutTest

var save_system
var test_save_path = "user://test_save.data"

func before_each():
	save_system = preload("res://scripts/save_system.gd").new()

func after_each():
	# Clean up test files
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(test_save_path)

func test_save_and_load():
	var data = {"player_name": "Hero", "level": 5}
	
	save_system.save_game(test_save_path, data)
	assert_true(FileAccess.file_exists(test_save_path), "Save file should exist")
	
	var loaded_data = save_system.load_game(test_save_path)
	assert_eq(loaded_data.player_name, "Hero")
	assert_eq(loaded_data.level, 5)
```

## Testing Async Functions

```gdscript
func test_async_operation():
	var result = await some_async_function()
	assert_eq(result, "expected_value")

func test_with_timeout():
	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	assert_true(something_happened, "Should happen after delay")
```

## Testing Signals

```gdscript
func test_signal_emission():
	var player = Player.new()
	var signal_watcher = watch_signals(player)
	
	player.take_damage(50)
	
	assert_signal_emitted(player, "health_changed")
	assert_signal_emitted_with_parameters(player, "health_changed", [50])
	assert_signal_emit_count(player, "health_changed", 1)
```

## Mocking and Doubling

GUT provides tools for creating test doubles:

```gdscript
# Create a double (mock) of a class
var double = double(MyClass)

# Stub a method to return a specific value
stub(double, "get_health").to_return(100)

# Verify a method was called
assert_called(double, "take_damage")
assert_called(double, "take_damage", [50])  # with specific parameters
```

See [Doubles documentation](https://gut.readthedocs.io/en/latest/Doubles.html) for more details.

## Best Practices

### 1. Use Descriptive Test Names
```gdscript
# Good
func test_player_cannot_attack_while_stunned():
	player.stun()
	var can_attack = player.attack()
	assert_false(can_attack)

# Bad
func test_attack():
	player.stun()
	assert_false(player.attack())
```

### 2. Arrange-Act-Assert Pattern
```gdscript
func test_inventory_full_prevents_adding_items():
	# Arrange: Set up the test
	var inventory = Inventory.new()
	inventory.max_size = 2
	inventory.add_item("sword")
	inventory.add_item("shield")
	
	# Act: Perform the action
	var result = inventory.add_item("potion")
	
	# Assert: Verify the outcome
	assert_false(result, "Should not add item to full inventory")
	assert_eq(inventory.size(), 2, "Inventory size should remain 2")
```

### 3. Keep Tests Independent
```gdscript
# Each test should not depend on others
# Use before_each() to set up fresh state

func before_each():
	player = Player.new()  # Fresh instance for each test

func test_first():
	player.level = 5
	assert_eq(player.level, 5)

func test_second():
	# This test starts with a fresh player, not level 5
	assert_eq(player.level, 1)
```

### 4. Clean Up Resources
```gdscript
func after_each():
	# Free nodes
	if player:
		player.queue_free()
	
	# Delete test files
	if FileAccess.file_exists("user://test.save"):
		DirAccess.remove_absolute("user://test.save")
```

## Troubleshooting

### Tests Not Running
- Verify GUT is installed and enabled in **Project Settings → Plugins**
- Check that test files start with `test_` prefix
- Check that test functions start with `test_` prefix
- Look for errors in the GUT panel output

### Path Issues
- Use `res://` for project files: `preload("res://scripts/player.gd")`
- Use `user://` for save data: `"user://test_save.data"`

### Tests Fail in Unexpected Ways
- Check `before_each()` and `after_each()` are cleaning up properly
- Make sure tests don't depend on execution order
- Look for leftover files or state from previous tests

## Advanced Topics

For more advanced features, see the GUT documentation:
- [Parameterized Tests](https://gut.readthedocs.io/en/latest/ParameterizedTests.html)
- [Inner Test Classes](https://gut.readthedocs.io/en/latest/InnerClasses.html)
- [Continuous Integration](https://gut.readthedocs.io/en/latest/CI.html)
- [Command Line Options](https://gut.readthedocs.io/en/latest/Command-Line.html)

## Example Test Suite

Here's what a complete test suite might look like:

```
tests/
├── unit/
│   ├── test_player.gd           # Player logic tests
│   ├── test_inventory.gd        # Inventory logic tests
│   ├── test_combat.gd           # Combat calculations
│   ├── test_utils.gd            # Utility functions
│   └── test_item_database.gd   # Item data validation
└── integration/
	├── test_save_system.gd      # Save/load with files
	├── test_game_flow.gd        # Scene transitions
	├── test_ui_integration.gd   # UI + game logic
	└── test_multiplayer.gd      # Network tests
```
