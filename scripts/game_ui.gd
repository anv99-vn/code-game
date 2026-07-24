extends CanvasLayer

signal logout_requested

@onready var settings_button: Button = $"../UILayer/SettingsButton"
@onready var settings_dropdown = $"../UILayer/SettingsButton/SettingsDropdown"
@onready var action_button: TextureButton = $"../UILayer/ActionButton"
@onready var action_button_bg: Panel = $"../UILayer/ActionButtonBackground"
var resource_game_ui: Control = null
var _current_action: String = ""
var _focused_resource: Node2D = null
const RESOURCE_GAME_SCENE := preload("res://scenes/resource_game.tscn")


func _ready() -> void:
	_setup_action_button()
	_setup_settings()


func _setup_action_button() -> void:
	action_button.button_down.connect(_on_action_pressed)
	action_button.button_up.connect(_on_action_released)
	action_button.visible = false
	action_button_bg.visible = false


func _setup_settings() -> void:
	settings_button.text = tr("SETTINGS")
	settings_dropdown.update_toggle("click_to_move", SettingsManager.click_to_move)
	settings_dropdown.option_selected.connect(_on_settings_option)
	settings_button.pressed.connect(_on_settings_pressed)


func _on_focus_changed(focused: Node2D) -> void:
	_focused_resource = focused
	if focused == null:
		_current_action = ""
		action_button.visible = false
		action_button_bg.visible = false
	elif focused.is_in_group("trees") or focused.is_in_group("stones") or focused.is_in_group("gold_sources"):
		if focused.has_signal("depleted_changed"):
			if focused._depleted:
				_current_action = ""
				action_button.visible = false
				action_button_bg.visible = false
				if not focused.depleted_changed.is_connected(_on_depleted_changed):
					focused.depleted_changed.connect(_on_depleted_changed)
				return
			if not focused.depleted_changed.is_connected(_on_depleted_changed):
				focused.depleted_changed.connect(_on_depleted_changed)
		_show_action_for_resource(focused)


func _on_depleted_changed(is_depleted: bool) -> void:
	if is_depleted:
		_current_action = ""
		action_button.visible = false
		action_button_bg.visible = false
	elif _focused_resource and is_instance_valid(_focused_resource):
		_show_action_for_resource(_focused_resource)


func _show_action_for_resource(resource: Node2D) -> void:
	if resource.is_in_group("trees"):
		_set_action("chop", "res://assets/icons/icon_chop.png")
	elif resource.is_in_group("stones"):
		_set_action("mine", "res://assets/icons/icon_mine.png")
	elif resource.is_in_group("gold_sources"):
		_set_action("pan", "res://assets/icons/icon_pan.png")


func _set_action(action: String, icon_path: String) -> void:
	_current_action = action
	action_button.texture_normal = load(icon_path)
	action_button.visible = true
	action_button_bg.visible = true


func _on_action_pressed() -> void:
	if _current_action.is_empty():
		return
	var tween := create_tween()
	tween.tween_property(action_button, "scale", Vector2(0.85, 0.85), 0.08)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	var ev := InputEventAction.new()
	ev.action = _current_action
	ev.pressed = true
	Input.parse_input_event(ev)


func _on_action_released() -> void:
	if _current_action.is_empty():
		return
	var tween := create_tween()
	tween.tween_property(action_button, "scale", Vector2.ONE, 0.1)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	var ev := InputEventAction.new()
	ev.action = _current_action
	ev.pressed = false
	Input.parse_input_event(ev)


func on_login_changed(is_logged_in: bool) -> void:
	if not is_logged_in:
		_go_to_login.call_deferred()


func _go_to_login() -> void:
	get_tree().change_scene_to_file("res://scenes/login.tscn")


func _on_settings_pressed() -> void:
	if settings_dropdown.visible:
		settings_dropdown.close()
	else:
		_update_settings_labels()
		settings_dropdown.open()


func _update_settings_labels() -> void:
	settings_button.text = tr("SETTINGS")
	for child in settings_dropdown.get_children():
		if child is Button:
			var key: String = child.get_meta("label_key", "")
			var action: String = child.get_meta("action", "")
			if action == "click_to_move":
				child.text = tr(key) + ": " + ("ON" if SettingsManager.click_to_move else "OFF")
			else:
				child.text = tr(key)


func _on_settings_option(action: String) -> void:
	match action:
		"click_to_move":
			SettingsManager.click_to_move = not SettingsManager.click_to_move
			_update_click_to_move_option()
		"resources":
			if resource_game_ui == null:
				resource_game_ui = RESOURCE_GAME_SCENE.instantiate()
				add_child(resource_game_ui)
			elif resource_game_ui.visible:
				resource_game_ui.hide()
			else:
				resource_game_ui.show()
		"logout":
			logout_requested.emit()


func _update_click_to_move_option() -> void:
	settings_dropdown.update_toggle("click_to_move", SettingsManager.click_to_move)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and settings_dropdown.visible:
		var btn_rect := Rect2(settings_button.global_position, settings_button.size)
		var ddown_rect := Rect2(settings_dropdown.global_position, settings_dropdown.size * settings_dropdown.scale)
		var mouse_pos := get_viewport().get_mouse_position()
		var screen_rect := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
		if not btn_rect.has_point(mouse_pos) and not ddown_rect.has_point(mouse_pos):
			settings_dropdown.close()
		elif not screen_rect.has_point(mouse_pos):
			settings_dropdown.close()
