extends Node

signal login_changed(is_logged_in: bool)

var _is_logged_in: bool = false


func login(_username: String) -> void:
	_is_logged_in = true
	ResourceManager.reset()
	login_changed.emit(_is_logged_in)


func logout() -> void:
	_is_logged_in = false
	ResourceManager.reset()
	login_changed.emit(_is_logged_in)


func has_saved_credentials() -> bool:
	var config := ConfigFile.new()
	if config.load("user://login.cfg") != OK:
		return false
	var username: String = config.get_value("login", "username", "")
	return not username.is_empty()


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node.is_in_group("login_screen"):
		if node.has_method("on_login_changed"):
			if not login_changed.is_connected(node.on_login_changed):
				login_changed.connect(node.on_login_changed)
				node.on_login_changed(_is_logged_in)
		if node.has_signal("login_requested") and not node.login_requested.is_connected(_on_login_requested):
			node.login_requested.connect(_on_login_requested)
		if has_saved_credentials() and node.has_method("on_credentials_loaded"):
			node.on_credentials_loaded(true)
	if node.is_in_group("game_ui"):
		if node.has_signal("logout_requested") and not node.logout_requested.is_connected(_on_logout_requested):
			node.logout_requested.connect(_on_logout_requested)
		if node.has_method("on_login_changed"):
			if not login_changed.is_connected(node.on_login_changed):
				login_changed.connect(node.on_login_changed)
				node.on_login_changed(_is_logged_in)


func _on_login_requested(username: String) -> void:
	login(username)


func _on_logout_requested() -> void:
	logout()
