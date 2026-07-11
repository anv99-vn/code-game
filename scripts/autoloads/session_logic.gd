extends Node

func login(_username: String) -> void:
	SessionManager.is_logged_in = true
	ResourceLogic.reset_resources()
	ResourceLogic.start_passive_income()

func logout() -> void:
	SessionManager.is_logged_in = false
	ResourceLogic.stop_passive_income()
	ResourceLogic.reset_resources()

func has_saved_credentials() -> bool:
	var config := ConfigFile.new()
	if config.load("user://login.cfg") != OK:
		return false
	var username: String = config.get_value("login", "username", "")
	return not username.is_empty()
