extends CanvasLayer

@onready var settings_button: Button = $"../UILayer/SettingsButton"
@onready var settings_dropdown = $"../UILayer/SettingsButton/SettingsDropdown"
@onready var chop_button: Button = $"../UILayer/ChopButton"
var resource_game_ui: Control = null
var _nearby_trees: int = 0
const RESOURCE_GAME_SCENE := preload("res://scenes/resource_game.tscn")

func _ready() -> void:
	settings_button.icon = load("res://assets/icons/icon_gear.png")
	settings_button.text = ""
	var transparent := StyleBoxFlat.new()
	transparent.bg_color = Color(0, 0, 0, 0)
	settings_button.add_theme_stylebox_override("normal", transparent)
	settings_button.add_theme_stylebox_override("pressed", transparent)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1, 1, 1, 0.15)
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_right = 8
	hover.corner_radius_bottom_left = 8
	settings_button.add_theme_stylebox_override("hover", hover)
	_setup_chop_button()
	if not SessionManager.is_logged_in:
		call_deferred("_go_to_login")
		return
	var opts: Array[Dictionary] = [
		{"action": "resources", "label": tr("RES_LABEL"), "icon": "res://assets/icons/icon_resource.png"},
		{"action": "logout", "label": tr("LOG_OUT"), "icon": "res://assets/icons/icon_logout.png"},
	]
	settings_dropdown.options = opts
	settings_dropdown.option_selected.connect(_on_settings_option)
	settings_button.pressed.connect(_on_settings_pressed)

func _setup_chop_button() -> void:
	chop_button.icon = load("res://assets/icons/icon_chop.png")
	chop_button.text = ""
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0.35)
	normal.corner_radius_top_left = 24
	normal.corner_radius_top_right = 24
	normal.corner_radius_bottom_right = 24
	normal.corner_radius_bottom_left = 24
	chop_button.add_theme_stylebox_override("normal", normal)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.2, 0.2, 0.2, 0.6)
	pressed.corner_radius_top_left = 24
	pressed.corner_radius_top_right = 24
	pressed.corner_radius_bottom_right = 24
	pressed.corner_radius_bottom_left = 24
	chop_button.add_theme_stylebox_override("pressed", pressed)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1, 1, 1, 0.15)
	hover.corner_radius_top_left = 24
	hover.corner_radius_top_right = 24
	hover.corner_radius_bottom_right = 24
	hover.corner_radius_bottom_left = 24
	chop_button.add_theme_stylebox_override("hover", hover)
	chop_button.button_down.connect(_on_chop_pressed)
	chop_button.button_up.connect(_on_chop_released)
	chop_button.visible = false
	for tree in get_tree().get_nodes_in_group("trees"):
		if not tree.is_connected("chop_proximity_changed", _on_chop_proximity_changed):
			tree.chop_proximity_changed.connect(_on_chop_proximity_changed)

func _on_chop_pressed() -> void:
	var ev := InputEventAction.new()
	ev.action = "chop"
	ev.pressed = true
	Input.parse_input_event(ev)

func _on_chop_proximity_changed(nearby: bool) -> void:
	if nearby:
		_nearby_trees += 1
	else:
		_nearby_trees = max(0, _nearby_trees - 1)
	chop_button.visible = _nearby_trees > 0

func _on_chop_released() -> void:
	var ev := InputEventAction.new()
	ev.action = "chop"
	ev.pressed = false
	Input.parse_input_event(ev)

func _go_to_login() -> void:
	get_tree().change_scene_to_file("res://scenes/login.tscn")

func _on_settings_pressed() -> void:
	if settings_dropdown.visible:
		settings_dropdown.close()
	else:
		settings_dropdown.open()

func _on_settings_option(action: String) -> void:
	match action:
		"resources":
			if resource_game_ui == null:
				resource_game_ui = RESOURCE_GAME_SCENE.instantiate()
				add_child(resource_game_ui)
			elif resource_game_ui.visible:
				resource_game_ui.hide()
			else:
				resource_game_ui.show()
		"logout":
			SessionLogic.logout()
			get_tree().change_scene_to_file("res://scenes/login.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and settings_dropdown.visible:
		var btn_rect := Rect2(settings_button.global_position, settings_button.size)
		var ddown_rect := Rect2(settings_dropdown.global_position, settings_dropdown.size * settings_dropdown.scale)
		var mouse_pos := get_viewport().get_mouse_position()
		if not btn_rect.has_point(mouse_pos) and not ddown_rect.has_point(mouse_pos):
			settings_dropdown.close()
