extends Control


enum Menus {
	MAIN,
	CREDITS,
	SETTINGS,
	GAME_SELECTION,
	EXIT,
}
var menu : Menus = Menus.MAIN


func _ready() -> void:
	change_menu(Menus.MAIN)


func change_menu(new_menu : Menus) -> void:
	#object.hide()
	
	match new_menu:
		Menus.MAIN:
			pass
		
		Menus.CREDITS:
			pass
		
		Menus.GAME_SELECTION:
			pass
		
		Menus.EXIT:
			pass


func _on_play_btn_pressed() -> void:
	change_menu(Menus.GAME_SELECTION)


func _on_credits_btn_pressed() -> void:
	change_menu(Menus.CREDITS)

 
func _on_exit_btn_pressed() -> void:
	change_menu(Menus.EXIT)


func _on_exit_dialog_canceled() -> void:
	change_menu(Menus.MAIN)


func _on_exit_dialog_confirmed() -> void:
	get_tree().quit()


func _on_back_btn_pressed() -> void:
	change_menu(Menus.MAIN)


func _on_start_game_btn_pressed() -> void:
	G.request_core_scene.emit(G.CoreScenes.GAME)
