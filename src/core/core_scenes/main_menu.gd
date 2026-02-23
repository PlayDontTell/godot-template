extends Control

@onready var title_screen: MarginContainer = %TitleScreen

@onready var title_label: Label = %TitleLabel

@onready var play_btn: Button = %PlayBtn
@onready var settings_btn: Button = %SettingsBtn
@onready var credits_btn: Button = %CreditsBtn
@onready var exit_btn: Button = %ExitBtn

enum Menu {
	TITLE,
	CREDITS,
	SETTINGS,
	GAME_SELECTION,
	EXIT,
}
var menu : Menu = Menu.TITLE


func _ready() -> void:
	init()


func init() -> void:
	title_label.set_text(ProjectSettings.get_setting("application/config/name"))
	
	if G.is_expo():
		settings_btn.hide()
	
	change_menu(Menu.TITLE)


func change_menu(new_menu : Menu) -> void:
	title_screen.hide()
	
	match new_menu:
		Menu.TITLE:
			title_screen.show()
		
		Menu.CREDITS:
			pass
		
		Menu.GAME_SELECTION:
			pass
		
		Menu.EXIT:
			pass


func _on_play_btn_pressed() -> void:
	change_menu(Menu.GAME_SELECTION)


func _on_credits_btn_pressed() -> void:
	change_menu(Menu.CREDITS)

 
func _on_exit_btn_pressed() -> void:
	change_menu(Menu.EXIT)


func _on_exit_dialog_canceled() -> void:
	change_menu(Menu.TITLE)


func _on_exit_dialog_confirmed() -> void:
	get_tree().quit()


func _on_back_btn_pressed() -> void:
	change_menu(Menu.TITLE)


func _on_start_game_btn_pressed() -> void:
	G.request_core_scene.emit(G.CoreScene.GAME)
