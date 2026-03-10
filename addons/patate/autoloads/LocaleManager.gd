extends Node
# Using translated text : tr("STRING_NAME")

## Emited when game locale has been changed
signal locale_changed

const LANGUAGE_FLAGS: Dictionary = {
	"af":  { "country": "ZA", "flag": "🇿🇦" },  # Afrikaans
	"ar":  { "country": "SA", "flag": "🇸🇦" },  # Arabic
	"az":  { "country": "AZ", "flag": "🇦🇿" },  # Azerbaijani
	"be":  { "country": "BY", "flag": "🇧🇾" },  # Belarusian
	"bg":  { "country": "BG", "flag": "🇧🇬" },  # Bulgarian
	"bn":  { "country": "BD", "flag": "🇧🇩" },  # Bengali
	"bs":  { "country": "BA", "flag": "🇧🇦" },  # Bosnian
	"ca":  { "country": "ES", "flag": "🇪🇸" },  # Catalan
	"cs":  { "country": "CZ", "flag": "🇨🇿" },  # Czech
	"cy":  { "country": "GB", "flag": "🏴󠁧󠁢󠁷󠁬󠁳󠁿" },  # Welsh
	"da":  { "country": "DK", "flag": "🇩🇰" },  # Danish
	"de":  { "country": "DE", "flag": "🇩🇪" },  # German
	"el":  { "country": "GR", "flag": "🇬🇷" },  # Greek
	"en":  { "country": "GB", "flag": "🇬🇧" },  # English
	"eo":  { "country": "",   "flag": "🏳️"  },  # Esperanto
	"es":  { "country": "ES", "flag": "🇪🇸" },  # Spanish
	"et":  { "country": "EE", "flag": "🇪🇪" },  # Estonian
	"eu":  { "country": "ES", "flag": "🇪🇸" },  # Basque
	"fa":  { "country": "IR", "flag": "🇮🇷" },  # Persian
	"fi":  { "country": "FI", "flag": "🇫🇮" },  # Finnish
	"fil": { "country": "PH", "flag": "🇵🇭" },  # Filipino
	"fr":  { "country": "FR", "flag": "🇫🇷" },  # French
	"fy":  { "country": "NL", "flag": "🇳🇱" },  # Frisian
	"ga":  { "country": "IE", "flag": "🇮🇪" },  # Irish
	"gl":  { "country": "ES", "flag": "🇪🇸" },  # Galician
	"gu":  { "country": "IN", "flag": "🇮🇳" },  # Gujarati
	"he":  { "country": "IL", "flag": "🇮🇱" },  # Hebrew
	"hi":  { "country": "IN", "flag": "🇮🇳" },  # Hindi
	"hr":  { "country": "HR", "flag": "🇭🇷" },  # Croatian
	"hu":  { "country": "HU", "flag": "🇭🇺" },  # Hungarian
	"hy":  { "country": "AM", "flag": "🇦🇲" },  # Armenian
	"id":  { "country": "ID", "flag": "🇮🇩" },  # Indonesian
	"is":  { "country": "IS", "flag": "🇮🇸" },  # Icelandic
	"it":  { "country": "IT", "flag": "🇮🇹" },  # Italian
	"ja":  { "country": "JP", "flag": "🇯🇵" },  # Japanese
	"ka":  { "country": "GE", "flag": "🇬🇪" },  # Georgian
	"kk":  { "country": "KZ", "flag": "🇰🇿" },  # Kazakh
	"km":  { "country": "KH", "flag": "🇰🇭" },  # Khmer
	"kn":  { "country": "IN", "flag": "🇮🇳" },  # Kannada
	"ko":  { "country": "KR", "flag": "🇰🇷" },  # Korean
	"lb":  { "country": "LU", "flag": "🇱🇺" },  # Luxembourgish
	"lij": { "country": "IT", "flag": "🇮🇹" },  # Ligurian
	"lo":  { "country": "LA", "flag": "🇱🇦" },  # Lao
	"lt":  { "country": "LT", "flag": "🇱🇹" },  # Lithuanian
	"lv":  { "country": "LV", "flag": "🇱🇻" },  # Latvian
	"mi":  { "country": "NZ", "flag": "🇳🇿" },  # Maori
	"mk":  { "country": "MK", "flag": "🇲🇰" },  # Macedonian
	"ml":  { "country": "IN", "flag": "🇮🇳" },  # Malayalam
	"mn":  { "country": "MN", "flag": "🇲🇳" },  # Mongolian
	"mr":  { "country": "IN", "flag": "🇮🇳" },  # Marathi
	"ms":  { "country": "MY", "flag": "🇲🇾" },  # Malay
	"mt":  { "country": "MT", "flag": "🇲🇹" },  # Maltese
	"my":  { "country": "MM", "flag": "🇲🇲" },  # Burmese
	"nb":  { "country": "NO", "flag": "🇳🇴" },  # Norwegian Bokmål
	"ne":  { "country": "NP", "flag": "🇳🇵" },  # Nepali
	"nl":  { "country": "NL", "flag": "🇳🇱" },  # Dutch
	"or":  { "country": "IN", "flag": "🇮🇳" },  # Odia
	"pa":  { "country": "IN", "flag": "🇮🇳" },  # Punjabi
	"pl":  { "country": "PL", "flag": "🇵🇱" },  # Polish
	"pt":  { "country": "PT", "flag": "🇵🇹" },  # Portuguese
	"ro":  { "country": "RO", "flag": "🇷🇴" },  # Romanian
	"ru":  { "country": "RU", "flag": "🇷🇺" },  # Russian
	"si":  { "country": "LK", "flag": "🇱🇰" },  # Sinhala
	"sk":  { "country": "SK", "flag": "🇸🇰" },  # Slovak
	"sl":  { "country": "SI", "flag": "🇸🇮" },  # Slovenian
	"sq":  { "country": "AL", "flag": "🇦🇱" },  # Albanian
	"sr":  { "country": "RS", "flag": "🇷🇸" },  # Serbian
	"sv":  { "country": "SE", "flag": "🇸🇪" },  # Swedish
	"sw":  { "country": "KE", "flag": "🇰🇪" },  # Swahili
	"ta":  { "country": "IN", "flag": "🇮🇳" },  # Tamil
	"te":  { "country": "IN", "flag": "🇮🇳" },  # Telugu
	"th":  { "country": "TH", "flag": "🇹🇭" },  # Thai
	"tl":  { "country": "PH", "flag": "🇵🇭" },  # Tagalog
	"tr":  { "country": "TR", "flag": "🇹🇷" },  # Turkish
	"uk":  { "country": "UA", "flag": "🇺🇦" },  # Ukrainian
	"ur":  { "country": "PK", "flag": "🇵🇰" },  # Urdu
	"uz":  { "country": "UZ", "flag": "🇺🇿" },  # Uzbek
	"vi":  { "country": "VN", "flag": "🇻🇳" },  # Vietnamese
	"zh":  { "country": "CN", "flag": "🇨🇳" },  # Chinese
	"zu":  { "country": "ZA", "flag": "🇿🇦" },  # Zulu
}

