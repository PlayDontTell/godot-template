# DeviceTracker (D)

Tracks *how* the player is providing input — keyboard, gamepad, or touch. It does not handle what the player intends (that's InputService). It answers one question: what device is the player currently using?

This is useful for adapting your UI — showing keyboard icons vs gamepad icons, hiding the cursor when a gamepad is active, or knowing whether a player has ever touched both input methods.

---

## What it tracks

`D.last_input_method` is **sticky** — it reflects the most recently used device and never resets to `NONE` after first input. Use it to drive UI icon swaps or layout changes.

```gdscript
match D.last_input_method:
    D.InputMethod.KEYBOARD_AND_MOUSE:
        show_keyboard_icons()
    D.InputMethod.GAMEPAD:
        show_gamepad_icons()
    D.InputMethod.TOUCH:
        show_touch_icons()
```

---

## Signals

Listen to these rather than polling `last_input_method` every frame:

```gdscript
# Input method switched (e.g. player picked up a gamepad mid-game)
D.method_changed.connect(_on_method_changed)

# A gamepad was plugged in — device_id is what you pass to I for gamepad input
D.gamepad_connected.connect(_on_gamepad_connected)
D.gamepad_disconnected.connect(_on_gamepad_disconnected)
```

The `device_id` from `gamepad_connected` is what you pass to `I.just_pressed()` and `I.get_move_vector()` to route input to the right player.

---

## Public API

```gdscript
D.get_current_method()       # → InputMethod (same as last_input_method)
D.is_gamepad_active()        # true if gamepad was used in the last 0.1s
D.is_keyboard_active()       # true if keyboard/mouse was used in the last 0.1s
D.has_used_both()            # true if player has used both keyboard and gamepad
D.seconds_since_gamepad()    # float, INF if never used
D.seconds_since_keyboard()   # float, INF if never used
```

---

## Cursor visibility

D automatically hides the mouse cursor when a gamepad or touch input is detected, and shows it again on keyboard/mouse. This is handled internally via `show_cursor()` connected to `method_changed` — you don't need to manage it manually.
