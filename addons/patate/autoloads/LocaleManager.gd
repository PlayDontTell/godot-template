extends Node


# Using translated text : tr("STRING_NAME")

## Emited when game locale has been changed
signal locale_changed

## The game currently used locale
var current_locale : String = get_OS_default_locale()

## Sets game locale (langage setting)
func set_locale(request_locale : String) -> void:
	if request_locale in get_available_locales():
		if request_locale == current_locale:
			print("locale is already " + request_locale)
		else:
			current_locale = request_locale
			TranslationServer.set_locale(request_locale)
			locale_changed.emit()
			print("locale set to " + request_locale)
	else:
		current_locale = TranslationServer.get_locale()
		printerr("requested locale named " + request_locale + " not supported. Available locales: " + str(get_available_locales()))


## Get the locale used on the machine
func get_OS_default_locale() -> String:
	return OS.get_locale_language()


# List all available locales in the game
func get_available_locales() -> PackedStringArray:
	return TranslationServer.get_loaded_locales()
