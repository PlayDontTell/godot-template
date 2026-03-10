extends GameManager


func _setup_game() -> void:
	# Defining the Intents (intent-name: [events])
	# - Intent names should reflect concrete player actions and intents
	# - Events are listed in Project > Project Settings > Input Map
	InputManager.register_intents({
		#"move_up":    ["move_up", "ui_up"],
	})
	# Defining the Contexts (context: [intents])
	# List what Intents are allowed in this context.
	InputManager.extend_context(
		InputManager.Context.GAMEPLAY,
		[
			#"move_up",
		],
	)


func _reset_variables() -> void:
	pass
