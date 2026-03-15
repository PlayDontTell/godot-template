extends BaseMenuController

enum State {
	MAIN,
	SETTINGS,
	CREDITS,
	EXIT_DIALOG,
	SAVE_FILE_SELECTION,
	SAVE_SLOT_SELECTION,
	SAVE_SLOT_CREATION,
}

@onready var panel_main:        Control = %TitleScreen
@onready var panel_settings:    Control = $SettingsScreen
@onready var panel_credits:     Control = $CreditsScreen
@onready var panel_exit_dialog: Control = $ExitDialog
@onready var panel_save_file_selection: Control = $SaveFileSelectionScreen
@onready var panel_save_slot_selection: Control = $SaveSlotSelectionScreen
@onready var panel_save_slot_creation: Control = $SaveSlotCreationScreen

@export var initial_state : State = State.MAIN


func _ready() -> void:
	# Making sure the current Save is unloaded while being in the main menu.
	# So that player cannot create new save files under a save slot by mistake
	SaveManager.unload()
	
	SaveManager.save_file_deleted.connect(update_save_info)
	SaveManager.save_slot_selected.connect(update_save_lists)
	update_save_info()
	
	_panels = {
		State.MAIN: panel_main,
		State.SETTINGS: panel_settings,
		State.CREDITS: panel_credits,
		State.EXIT_DIALOG: panel_exit_dialog,
		State.SAVE_FILE_SELECTION: panel_save_file_selection,
		State.SAVE_SLOT_SELECTION: panel_save_slot_selection,
		State.SAVE_SLOT_CREATION: panel_save_slot_creation,
	}
	_initial_state = initial_state
	
	if G.config.has_save_slots:
		panel_main.play_requested.connect(go_to.bind(State.SAVE_SLOT_SELECTION))
	else:
		panel_main.play_requested.connect(_on_save_slot_selected)
	
	panel_main.settings_requested.connect(go_to.bind(State.SETTINGS))
	panel_main.credits_requested.connect(go_to.bind(State.CREDITS))
	panel_main.exit_dialog_requested.connect(go_to.bind(State.EXIT_DIALOG))

	panel_settings.back_requested.connect(go_back)
	
	panel_save_file_selection.back_requested.connect(go_back)
	
	panel_save_slot_selection.back_requested.connect(go_back)
	panel_save_slot_selection.save_slot_selected.connect(_on_save_slot_selected)
	
	panel_save_slot_creation.back_requested.connect(go_back)
	
	panel_credits.back_requested.connect(go_back)
	panel_exit_dialog.outcome_received.connect(
		func(confirmed: bool):
			if confirmed:
				get_tree().quit()
			else:
				go_back()
	)
	
	panel_exit_dialog.format_dict = {"game_name": ProjectSettings.get_setting("application/config/name")}
	panel_exit_dialog.refresh()
	
	super._ready()  # always last — triggers go_to(_initial_state)


func _input(event: InputEvent) -> void:
	if InputManager.just_pressed_event("ui_cancel", event):
		go_back()


func update_save_info() -> void:
	SaveManager.list_save_data()
	update_save_lists()


func update_save_lists() -> void:
	panel_save_file_selection.update()
	panel_save_slot_selection.update()


## Called when a save slot is selected (or immediately if has_save_slots is false).
## Routes the player to the appropriate next step based on the save system configuration:
##   - Show save file selection (if multiple saves exist and manual saving is enabled)
##   - Load the most recent save and start the game (if only one save or no manual saving)
##   - Show slot setup screen (if the slot is empty and needs configuration)
##   - Create a new save and start the game (if the slot is empty and needs no setup)
func _on_save_slot_selected() -> void:
	var has_save_slots : bool = G.config.has_save_slots
	var manual_loading_enabled : bool = G.config.manual_loading_enabled
	var save_slots_need_setup : bool = G.config.save_slots_need_setup
	var has_saves_in_slot : bool = false
	if SaveManager.save_data_list.has(SaveManager.current_save_slot):
		has_saves_in_slot = SaveManager.save_data_list[SaveManager.current_save_slot].size() > 0
	
	if has_saves_in_slot:
		# The selected slot already has save files.
		
		var has_only_one_save_available : bool = SaveManager.save_data_list[SaveManager.current_save_slot].size() == 1
		var a_save_is_loaded : bool = not SaveManager.save_data._is_empty
		# The player can create new save files if:
		# - there are no save slots (flat list mode — always allowed), or
		# - a save is already loaded (the player is resuming, not starting fresh)
		var player_can_create_new_files : bool = not has_save_slots or a_save_is_loaded
		
		if manual_loading_enabled and (not has_only_one_save_available or player_can_create_new_files):
			# Multiple saves to choose from, or the player can create new ones.
			# Show the file selection screen so they can pick, delete, or create saves.
			go_to(State.SAVE_FILE_SELECTION)
		else:
			# Either manual saving is off, or there's exactly one save and no ability
			# to create more — just load the most recent file and start playing.
			SaveManager.load_save_file(SaveManager.save_data_list[SaveManager.current_save_slot][0].file_path)
			G.request_core_scene.emit(&"GAME")
	
	else:
		# The selected slot is empty — no save files exist yet.
		
		if save_slots_need_setup and has_save_slots:
			# The slot requires player configuration before first use
			# (e.g. naming the slot, choosing difficulty, setting a seed).
			go_to(State.SAVE_SLOT_CREATION)
		else:
			# No setup needed — create a fresh save file and start the game immediately.
			await SaveManager.create_new_save()
			G.request_core_scene.emit(&"GAME")
