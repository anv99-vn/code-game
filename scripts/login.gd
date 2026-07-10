extends Control

@onready var username_input: LineEdit = %UsernameInput
@onready var password_input: LineEdit = %PasswordInput
@onready var error_label: Label = %ErrorLabel
@onready var login_button: Button = %LoginButton
@onready var forgot_password: Button = $ForgotPassword
@onready var lang_button: Button = $LangButton
@onready var lang_dropdown = $LangButton/LangDropdown

func _ready() -> void:
	# Set placeholder texts manually (LineEdit placeholders don't auto-translate)
	username_input.placeholder_text = tr("USERNAME")
	password_input.placeholder_text = tr("PASSWORD")
	lang_button.icon = load("res://assets/icons/icon_globe_small.png")
	lang_button.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	lang_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	var lang_bg := StyleBoxFlat.new()
	lang_bg.bg_color = Color(1, 1, 1, 0.15)
	lang_bg.corner_radius_top_left = 8
	lang_bg.corner_radius_top_right = 8
	lang_bg.corner_radius_bottom_right = 8
	lang_bg.corner_radius_bottom_left = 8
	lang_button.add_theme_stylebox_override("normal", lang_bg)
	lang_button.add_theme_stylebox_override("pressed", lang_bg)
	var lang_hover := StyleBoxFlat.new()
	lang_hover.bg_color = Color(1, 1, 1, 0.25)
	lang_hover.corner_radius_top_left = 8
	lang_hover.corner_radius_top_right = 8
	lang_hover.corner_radius_bottom_right = 8
	lang_hover.corner_radius_bottom_left = 8
	lang_button.add_theme_stylebox_override("hover", lang_hover)
	forgot_password.pressed.connect(_on_forgot_password_pressed)
	if SessionManager.is_logged_in:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		return
	_load_credentials()
	var langs: Array[Dictionary] = [
		{"locale": "en", "label": tr("LANG_EN")},
		{"locale": "vi", "label": tr("LANG_VI")},
	]
	lang_dropdown.options = langs
	lang_dropdown.language_selected.connect(_on_language_selected)
	_update_lang_button_text()

func _on_login_pressed() -> void:
	var username := username_input.text.strip_edges()
	var password := password_input.text.strip_edges()

	if username.is_empty() or password.is_empty():
		error_label.text = tr("ERROR_EMPTY")
		return

	if username == "admin" and password == "admin":
		_save_credentials(username, password)
		SessionManager.login(username)
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		error_label.text = tr("ERROR_INVALID")

func _save_credentials(username: String, password: String) -> void:
	var config := ConfigFile.new()
	config.set_value("login", "username", username)
	config.set_value("login", "password", password)
	config.save("user://login.cfg")

func _load_credentials() -> void:
	var config := ConfigFile.new()
	if config.load("user://login.cfg") != OK:
		return
	username_input.text = config.get_value("login", "username", "")
	password_input.text = config.get_value("login", "password", "")

func _on_lang_pressed() -> void:
	if lang_dropdown.visible:
		lang_dropdown.close()
	else:
		lang_dropdown.open(TranslationServer.get_locale().left(2))

func _on_language_selected(locale: String) -> void:
	TranslationServer.set_locale(locale)
	# Manually update texts (auto-translate can be unreliable at runtime)
	login_button.text = tr("LOGIN_BUTTON")
	forgot_password.text = tr("FORGOT_PASSWORD")
	username_input.placeholder_text = tr("USERNAME")
	password_input.placeholder_text = tr("PASSWORD")
	# Rebuild dropdown with translated labels
	var langs: Array[Dictionary] = [
		{"locale": "en", "label": tr("LANG_EN")},
		{"locale": "vi", "label": tr("LANG_VI")},
	]
	lang_dropdown.options = langs
	_update_lang_button_text()

func _update_lang_button_text() -> void:
	var current := TranslationServer.get_locale().left(2)
	for opt in lang_dropdown.options:
		if opt.get("locale") == current:
			lang_button.text = opt.get("label", "")
			return
	lang_button.text = tr("LANG_EN")

func _on_forgot_password_pressed() -> void:
	error_label.text = tr("FORGOT_PASSWORD_MSG")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and lang_dropdown.visible:
		var btn_rect := Rect2(lang_button.global_position, lang_button.size)
		var ddown_rect := Rect2(lang_dropdown.global_position, lang_dropdown.size * lang_dropdown.scale)
		var mouse_pos := get_global_mouse_position()
		if not btn_rect.has_point(mouse_pos) and not ddown_rect.has_point(mouse_pos):
			lang_dropdown.close()
