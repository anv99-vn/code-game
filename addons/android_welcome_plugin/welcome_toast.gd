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
	if _plugin_available:
		return Engine.get_singleton("ToastPlugin").getBatteryPercent()
	if OS.get_name() == "Windows":
		return _get_windows_battery_percent()
	return -1


func _get_windows_battery_percent() -> int:
	var output: Array = []
	var exit_code := OS.execute(
		"powershell.exe",
		[
			"-NoLogo",
			"-NoProfile",
			"-NonInteractive",
			"-Command",
			"$b = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue; "
				+ "if ($b) { [int](($b | Measure-Object EstimatedChargeRemaining -Average).Average) }",
		],
		output,
		true
	)
	if exit_code != 0 or output.is_empty():
		return -1
	var value := str(output[0]).strip_edges()
	if not value.is_valid_int():
		return -1
	return clampi(value.to_int(), 0, 100)
