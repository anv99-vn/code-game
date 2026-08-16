extends Node

const PLUGIN_NAME := "AndroidWelcomePlugin"
const DEFAULT_DURATION := 1

var default_duration: int = DEFAULT_DURATION
var _plugin: Object


func _ready() -> void:
	if Engine.has_singleton(PLUGIN_NAME):
		_plugin = Engine.get_singleton(PLUGIN_NAME)


func show_welcome(username: String, duration: int = -1) -> void:
	if _plugin == null:
		return
	var toast_duration := default_duration if duration < 0 else duration
	var current_time := Time.get_time_string_from_system()
	var message := "Welcome %s in %s" % [username, current_time]
	_plugin.showToast(message, toast_duration)


func get_battery_percent() -> int:
	if _plugin != null:
		return _plugin.getBatteryPercent()
	if OS.get_name() == "Windows":
		return _get_windows_battery_percent()
	return -1


func is_battery_charging() -> int:
	if _plugin != null:
		return _plugin.isBatteryCharging()
	if OS.get_name() == "Windows":
		return _get_windows_charging_state()
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


func _get_windows_charging_state() -> int:
	var output: Array = []
	var exit_code := OS.execute(
		"powershell.exe",
		[
			"-NoLogo",
			"-NoProfile",
			"-NonInteractive",
			"-Command",
			"$b = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue; "
				+ "if ($b) { if ($b.BatteryStatus -in 2, 6, 7, 8, 9) { 1 } else { 0 } }",
		],
		output,
		true
	)
	if exit_code != 0 or output.is_empty():
		return -1
	var value := str(output[0]).strip_edges()
	if not value.is_valid_int():
		return -1
	return value.to_int()
