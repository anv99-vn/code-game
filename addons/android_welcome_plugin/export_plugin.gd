@tool
extends EditorPlugin

var _export_plugin: AndroidExportPlugin


func _enter_tree() -> void:
	print("[WelcomePlugin] _enter_tree - registering export plugin")
	_export_plugin = AndroidExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	const _PLUGIN_NAME := "welcomeplugin"
	const _RELEASE_AAR := "android_welcome_plugin/bin/release/welcomeplugin-release.aar"
	const _DEBUG_AAR := "android_welcome_plugin/bin/debug/welcomeplugin-debug.aar"

	func _supports_platform(platform: Object) -> bool:
		var supported := platform is EditorExportPlatformAndroid
		print("[WelcomePlugin] _supports_platform -> ", supported)
		return supported

	func _get_android_libraries(_platform: Object, debug: bool) -> PackedStringArray:
		var aar := _DEBUG_AAR if debug else _RELEASE_AAR
		print("[WelcomePlugin] _get_android_libraries returning: ", aar)
		return PackedStringArray([aar])

	func _get_android_dependencies(_platform: Object, _debug: bool) -> PackedStringArray:
		return PackedStringArray()

	func _get_name() -> String:
		return _PLUGIN_NAME