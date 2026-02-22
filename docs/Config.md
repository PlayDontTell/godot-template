# Config (C)

A stub autoload for game-specific constants and variables that:
- define game state or conventions used across multiple scripts
- do **not** need to be saved to disk (those belong in `G.data`)
- do **not** belong in `G.gd` because they are specific to this game rather than the framework

`G.gd` is framework-level infrastructure. `C.gd` is your game.

---

## How to use it

Add constants, enums, and variables here as your game grows. Reset any runtime state in `reset_variables()`, which is called by `GameManager` on every game restart.

```gdscript
# Example additions to Config.gd:
const MAX_LEVEL : int = 10
const PLAYER_SPEED : float = 200.0

enum EnemyType { BASIC, RANGED, BOSS }

var current_level : int = 0

func reset_variables() -> void:
	current_level = 0
```

Then anywhere in the project:
```gdscript
if C.current_level >= C.MAX_LEVEL:
	trigger_ending()
```

---

## What not to put here

- Data that should survive a game restart → `G.data`
- Settings the player can change → `G.settings`
- Infrastructure shared across all projects → `G.gd`
