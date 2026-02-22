extends Control

@onready var play_btn: Button = %PlayBtn
@onready var settings_btn: Button = %SettingsBtn
@onready var credits_btn: Button = %CreditsBtn
@onready var exit_btn: Button = %ExitBtn

enum Menu {
	MAIN,
	CREDITS,
	SETTINGS,
	GAME_SELECTION,
	EXIT,
}
var menu : Menu = Menu.MAIN


func _ready() -> void:
	init()


func init() -> void:
	if G.is_expo():
		settings_btn.hide()
	
	change_menu(Menu.MAIN)


func change_menu(new_menu : Menu) -> void:
	#object.hide()
	
	match new_menu:
		Menu.MAIN:
			pass
		
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
	change_menu(Menu.MAIN)


func _on_exit_dialog_confirmed() -> void:
	get_tree().quit()


func _on_back_btn_pressed() -> void:
	change_menu(Menu.MAIN)


func _on_start_game_btn_pressed() -> void:
	G.request_core_scene.emit(G.CoreScene.GAME)
