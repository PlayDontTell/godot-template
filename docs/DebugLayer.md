# DebugLayer

A CanvasLayer that displays live game stats in an overlay panel. It exists to help during development — it is not part of the game itself.

It is **safe to delete** if you don't need it. Nothing else depends on it. Remove the node from the scene and delete the script.

---

## When it appears

DebugLayer stays alive only in `DEV` and `EXPO` build profiles. In any other profile, it frees itself on `_ready`. In `DEV`, it is hidden by default and toggled with the `toggle_Dev_layer` input action (bound in the Input Map). The toggle is handled internally in `_input` — no signal from `G` is needed.

---

## What it shows

The panel is split into tabs, each togglable independently:

| Tab           | Contents                                       |
|---------------|------------------------------------------------|
| Time          | FPS, time since start, time played, delta      |
| Costs         | Memory usage, node count, active tweens        |
| Machine       | OS, machine model, window and viewport sizes   |
| Game State    | Build profile, version, locale, current scene  |
| Input/Output  | Mouse position                                 |
| Pause         | Pause state, number of pause requesters        |

---

## Inspector options

| Export                | Default    | Effect                                       |
|-----------------------|------------|----------------------------------------------|
| `expanded_on_start`   | `true`     | Whether the panel opens expanded             |
| `position_on_start`   | `TOP_LEFT` | Which corner the panel anchors to            |
| `info_refresh_period` | `2.0`      | How often slow stats (memory, nodes) refresh |
| `active_tabs_on_start`| all on     | Which tabs are visible on launch             |

---

## Pause control

The panel includes a Pause/Resume button that calls `G.request_pause()`. It participates in the normal pause system and won't conflict with other pause requesters.

---

## Adding your own stats

Add a `Label` node inside `%DebugContainer` in the scene, then update it in `_process` or connect it to a signal. Follow the pattern of any existing label setter (e.g. `set_fps_label`).
