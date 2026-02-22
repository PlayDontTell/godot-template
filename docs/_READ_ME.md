# Project Architecture

## Autoloads

| Name | File | Purpose |
|------|------|---------|
| `G` | `Global.gd` | Framework infrastructure: scenes, pause, settings, save, localization |
| `C` | `Config.gd` | Game-specific constants and runtime state |
| `I` | `InputService.gd` | Intent-based input: what is the player trying to do? |
| `D` | `DeviceTracker.gd` | Device detection: what input method is the player using? |

Each autoload has its own `.md` doc. Read those before touching the scripts.

---

## Scene Structure

The root scene contains **GameManager** (a `WorldEnvironment` node) plus two persistent overlay layers:

```
GameManager
├── DebugLayer     # DEV + EXPO only — stats overlay, toggled with toggle_Dev_layer
└── ExpoLayer      # EXPO only — idle timer and restart logic
```

These two layers survive all scene transitions. Everything else under GameManager is cleared on each scene change.

**To switch scenes** from anywhere:
```gdscript
G.request_core_scene.emit(G.CoreScene.GAME)
```

Scene paths are defined in `G.CoreScenePath`. Starting scene per build profile is set in the GameManager inspector.

---

## Build Profiles

Set `G.build_profile` at the top of `Global.gd`:

| Profile | DebugLayer | ExpoLayer | Use case |
|---------|------------|-----------|----------|
| `DEV` | ✓ | ✗ | Development |
| `RELEASE` | ✗ | ✗ | Shipping |
| `EXPO` | ✓ | ✓ | Convention booth |

---

## Input

Never call `Input.*` directly in gameplay code — always go through `I`:

```gdscript
I.just_pressed("confirm")   # one frame
I.pressed("cancel")         # held
I.get_move_vector()         # normalized Vector2
```

Modal filtering uses contexts — acquire one when a UI opens, release when it closes:
```gdscript
var _ctx := I.acquire_context(I.Context.PAUSE, self, 100)
I.release_context(_ctx)  # or just free the node
```

See `InputService.md` and `DeviceTracker.md` for full docs.

---

## Testing (GUT)

Install GUT via **AssetLib**, enable in **Project Settings → Plugins**.

```
tests/
├── unit/          # Fast, no I/O — run constantly during development
└── integration/   # Slower, real file/scene dependencies — run before commits
```

```gdscript
# tests/unit/test_example.gd
extends GutTest

func test_something():
	assert_eq(1, 1)
```

Run from the **Gut panel** (bottom of editor) or command line:
```bash
godot -s addons/gut/gut_cmdln.gd -gdir=res://tests
```

Test files and functions must start with `test_`. Use `before_each` / `after_each` for setup and cleanup. See `tests_using_GUT.md` for full reference.
