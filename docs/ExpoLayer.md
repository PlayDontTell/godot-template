# ExpoLayer

A CanvasLayer designed for convention booth deployments. It owns all expo logic — idle tracking, countdown display, and game restart. Nothing outside this node needs to know about the expo timer.

It is **safe to delete** if you're not building for an expo. Remove the node from the scene and delete the script. No other script depends on it.

---

## How it works

1. Any player input resets the internal `expo_timer` (detected directly in `_input`)
2. `_physics_process` increments the timer while the booth session is active
3. At `EXPO_CRITICAL_TIME`, the warning panel appears with a pulsing "press any key" label
4. At `EXPO_MAX_IDLE_TIME`, `G.request_game_restart` fires and the timer resets

This only runs in the `EXPO` build profile. In any other profile, ExpoLayer frees itself on `_ready`.

---

## Inspector options

Set these on the node in the Godot editor:

| Export                  | Default           | Effect                                               |
|-------------------------|-------------------|------------------------------------------------------|
| `EXPO_EVENT_NAME`       | `CITY-EVENT-YEAR` | Used for file naming, sanitized automatically        |
| `is_expo_timer_enabled` | `true`            | Can be toggled at runtime with `toggle_Expo_timer`   |
| `EXPO_MAX_IDLE_TIME`    | `150.0`           | Seconds of inactivity before restart                 |
| `EXPO_CRITICAL_TIME`    | `120.0`           | Seconds before the warning panel appears             |

---

## Runtime toggle

The expo timer can be paused at runtime (useful for demo staff) with the `toggle_Expo_timer` input action, defined in the Input Map. A visual indicator appears on screen when the timer is disabled.

---

## Internal state

All expo state lives inside ExpoLayer — nothing is stored in `G`:

- `expo_timer` — current idle time in seconds
- `is_expo_timer_critical` — whether the warning panel is currently shown
- `is_booth_session_active` — whether the timer is currently counting

These are not meant to be read from outside. React to `G.request_game_restart` if you need to know when a restart happens.
