extends Node

const QUIT_POPUP_SCENE := preload("res://scenes/quit_popup.tscn")
var _popup: Control = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		show_quit_dialog()


func show_quit_dialog() -> void:
	if _popup and is_instance_valid(_popup):
		_popup.open()
		return
	_popup = QUIT_POPUP_SCENE.instantiate()
	_popup.visible = false
	_popup.process_mode = Node.PROCESS_MODE_ALWAYS
	_popup.z_index = 100
	get_tree().root.add_child(_popup)
	_popup.open()
