# GameManager

The root node of the game scene tree. It owns the `WorldEnvironment`, manages scene loading, and wires up the core signals that drive the application lifecycle.

There is only one GameManager and it never changes at runtime. It is not an autoload — it is a persistent scene node.

---

## What it does

- Listens for `G.request_core_scene` and performs the actual scene load
- Shows a loading screen while scenes load in a background thread
- Restarts the game cleanly when `G.request_game_restart` fires (used by ExpoLayer)
- Routes visual environment signals (`adjust_brightness` etc.) to the `WorldEnvironment`
- Prevents the OS from auto-closing the window (handles quit manually via `_notification`)

---

## Inspector options

| Export                  | Default     | Effect                                          |
|-------------------------|-------------|-------------------------------------------------|
| `auto_start_game`       | `true`      | Whether to load a start scene on launch         |
| `DEV_build_profile`     | `MAIN_MENU` | First scene loaded in DEV builds                |
| `RELEASE_build_profile` | `MAIN_MENU` | First scene loaded in RELEASE builds            |
| `EXPO_build_profile`    | `MAIN_MENU` | First scene loaded in EXPO builds               |

The starting scene per build profile is set here in the inspector — not in code.

---

## Scene loading

All scene changes go through `G.request_core_scene`. GameManager intercepts this signal and handles loading safely:

1. Clears existing game scenes (except `DebugLayer` and `ExpoLayer`)
2. Resets pause state
3. Shows the `LOADING` core scene as an overlay
4. Loads the target scene on a background thread
5. Swaps to the new scene and emits `G.new_core_scene_loaded`

A second `request_core_scene` call while loading is already in progress is silently ignored.

The `LOADING` scene must implement a `set_progress(value: float)` method to receive progress updates, where `value` goes from `0.0` to `1.0`.

---

## Restarting

`restart_game()` is called both on first launch and when `G.request_game_restart` fires. It calls `C.reset_variables()` and `G.reset_variables()` to clear runtime state, then loads the starting scene for the current build profile. You can call it manually to perform a full soft restart without quitting the application.

---

## Exceptions

`DebugLayer` and `ExpoLayer` are never cleared during scene transitions — they persist across all scene changes by name. If you rename either node, update the `EXCEPTIONS` array in `clear_game_scenes()`.
