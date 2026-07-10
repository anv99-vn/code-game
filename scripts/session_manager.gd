extends Node

var is_logged_in: bool = false

func login(_username: String) -> void:
	is_logged_in = true

func logout() -> void:
	is_logged_in = false

func has_saved_credentials() -> bool:
	var config := ConfigFile.new()
	if config.load("user://login.cfg") != OK:
		return false
	var username: String = config.get_value("login", "username", "")
	return not username.is_empty()
