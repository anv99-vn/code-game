extends Control

signal login_requested(username: String)

@onready var username_input: LineEdit = %UsernameInput
@onready var password_input: LineEdit = %PasswordInput
@onready var error_label: Label = %ErrorLabel
@onready var login_button: Button = %LoginButton
@onready var forgot_password: Button = $ForgotPassword
@onready var lang_button: Button = $LangButton
@onready var lang_dropdown = $LangButton/LangDropdown
@onready var render_engine_label: Label = $RenderEngineLabel


func _ready() -> void:
	add_to_group("login_screen")
	forgot_password.pressed.connect(_on_forgot_password_pressed)
	lang_dropdown.language_selected.connect(_on_language_selected)
	_update_lang_button_text()
	_update_render_engine_label()


func on_login_changed(is_logged_in: bool) -> void:
	if is_logged_in:
		get_tree().change_scene_to_file(AssetRegistry.SCENES_GAME)


func on_credentials_loaded(saved: bool) -> void:
	if saved:
		_load_credentials.call_deferred()


func _on_login_pressed() -> void:
	var username := username_input.text.strip_edges()
	var password := password_input.text.strip_edges()

	if username.is_empty() or password.is_empty():
		error_label.text = tr("ERROR_EMPTY")
		return

	if username == "admin" and password == "admin":
		_save_credentials(username, password)
		login_requested.emit(username)
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
		lang_dropdown.open()


func _on_language_selected(locale: String) -> void:
	TranslationServer.set_locale(locale)
	login_button.text = tr("LOGIN_BUTTON")
	forgot_password.text = tr("FORGOT_PASSWORD")
	username_input.placeholder_text = tr("USERNAME")
	password_input.placeholder_text = tr("PASSWORD")
	_update_lang_button_text()


func _update_render_engine_label() -> void:
	var version := Engine.get_version_info()
	var setting_key := "rendering/renderer/rendering_method"
	if OS.get_name() == "Android":
		setting_key = "rendering/renderer/rendering_method.mobile"
	var method: String = ProjectSettings.get_setting(setting_key, "forward_plus")
	var driver := RenderingServer.get_current_rendering_driver_name()
	render_engine_label.text = "Godot %d.%d.%d - %s - %s" % [version.major, version.minor, version.patch, driver, method]


func _update_lang_button_text() -> void:
	var current := TranslationServer.get_locale().left(2)
	var key: String = lang_dropdown.get_current_label(current)
	if key.is_empty():
		lang_button.text = tr("LANG_EN")
	else:
		lang_button.text = tr(key)


func _on_forgot_password_pressed() -> void:
	error_label.text = tr("FORGOT_PASSWORD_MSG")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and lang_dropdown.visible:
		var btn_rect := Rect2(lang_button.global_position, lang_button.size)
		var ddown_rect := Rect2(lang_dropdown.global_position, lang_dropdown.size * lang_dropdown.scale)
		var mouse_pos := get_global_mouse_position()
		if not btn_rect.has_point(mouse_pos) and not ddown_rect.has_point(mouse_pos):
			lang_dropdown.close()
