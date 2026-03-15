extends BaseMenuController

enum State {
	MAIN,
	SETTINGS,
	RETURN_TO_MAIN_MENU_DIALOG,
	SAVE_AND_EXIT_DIALOG,
	SAVE_FILE_SELECTION,
}

@onready var panel_main:        Control = $PauseScreen
@onready var panel_settings:    Control = $SettingsScreen
@onready var return_to_main_menu_dialog: 	Control = $ReturnToMainMenuDialog
@onready var save_and_exit_dialog: 			Control = $SaveAndExitDialog
@onready var save_file_selection_screen: 	Control = $SaveFileSelectionScreen

@export var initial_state : State = State.MAIN


func _ready() -> void:
	SaveManager.save_file_deleted.connect(update_save_info)
	update_save_info()
	
	_panels = {
		State.MAIN: panel_main,
		State.SETTINGS: panel_settings,
		State.RETURN_TO_MAIN_MENU_DIALOG: return_to_main_menu_dialog,
		State.SAVE_AND_EXIT_DIALOG: save_and_exit_dialog,
		State.SAVE_FILE_SELECTION: save_file_selection_screen,
	}
	_initial_state = initial_state
	
	panel_main.resume_requested.connect(close)
	panel_main.settings_requested.connect(go_to.bind(State.SETTINGS))
	panel_main.main_menu_requested.connect(go_to.bind(State.RETURN_TO_MAIN_MENU_DIALOG))
	panel_main.exit_dialog_requested.connect(go_to.bind(State.SAVE_AND_EXIT_DIALOG))
	panel_main.save_requested.connect(handle_save_request)
	panel_main.load_requested.connect(handle_load_request)

	panel_settings.back_requested.connect(go_back)
	
	return_to_main_menu_dialog.outcome_received.connect(
		func(confirmed: bool):
			if confirmed:
				handle_main_menu_request()
			else:
				go_back()
	)
	
	save_file_selection_screen.back_requested.connect(go_back)
	save_file_selection_screen.save_completed.connect(close)
	
	save_and_exit_dialog.outcome_received.connect(
		func(confirmed: bool):
			if confirmed:
				handle_exit_request()
			else:
				go_back()
	)
	
	save_and_exit_dialog.format_dict = {"game_name": ProjectSettings.get_setting("application/config/name")}
	save_and_exit_dialog.refresh()
	
	SaveManager.before_screenshot.connect(hide)
	SaveManager.after_screenshot.connect(show)
	
	super._ready()  # always last — triggers go_to(_initial_state)
	
	close()


func _input(event: InputEvent) -> void:
	if InputManager.just_pressed_event("ui_cancel", event):
		if is_visible_in_tree():
			go_back()
		else:
			open()


func update_save_info() -> void:
	SaveManager.list_save_data()
	save_file_selection_screen.update()


func handle_main_menu_request() -> void:
	await SaveManager.auto_save()
	G.request_core_scene.emit(G.MAIN_MENU)


func handle_exit_request() -> void:
	await SaveManager.auto_save()
	get_tree().quit()


func handle_save_request() -> void:
	if G.config.manual_loading_enabled:                                                                                                                                                                                                       
		save_file_selection_screen.mode = SaveManager.Mode.SAVING
		update_save_info()
		go_to(State.SAVE_FILE_SELECTION)
	else:
		await SaveManager.auto_save()
		close()


func handle_load_request() -> void:
	save_file_selection_screen.mode = SaveManager.Mode.LOADING
	update_save_info()
	go_to(State.SAVE_FILE_SELECTION)
