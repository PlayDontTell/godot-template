# 🥔 patate
**A Godot 4.6 game template by [Play Don't Tell](https://github.com/PlayDontTell)**

Patate is a modular, community-maintained starting point for Godot projects.  
Like a potato, it's versatile, unpretentious, and works in almost any recipe.

Its philosophy: **ship early, share openly, work together** — with developers, artists, designers, and players alike.

---

## What it does

#### Quick setup
Open `game_manager.tscn` — the root scene — and configure everything from the inspector via its `config` export variable: scenes per release mode, save paths, encryption key, startup behaviour. No code needed to get a game booting.

#### Release modes
`DEV`, `PLAYTEST`, `EXPO`, `RELEASE` — same codebase, different behaviour per audience. The **Expo layer** handles idle detection and automatic session resets for public booths. The **Debug layer** shows performance info during development and playtests.

#### Structured asset folder
Artists, sound designers, and writers can drop files in the right place without guidance. Kenney asset packs ([board-game-icons](https://kenney.nl/assets/board-game-icons), [crosshair-pack](https://kenney.nl/assets/crosshair-pack), [cursor-pack](https://kenney.nl/assets/cursor-pack), [game-icons](https://kenney.nl/assets/game-icons), [input-prompts](https://kenney.nl/assets/input-prompts)) are included as placeholder assets.

#### Multi-input support
The input system tracks the active device and adapts UI focus and cursor visibility automatically. Adding a new gameplay action means registering one intent, not hunting for every `Input.is_action_pressed` call.

#### Localization
String handling is wired to Godot's `TranslationServer` from the start. Add a CSV file and call `LocaleManager.set_locale("fr")`. See [Godot's localization docs](https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html) for the full workflow.

#### Save system
Encryption, atomic writes (no corruption on crash), and forward-compatible schema migration out of the box.

---

## Project structure

```
patate/
├── addons/
│   └── patate/                 # Template core — update across projects without changes
│       ├── autoloads/          # G, DeviceManager, InputManager, SaveManager, etc.
│       ├── classes/            # SaveData, GameSettings, ProjectConfig, ExpoEventConfig
│       ├── resources/          # Shared resource files (.tres)
│       └── scenes/             # game_manager.tscn and profile layers (dev, expo)
├── assets/
│   ├── art/                    # characters, levels, props, tilesets, ui
│   ├── audio/                  # atmospheres, dialogue, music, sfx, ui_sfx
│   ├── fonts/
│   ├── bitfonts/
│   ├── texts/                  # Localization CSV files
│   └── themes/                 # Godot UI themes (debug, default)
├── src/                        # Your game code — customize freely
│   ├── core/
│   │   ├── autoloads/          # Game-specific autoloads
│   │   └── core_scenes/        # Loading screen, main menu, settings, credits
│   ├── classes/                # Game-specific classes
│   ├── scenes/                 # Game scenes (levels, characters, HUD)
│   ├── scripts/
│   └── shaders/
├── docs/
├── exports/                    # Per-platform export folders
├── tools/                      # Dev tools (level editors, optimization scripts, etc.)
└── wip/                        # Gitignored scratch space
```

`addons/patate/` is template infrastructure — it should be replaceable across projects without touching game code. `src/` is yours. `addons/` uses a gitignore exception so that `addons/patate/` is tracked while third-party plugins are not.

---

## How it works

#### `game_manager.tscn`
The root scene. It owns the threaded scene loader and a `persistent_nodes` export array — any node listed there survives core scene changes. `DevLayer` and `ExpoLayer` are listed by default; add or remove entries to suit your project. Select the root node and edit its `config` export to configure `project_config.tres` from the inspector.

#### Autoloads

| Autoload | Role |
|---|---|
| `G` | Global hub: release mode checks, core scene signals, project config reference |
| `InputManager` | Intent-based input: intent checks, context filtering, runtime rebinding |
| `DeviceManager` | Device tracking: active input method, cursor visibility, gamepad detection |
| `SaveManager` | Save system: encrypted file I/O, schema migration, save listing and archiving |
| `SettingsManager` | Player settings: audio, video, resolution — saved as a human-editable `.cfg` file |
| `PauseManager` | Pause request stack: any node can request pause, last one out unpauses |
| `LocaleManager` | Localization: locale switching via `TranslationServer` |
| `Utils` | Static helpers: math, string sanitization, geometry |

#### Release modes

| Mode | Intended for |
|---|---|
| `DEV` | Daily development. Debug layer visible, all tools available. |
| `PLAYTEST` | Controlled testing sessions with testers, QA, or friends. |
| `EXPO` | Convention booths and public demos — idle timer, auto session reset. |
| `RELEASE` | Public distribution. |

Set once in `project_config.tres` before exporting. Check at runtime with `G.is_dev()`, `G.is_expo()`, etc.

#### Intent-based input
Gameplay code reads **intents** — semantic action names — never raw Godot Input Map actions:

```gdscript
# Polling — from _process()
if InputManager.just_pressed("confirm"):
	do_thing()

# Event-driven — from _input(event), with optional device filter
if InputManager.just_pressed("confirm", event, device_id):
	do_thing()
```

Core intents (confirm, cancel, pause, dev toggles) are built in. Register game-specific intents at startup:

```gdscript
InputManager.register_intents({
	"attack":    ["attack"],
	"interact":  ["interact"],
	"move_up":   ["move_up", "ui_up"],
})
```

**Contexts** restrict which intents are active at any given moment. A `DIALOGUE` context silently blocks movement without any node needing to check. Extend existing contexts with your game intents:

```gdscript
InputManager.extend_context(InputManager.Context.GAMEPLAY, [
	"attack", "interact", "move_up", "move_down",
])
```

#### Core scenes
Registered in `project_config.tres` as a `Dictionary[StringName, PackedScene]`. The template ships with `G.LOADING` and `G.MAIN_MENU`. Add your own:

```gdscript
G.request_core_scene.emit(&"GAME")
```

#### Menu system
`BaseMenu` and `BaseMenuController` handle panel visibility, focus memory, input context acquisition, and device-aware focus (mouse releases focus; gamepad restores it). Extend them for any screen that needs navigation history.

#### Save system
Saves are encrypted with a key from `project_config.tres`. Writes go through a temp file first — if the game crashes mid-save, the previous file stays intact. Schema migration runs on load, filling in new properties added to `SaveData` since the save was created.

```gdscript
SaveManager.create_save_file("my_save")
SaveManager.save_data.time_played
SaveManager.list_save_files()
```

Player settings (audio, video, resolution) are saved separately as a `.cfg` file in `user://bin/`, editable outside the game.

---

## Getting started

1. Use this repo as a GitHub template or clone it.
2. Open in Godot 4.6+.
3. Open `game_manager.tscn`, select the root node, and edit the `config` export in the inspector.
4. Add your scenes to the `core_scenes` dictionary and set your start scene per release mode.
5. Register your game intents and context extensions in your startup script.
6. Build your game in `src/` — everything in `addons/patate/` is template infrastructure.

---

## Testing

Patate does not bundle a test framework. [GUT (Godot Unit Test)](https://gut.readthedocs.io/) is recommended — install it via [AssetLib](https://docs.godotengine.org/en/stable/community/asset_library/using_assetlib.html). A setup guide is at `docs/tests_using_GUT.md`.

---

## Contributing

Patate is maintained by Play Don't Tell and open to contributions. Keep systems modular, prefer clarity over cleverness, and document the reasoning behind any change that affects autoload APIs or config structure.

---

## License

GNU GPLv3 — see `LICENSE`.  
Made with 🥔 by [Play Don't Tell](https://github.com/PlayDontTell).
