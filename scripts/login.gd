extends Control

@onready var username_input: LineEdit = %UsernameInput
@onready var password_input: LineEdit = %PasswordInput
@onready var error_label: Label = %ErrorLabel
@onready var login_button: Button = %LoginButton
@onready var lang_button: Button = $LangButton
@onready var lang_dropdown = $LangButton/LangDropdown

func _ready() -> void:
	var langs: Array[Dictionary] = [
		{"locale": "en", "label": "English"},
		{"locale": "vi", "label": "Tiếng Việt"},
	]
	lang_dropdown.options = langs
	lang_dropdown.language_selected.connect(_on_language_selected)
	_update_lang_button_text()

func _on_login_pressed() -> void:
	var username := username_input.text.strip_edges()
	var password := password_input.text.strip_edges()

	if username.is_empty() or password.is_empty():
		error_label.text = "ERROR_EMPTY"
		return

	if username == "admin" and password == "admin":
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
	else:
		error_label.text = "ERROR_INVALID"

func _on_lang_pressed() -> void:
	if lang_dropdown.visible:
		lang_dropdown.close()
	else:
		lang_dropdown.open(TranslationServer.get_locale().left(2))

func _on_language_selected(locale: String) -> void:
	TranslationServer.set_locale(locale)
	_update_lang_button_text()

func _update_lang_button_text() -> void:
	var current := TranslationServer.get_locale().left(2)
	for opt in lang_dropdown.options:
		if opt.get("locale") == current:
			lang_button.text = opt.get("label", "")
			return
	lang_button.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and lang_dropdown.visible:
		var btn_rect := Rect2(lang_button.global_position, lang_button.size)
		var ddown_rect := Rect2(lang_dropdown.global_position, lang_dropdown.size * lang_dropdown.scale)
		var mouse_pos := get_global_mouse_position()
		if not btn_rect.has_point(mouse_pos) and not ddown_rect.has_point(mouse_pos):
			lang_dropdown.close()
