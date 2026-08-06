extends Node

var _plugin_available: bool = false


func _ready() -> void:
	if Engine.has_singleton("ToastPlugin"):
		_plugin_available = true


func show_welcome() -> void:
	if _plugin_available:
		Engine.get_singleton("ToastPlugin").showToast("Hello admin")
