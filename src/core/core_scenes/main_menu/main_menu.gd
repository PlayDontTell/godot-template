extends BaseMenuController

enum State {
	MAIN,
	SETTINGS,
	CREDITS,
	EXIT_DIALOG,
	SAVE_SELECTION,
}

@onready var panel_main:        Control = %TitleScreen
@onready var panel_settings:    Control = $SettingsScreen
@onready var panel_credits:     Control = $CreditsScreen
@onready var panel_exit_dialog: Control = $ExitDialog
@onready var panel_save_selection: Control = $SaveSelectionScreen

@export var initial_state : State = State.MAIN


func _ready() -> void:
	_panels = {
		State.MAIN: panel_main,
		State.SETTINGS: panel_settings,
		State.CREDITS: panel_credits,
		State.EXIT_DIALOG: panel_exit_dialog,
		State.SAVE_SELECTION: panel_save_selection,
	}
	_initial_state = initial_state

	panel_main.play_requested.connect(go_to.bind(State.SAVE_SELECTION))
	panel_main.settings_requested.connect(go_to.bind(State.SETTINGS))
	panel_main.credits_requested.connect(go_to.bind(State.CREDITS))
	panel_main.exit_dialog_requested.connect(go_to.bind(State.EXIT_DIALOG))

	panel_settings.back_requested.connect(go_back)
	
	panel_save_selection.back_requested.connect(go_back)
	
	panel_credits.back_requested.connect(go_back)
	panel_exit_dialog.cancel_requested.connect(go_back)
	panel_exit_dialog.exit_game_requested.connect(get_tree().quit)

	super._ready()  # always last — triggers go_to(_initial_state)


func _input(event: InputEvent) -> void:
	if I.just_pressed("cancel", event):
		go_back()
