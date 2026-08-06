extends Control

signal login_requested(username: String)

const RENDER_OVERRIDE_PATH := "user://render_engine.cfg"

const ENGINE_SETTINGS := {
	"vulkan": {
		"method": "forward_plus",
		"driver": "vulkan",
		"use_gl_driver": false,
	},
	"d3d12": {
		"method": "forward_plus",
		"driver": "d3d12",
		"use_gl_driver": false,
	},
	"opengl": {
		"method": "gl_compatibility",
		"driver": "opengl3",
		"use_gl_driver": true,
	},
}

@onready var username_input: LineEdit = %UsernameInput
@onready var password_input: LineEdit = %PasswordInput
@onready var error_label: Label = %ErrorLabel
@onready var login_button: Button = %LoginButton
@onready var forgot_password: Button = $ForgotPassword
@onready var lang_button: Button = $LangButton
@onready var lang_dropdown = $LangButton/LangDropdown
@onready var engine_button: Button = $EngineButton
@onready var engine_dropdown = $EngineButton/EngineDropdown
@onready var render_engine_label: Label = $RenderEngineLabel


func _ready() -> void:
	add_to_group("login_screen")
	forgot_password.pressed.connect(_on_forgot_password_pressed)
	lang_dropdown.language_selected.connect(_on_language_selected)
	engine_dropdown.engine_selected.connect(_on_engine_selected)
	_update_lang_button_text()
	_update_engine_button_text()
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
		if WelcomeToast:
			WelcomeToast.show_welcome(username)
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


func _on_engine_pressed() -> void:
	if engine_dropdown.visible:
		engine_dropdown.close()
	else:
		engine_dropdown.current_engine = _get_selected_engine()
		engine_dropdown.open()


func _on_engine_selected(engine: String) -> void:
	_apply_render_engine(engine)
	_update_engine_button_text()
	_update_render_engine_label()
	error_label.text = tr("RENDER_RESTART_MSG")


func _apply_render_engine(engine: String) -> void:
	if not ENGINE_SETTINGS.has(engine):
		return
	var info: Dictionary = ENGINE_SETTINGS[engine]
	ProjectSettings.set_setting("rendering/renderer/rendering_method", info.method)
	var config := ConfigFile.new()
	config.set_value("rendering", "renderer/rendering_method", info.method)
	if info.use_gl_driver:
		ProjectSettings.set_setting("rendering/gl_compatibility/driver.windows", info.driver)
		config.set_value("rendering", "gl_compatibility/driver.windows", info.driver)
	else:
		ProjectSettings.set_setting("rendering/rendering_device/driver.windows", info.driver)
		config.set_value("rendering", "rendering_device/driver.windows", info.driver)
	config.save(RENDER_OVERRIDE_PATH)


func _get_selected_engine() -> String:
	var saved := _get_saved_engine()
	if not saved.is_empty():
		return saved
	return _detect_running_engine()


func _get_saved_engine() -> String:
	var config := ConfigFile.new()
	if config.load(RENDER_OVERRIDE_PATH) != OK:
		return ""
	var method: String = config.get_value("rendering", "renderer/rendering_method", "")
	if method == "gl_compatibility":
		return "opengl"
	var driver: String = config.get_value("rendering", "rendering_device/driver.windows", "vulkan")
	return "d3d12" if driver == "d3d12" else "vulkan"


func _detect_running_engine() -> String:
	var method := RenderingServer.get_current_rendering_method()
	if method == "gl_compatibility":
		return "opengl"
	var driver := RenderingServer.get_current_rendering_driver_name()
	return "d3d12" if driver == "d3d12" else "vulkan"


func _update_engine_button_text() -> void:
	var engine := _get_selected_engine()
	var key: String = engine_dropdown.get_current_label(engine)
	if key.is_empty():
		engine_button.text = tr("RENDER_ENGINE")
	else:
		engine_button.text = tr(key)


func _on_language_selected(locale: String) -> void:
	TranslationServer.set_locale(locale)
	login_button.text = tr("LOGIN_BUTTON")
	forgot_password.text = tr("FORGOT_PASSWORD")
	username_input.placeholder_text = tr("USERNAME")
	password_input.placeholder_text = tr("PASSWORD")
	_update_lang_button_text()
	_update_engine_button_text()


func _update_render_engine_label() -> void:
	var version := Engine.get_version_info()
	var driver := RenderingServer.get_current_rendering_driver_name()
	var method := RenderingServer.get_current_rendering_method()
	var running := "%s / %s" % [driver, method]
	var saved := _get_saved_engine()
	if not saved.is_empty() and saved != _detect_running_engine():
		var key: String = engine_dropdown.get_current_label(saved)
		var pending := tr(key) if not key.is_empty() else saved
		running += "  → %s (restart)" % pending
	render_engine_label.text = "Godot %d.%d.%d - %s" % [version.major, version.minor, version.patch, running]


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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if lang_dropdown.visible and _is_click_outside(lang_button, lang_dropdown):
			lang_dropdown.close()
		if engine_dropdown.visible and _is_click_outside(engine_button, engine_dropdown):
			engine_dropdown.close()


func _is_click_outside(btn: Control, dropdown: Control) -> bool:
	var btn_rect := Rect2(btn.global_position, btn.size)
	var ddown_rect := Rect2(dropdown.global_position, dropdown.size * dropdown.scale)
	var mouse_pos := get_global_mouse_position()
	return not btn_rect.has_point(mouse_pos) and not ddown_rect.has_point(mouse_pos)
