# 🥔 patate
**A Godot 4.6 game template by [Play Don't Tell](https://github.com/PlayDontTell)**

Patate is a modular, community-maintained starting point for Godot projects.  
Like a potato, it's versatile, unpretentious, and works in almost any recipe.

Its philosophy: **ship early, share confidently, work openly** — with developers, artists, designers, and players alike, regardless of whether they open a game engine.

---

## What you can do with it

#### Start a new project in minutes
Open `game_manager.tscn` — the root scene — and configure everything from the inspector via its `config` export variable: which scenes to load per build profile, save paths, encryption key, and startup behaviour. No code needed to get a game booting.

#### Ship to any audience, on day one
Patate has distinct build profiles baked in. Run `DEV` on your machine, hand a `PLAYTEST` build to testers, set up an `EXPO` booth at a convention, and cut a `RELEASE` — all from the same codebase, with behaviour that adapts automatically.

#### Present your game anywhere, confidently
The **Expo layer** handles idle detection and automatic session resets for public booths — no babysitting required. Pair it with the **Debug layer** to monitor performance live during playtests without shipping it to players.

#### Let anyone contribute, not just programmers
The asset folder is structured so that artists, sound designers, and writers can drop files in the right place without guidance. Kenney asset packs ([board-game-icons](https://kenney.nl/assets/board-game-icons), [crosshair-pack](https://kenney.nl/assets/crosshair-pack), [cursor-pack](https://kenney.nl/assets/cursor-pack), [game-icons](https://kenney.nl/assets/game-icons), [input-prompts](https://kenney.nl/assets/input-prompts)) are included as a ready-to-use placeholder library.

#### Support keyboard, gamepad, touch, and mouse — without extra work
The input system tracks the active device and adapts UI focus and cursor visibility automatically. Adding a new gameplay action means registering one intent — not hunting for every `Input.is_action_pressed` call in the codebase.

#### Localize your game
String handling is wired to Godot's `TranslationServer` from the start. Add a CSV file, and call `LocaleManager.set_locale("fr")`. See [Godot's localization documentation](https://docs.godotengine.org/en/stable/tutorials/i18n/internationalizing_games.html) for the full workflow. For managing translation files outside Godot, [Poedit](https://poedit.net/) is a solid option for PO files, or any spreadsheet editor works for CSV-based workflows.

#### Save and load without boilerplate
The save system handles encryption, atomic writes (no corruption on crash), and forward-compatible schema migration out of the box.

---

## Project structure

```
patate/
├── addons/
│   └── patate/                 # Template core — don't edit for game-specific code
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
├── src/
│   ├── core/
│   │   ├── autoloads/          # Your game-specific autoloads
│   │   └── core_scenes/        # Loading screen, main menu, settings, credits
│   ├── classes/                # Your game-specific classes
│   ├── scenes/                 # Your game scenes (levels, characters, HUD)
│   ├── scripts/
│   └── shaders/
├── docs/                       # Your game documentation, guides, notes
├── exports/                    # Per-platform export folders
├── tools/                      # Dev tools (level editors, optimization scripts, etc.)
└── wip/                        # Gitignored scratch space
```

`addons/` uses a gitignore exception so that `addons/patate/` is tracked while third-party plugins are not. Install plugins via the [Godot AssetLib](https://docs.godotengine.org/en/stable/community/asset_library/using_assetlib.html) — they'll be gitignored automatically.

---

## How it works

#### The starting scene: `game_manager.tscn`
`game_manager.tscn` is the root scene of the project. It owns the threaded scene loader and a `persistent_nodes` export array — any node listed there survives core scene changes. `DevLayer` and `ExpoLayer` are listed by default; add or remove entries to suit your project. Select the root node and edit its `config` export variable to configure `project_config.tres` directly from the inspector.

#### Autoloads

| Autoload | Role |
|---|---|
| `G` | Global hub: build profile checks, core scene signals, project config reference |
| `InputManager` | Intent-based input: intent checks, context filtering, runtime rebinding |
| `DeviceManager` | Device tracking: active input method, cursor visibility, gamepad detection |
| `SaveManager` | Save system: encrypted file I/O, schema migration, save listing and archiving |
| `SettingsManager` | Player settings: audio, video, resolution — saved as a human-editable `.cfg` file |
| `PauseManager` | Pause request stack: any node can request pause, last one out unpauses |
| `LocaleManager` | Localization: locale switching via `TranslationServer` |
| `Utils` | Static helpers: math, string sanitization, geometry |

These names are consistent across all Patate-based projects so developers can switch between them without relearning the API.

#### Build profiles

| Profile | Intended for |
|---|---|
| `DEV` | Daily development — the default state of the template. Debug layer visible, all tools available. |
| `PLAYTEST` | Controlled testing sessions — hand builds to testers, QA, or friends for bug tracking and feedback. |
| `EXPO` | Convention booths and public demos — idle timer, automatic session reset, per-event configuration. |
| `RELEASE` | Public distribution — clean builds for players. |

Profile is set once in `project_config.tres` before exporting. The game adapts its behaviour automatically — no `if` statements scattered across your codebase. Check the current profile with `G.is_dev()`, `G.is_expo()`, etc.

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

Core intents (confirm, cancel, pause, dev toggles) are built into the template. Register your game-specific intents at startup:

```gdscript
InputManager.register_intents({
    "attack":    ["attack"],
    "interact":  ["interact"],
    "move_up":   ["move_up", "ui_up"],
})
```

**Contexts** restrict which intents are active at any given moment. A `DIALOGUE` context silently blocks movement without any node needing to check — the InputManager handles it. Extend existing contexts with your game intents:

```gdscript
InputManager.extend_context(InputManager.Context.GAMEPLAY, [
    "attack", "interact", "move_up", "move_down",
])
```

#### Core scenes
Scenes are registered in `project_config.tres` as a `Dictionary[StringName, PackedScene]`. The template defines `G.LOADING` and `G.MAIN_MENU` — add your own freely:

```gdscript
# From anywhere in the project
G.request_core_scene.emit(&"GAME")
```

#### Menu system
`BaseMenu` and `BaseMenuController` handle panel visibility, focus memory, input context acquisition, and device-aware focus (mouse releases focus; gamepad restores it). Extend them for any screen that needs navigation history.

#### Save system
Saves are encrypted with a key set in `project_config.tres`. Writes go through a temp file first — if the game crashes mid-save, the previous file stays intact. Schema migration runs automatically on load, filling in any new properties you've added to `SaveData` since the save was created.

```gdscript
# Create a new save
SaveManager.create_save_file("my_save")

# Access current save data
SaveManager.save_data.time_played

# List all saves
SaveManager.list_save_files()
```

Player settings (audio, video, resolution) are saved separately as a human-readable `.cfg` file in `user://bin/`, editable outside the game.

---

## Getting started

1. Use this repo as a GitHub template or clone it.
2. Open in Godot 4.6+.
3. Open `game_manager.tscn`, select the root node, and edit the `config` export variable in the inspector.
4. Add your scenes to the `core_scenes` dictionary and set your start scene per build profile.
5. Register your game intents and context extensions in your startup script.
6. Build your game in `src/` — everything in `addons/patate/` is template infrastructure.

---

## Testing

Patate does not bundle a test framework. [GUT (Godot Unit Test)](https://gut.readthedocs.io/) is the recommended option — install it via [AssetLib](https://docs.godotengine.org/en/stable/community/asset_library/using_assetlib.html). A setup guide is included at `docs/tests_using_GUT.md`.

---

## Contributing

Patate is maintained by Play Don't Tell and open to contributions. Keep systems modular, prefer clarity over cleverness, and document the reasoning behind any change that affects autoload APIs or config structure.

---

## License

GNU GPLv3 — see `LICENSE`.  
Made with 🥔 by [Play Don't Tell](https://github.com/PlayDontTell).
