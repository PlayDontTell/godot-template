# InputService (I)

The single authority for all input. Gameplay code never calls Godot's `Input` directly — I resolves what the player *intends* and whether that intent is currently valid.

This gives you device-agnostic gameplay code, safe modal input filtering, and rebinding, all in one place.

---

## Intents — what is the player trying to do?

An **intent** is a named semantic action: `"confirm"`, `"move_up"`, `"pause"`. It represents what the player *means*, not which key they pressed. Each intent maps to one or more Input Map actions under the hood.

This means: changing a keybind, adding gamepad support, or adding a fallback key never touches gameplay code.

```gdscript
I.just_pressed("confirm")   # true for one frame
I.pressed("cancel")         # true while held
I.just_released("pause")    # true on the release frame
I.get_move_vector()         # normalized Vector2, context-aware
```

For gamepad players, pass their device ID — received from `DT.gamepad_connected`:
```gdscript
I.just_pressed("confirm", device_id)
I.get_move_vector(device_id)
```

To add an intent, add one entry to `INTENTS` at the top of the script.

---

## Contexts — what input is valid right now?

A **context** restricts which intents are active at a given moment. When a pause menu opens, it acquires the PAUSE context — and from that point, movement intents silently return `false` without the player node knowing anything changed.

Only the **highest-priority** context is consulted. Lower contexts are fully silent — there is no passthrough.

Contexts are tied to the lifetime of a node. When that node is freed, its context disappears automatically. You never need to manually reset anything.

```gdscript
var _ctx : I.ContextHandle

func _ready() -> void:
    # Priority 100 beats GAMEPLAY (priority 0), so this context wins
    _ctx = I.acquire_context(I.Context.PAUSE, self, 100)

func _exit_tree() -> void:
    I.release_context(_ctx)  # optional — freeing the node is enough
```

| Context    | Suggested priority | Allowed intents                      |
|------------|--------------------|--------------------------------------|
| `GAMEPLAY` | 0 (default)        | all                                  |
| `PAUSE`    | 100                | confirm, cancel, move_up, move_down  |
| `DIALOGUE` | 200                | confirm                              |

To add a context: add a value to `Context`, add a row to `CONTEXT_RULES`.  
⚠ Two contexts at the same priority have undefined resolution order.

---

## Rebinding

```gdscript
# Display the current binding in a label
var ev := I.get_binding("move_up")
label.text = ev.as_text() if ev else "Unbound"

# Capture and apply a new binding (from _input)
func _input(event : InputEvent) -> void:
    if event is InputEventKey or event is InputEventJoypadButton:
        I.rebind("move_up", event)
        set_process_input(false)

# Restore all defaults
I.reset_bindings()
```

Bindings persist through `G.settings[G.Setting.INPUT_BINDINGS]`.  
`I.load_bindings()` is called automatically in `G._ready()` after settings are loaded.
