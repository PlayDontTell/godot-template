# Global (G)

The global autoload for framework-level infrastructure. Holds shared state and systems that any node in the game may need. Always alive, always processing, never paused.

For game-specific constants and state, use `C` (Config) instead.

`G` is organized into regions — read only the section you need.

---

## Build Profiles

Controls which systems activate and which scenes launch on startup. Set `build_profile` at the top of `G.gd`.

| Profile   | Use case                          |
|-----------|-----------------------------------|
| `DEV`     | Local development, debug tools on |
| `RELEASE` | Shipping build                    |
| `EXPO`    | Convention booth, idle restart on |

```gdscript
if G.is_debug():  # true only in DEV
	show_debug_info()
```

---

## Core Scenes

Top-level application states: main menu, game, loading screen, etc. Only one is active at a time.

**To switch scenes**, emit the signal — never load scenes directly:
```gdscript
G.request_core_scene.emit(G.CoreScene.GAME)
```

**To add a new core scene:**
1. Add a value to `G.CoreScene`
2. Add its path to `G.CoreScenePath`
3. Set the starting scene per build profile in the `GameManager` inspector

**To react when a scene finishes loading:**
```gdscript
G.new_core_scene_loaded.connect(_on_scene_loaded)
```

---

## Pause System

Pause is **ownership-based** — multiple systems can request pause simultaneously, and the game only unpauses when all requests are cleared. This prevents race conditions between overlapping pause sources.

```gdscript
G.request_pause(self, true)   # request pause
G.request_pause(self, false)  # release your request
```

Pause state resets automatically on every scene change — no manual cleanup needed.

```gdscript
G.pause_state_changed.connect(_on_pause_changed)
```

---

## Settings

Stored as a flat dictionary keyed by `G.Setting` enum values, persisted to disk automatically.

```gdscript
# Read
var vol : float = G.settings[G.Setting.MUSIC_VOLUME]

# Write (applies immediately and saves to disk)
G.adjust_setting(G.Setting.MUSIC_VOLUME, -20.0)

# Display string for UI
G.get_setting_text(G.Setting.FULLSCREEN_MODE)  # → "Fullscreen Mode"
```

| Setting           | Type       | Range / Notes                  |
|-------------------|------------|--------------------------------|
| `MUSIC_VOLUME`    | float      | dB, 0 = full, -80 = muted      |
| `SFX_VOLUME`      | float      | dB, same as above              |
| `UI_VOLUME`       | float      | dB, same as above              |
| `AMBIENT_VOLUME`  | float      | dB, same as above              |
| `BRIGHTNESS`      | float      | 0.0 – 2.0, default 1.0         |
| `CONTRAST`        | float      | 0.0 – 2.0, default 1.0         |
| `SATURATION`      | float      | 0.0 – 2.0, default 1.0         |
| `FULLSCREEN_MODE` | bool       | true = fullscreen              |
| `INPUT_BINDINGS`  | Dictionary | Managed by InputService (I)    |

---

## Save System

Game data lives in `G.data`, mirroring `G.DEFAULT_DATA`. All save/load operations are encrypted.

```gdscript
# Create a new save
var path : String = G.create_save_file("my_save")

# Save current state (async — must await)
var ok : bool = await G.save_data(path)

# Load a save
var file_data : Array = G.load_data(path)
# file_data[0] = data dictionary, file_data[1] = thumbnail texture

# List existing saves
var paths : Array = G.list_save_files()

# Log a gameplay event (no duplicates)
G.log_event("discovered_cave")
```

Listen for data readiness before accessing `G.data`:
```gdscript
G.data_is_ready.connect(_on_data_ready)
if G.is_data_ready: ...
```

---

## Localization

```gdscript
G.set_locale("fr")
G.get_available_locales()       # → PackedStringArray
G.locale_changed.connect(...)   # fires on language change
```

Use `tr("STRING_KEY")` anywhere for translated text.

---

## Utility Methods

```gdscript
G.round_to_dec(3.14159, 2)        # → 3.14
G.sanitize_string("my save!")     # → "my save"
G.is_input_string_valid("hello")  # → true
G.generate_points_in_circle(...)  # → PackedVector2Array
```
