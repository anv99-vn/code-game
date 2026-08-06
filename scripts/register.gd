extends Control

const MIN_USERNAME_LENGTH := 3
const MAX_USERNAME_LENGTH := 32
const MIN_PASSWORD_LENGTH := 8
const MAX_PASSWORD_LENGTH := 72
const USERNAME_REGEX := "^[a-zA-Z0-9_]{3,32}$"

@onready var username_input: LineEdit = %UsernameInput
@onready var password_input: LineEdit = %PasswordInput
@onready var confirm_password_input: LineEdit = %ConfirmPasswordInput
@onready var error_label: Label = %ErrorLabel
@onready var register_button: Button = %RegisterButton
@onready var back_to_login: Button = $BackToLogin
@onready var lang_button: Button = $LangButton
@onready var lang_dropdown = $LangButton/LangDropdown


func _ready() -> void:
	lang_dropdown.language_selected.connect(_on_language_selected)
	_copy_input_theme()
	_update_lang_button_text()


## Styles the confirm field identically to the password field (theme
## sub-resources from the .tscn can't be referenced by the new node).
func _copy_input_theme() -> void:
	confirm_password_input.add_theme_color_override("font_color", password_input.get_theme_color("font_color"))
	confirm_password_input.add_theme_color_override("font_placeholder_color", password_input.get_theme_color("font_placeholder_color"))
	confirm_password_input.add_theme_font_size_override("font_size", password_input.get_theme_font_size("font_size"))
	confirm_password_input.add_theme_stylebox_override("normal", password_input.get_theme_stylebox("normal"))
	confirm_password_input.add_theme_stylebox_override("focus", password_input.get_theme_stylebox("focus"))


func _on_register_pressed() -> void:
	var username := username_input.text.strip_edges()
	var password := password_input.text.strip_edges()
	var confirm := confirm_password_input.text.strip_edges()

	if username.is_empty() or password.is_empty() or confirm.is_empty():
		error_label.text = tr("ERROR_EMPTY")
		return

	var username_regex := RegEx.new()
	username_regex.compile(USERNAME_REGEX)
	if not username_regex.search(username):
		error_label.text = tr("ERROR_USERNAME_INVALID")
		return

	if password.length() < MIN_PASSWORD_LENGTH or password.length() > MAX_PASSWORD_LENGTH:
		error_label.text = tr("ERROR_TOO_SHORT") % [MIN_PASSWORD_LENGTH, MAX_PASSWORD_LENGTH]
		return

	if password != confirm:
		error_label.text = tr("ERROR_PASSWORD_MISMATCH")
		return

	register_button.disabled = true
	error_label.text = ""

	var error_key: StringName = await SessionManager.register_user(username, password)
	if error_key != &"":
		error_label.text = tr(error_key)
		register_button.disabled = false
		return

	get_tree().change_scene_to_file(AssetRegistry.SCENES_LOGIN)


func _on_back_to_login_pressed() -> void:
	get_tree().change_scene_to_file(AssetRegistry.SCENES_LOGIN)


func _on_lang_pressed() -> void:
	if lang_dropdown.visible:
		lang_dropdown.close()
	else:
		lang_dropdown.open()


func _on_language_selected(locale: String) -> void:
	TranslationServer.set_locale(locale)
	register_button.text = tr("REGISTER_BUTTON")
	back_to_login.text = tr("BACK_TO_LOGIN")
	username_input.placeholder_text = tr("USERNAME")
	password_input.placeholder_text = tr("PASSWORD")
	confirm_password_input.placeholder_text = tr("CONFIRM_PASSWORD")
	_update_lang_button_text()


func _update_lang_button_text() -> void:
	var current := TranslationServer.get_locale().left(2)
	var key: String = lang_dropdown.get_current_label(current)
	if key.is_empty():
		lang_button.text = tr("LANG_EN")
	else:
		lang_button.text = tr(key)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if lang_dropdown.visible and _is_click_outside(lang_button, lang_dropdown):
			lang_dropdown.close()


func _is_click_outside(btn: Control, dropdown: Control) -> bool:
	var btn_rect := Rect2(btn.global_position, btn.size)
	var ddown_rect := Rect2(dropdown.global_position, dropdown.size * dropdown.scale)
	var mouse_pos := get_global_mouse_position()
	return not btn_rect.has_point(mouse_pos) and not ddown_rect.has_point(mouse_pos)
