extends Node

const SETTINGS_PATH := "user://settings.cfg"

var click_to_move: bool = true:
	set(val):
		click_to_move = val
		_save()


func _ready() -> void:
	_load()


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		click_to_move = config.get_value("game", "click_to_move", true)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "click_to_move", click_to_move)
	config.save(SETTINGS_PATH)