## Sets game locale (langage setting)
func set_locale(request_locale : String) -> void:
	if request_locale in get_available_locales():
		if request_locale != TranslationServer.get_locale():
			TranslationServer.set_locale(request_locale)
			locale_changed.emit()
			
			if not G.is_release():
				print("locale set to " + request_locale)
	else:
		printerr("requested locale named " + request_locale + " not supported. Available locales: " + str(get_available_locales()))


## Get the locale used on the machine
func get_OS_default_locale() -> String:
	return OS.get_locale_language()


## List all available locales in the game
func get_available_locales() -> PackedStringArray:
	return TranslationServer.get_loaded_locales()


## Get the default country (code) associated with a language
func get_country_from_locale(locale: String) -> String:
	if not locale in LANGUAGE_FLAGS:
		push_error("Locale '%s' not found in LANGUAGE_FLAGS" % locale)
		return ""
	return LANGUAGE_FLAGS[locale].country


## Get the flag emoji associated with a language
func get_flag_emoji_from_locale(locale: String) -> String:
	if not locale in LANGUAGE_FLAGS:
		push_error("Locale '%s' not found in LANGUAGE_FLAGS" % locale)
		return ""
	return LANGUAGE_FLAGS[locale].flag


func get_flag_icon(locale: String) -> Texture2D:
	var country_code: String = get_country_from_locale(locale).to_upper()
	var icon_path: String = "res://assets/art/ui/temp/country_flags/30x20px/" + country_code + ".png"
	if FileAccess.file_exists(icon_path):
		return load(icon_path)
	return null



var _bindings: Dictionary = {}

func bind_translation(object: Object, key: String, format_dict: Dictionary = {}) -> void:
	_bindings[object] = [key, format_dict]
	_apply_translation_to(object)

func _apply_translation_to(object: Object) -> void:
	if not is_instance_valid(object):
		_bindings.erase(object)
		return

	var key: String = _bindings[object][0]
	var format: Dictionary = _bindings[object][1]
	object.text = tr(key) if format.is_empty() else tr(key).format(format)

func _refresh_all_translations() -> void:
	for object in _bindings.keys():
		_apply_translation_to(object)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_refresh_all_translations()
