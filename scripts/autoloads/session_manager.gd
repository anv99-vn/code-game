extends Node

signal login_changed(is_logged_in: bool)

const SESSION_PATH := "user://session.cfg"
const CREDENTIALS_PATH := "user://login.cfg"
const _SERVER_API_SCRIPT := preload("res://scripts/server_api.gd")

var _is_logged_in: bool = false
var _token: String = ""
var _username: String = ""
var _api: Node


func get_token() -> String:
	return _token


func get_username() -> String:
	return _username


## Registers a new account via the server. Returns "" on success
## or a translation key describing the error.
func register_user(username: String, password: String) -> StringName:
	if _api == null:
		_api = _SERVER_API_SCRIPT.new()
		add_child(_api)
	_api.register(username, password)
	var result = await _api.register_completed
	if not result[0]:
		var data: Dictionary = result[1]
		if data.has("error"):
			return _map_server_error(data["error"])
		return &"ERROR_SERVER"
	_save_session(result[1].get("token", ""), result[1].get("username", username))
	return &""


## Authenticates via the server. Returns true on success.
func authenticate(username: String, password: String) -> bool:
	if _api == null:
		_api = _SERVER_API_SCRIPT.new()
		add_child(_api)
	_api.login(username, password)
	var result = await _api.login_completed
	if not result[0]:
		return false
	_save_session(result[1].get("token", ""), result[1].get("username", username))
	return true


func _save_session(token: String, username: String) -> void:
	_token = token
	_username = username
	var config := ConfigFile.new()
	config.set_value("session", "token", token)
	config.set_value("session", "username", username)
	config.save(SESSION_PATH)


func _clear_session() -> void:
	_token = ""
	_username = ""
	var config := ConfigFile.new()
	config.set_value("session", "token", "")
	config.set_value("session", "username", "")
	config.save(SESSION_PATH)


func login(username: String) -> void:
	_is_logged_in = true
	_username = username
	ResourceManager.reset()
	login_changed.emit(_is_logged_in)


func logout() -> void:
	_is_logged_in = false
	_clear_session()
	ResourceManager.reset()
	login_changed.emit(_is_logged_in)


func has_saved_credentials() -> bool:
	var config := ConfigFile.new()
	if config.load(CREDENTIALS_PATH) != OK:
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


func _map_server_error(server_error: String) -> StringName:
	if "username already taken" in server_error:
		return &"ERROR_USERNAME_TAKEN"
	if "username must be" in server_error:
		return &"ERROR_USERNAME_INVALID"
	if "password must be" in server_error:
		return &"ERROR_TOO_SHORT"
	return &"ERROR_SERVER"
