extends Node

var _plugin_available: bool = false
var default_duration: int = 1


func _ready() -> void:
	if Engine.has_singleton("ToastPlugin"):
		_plugin_available = true


func show_welcome(username: String, duration: int = -1) -> void:
	if _plugin_available:
		if duration == -1:
			duration = default_duration
		var time = Time.get_time_string_from_system()
		var msg = "Welcome %s in %s" % [username, time]
		Engine.get_singleton("ToastPlugin").showToast(msg, duration)


func get_battery_percent() -> int:
	if not _plugin_available:
		return -1
	return Engine.get_singleton("ToastPlugin").getBatteryPercent()
