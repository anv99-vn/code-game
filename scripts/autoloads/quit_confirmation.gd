extends Node

const QUIT_POPUP_SCENE := preload("res://scenes/quit_popup.tscn")
var _popup: Control = null


func _ready() -> void:
	get_tree().get_root().go_back_requested.connect(show_quit_dialog)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		show_quit_dialog()


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
	_popup.quit_confirmed.connect(_on_popup_closed)
	_popup.quit_cancelled.connect(_on_popup_closed)
	var layer = _get_popup_layer()
	layer.add_child(_popup)
	_popup.open()


func _get_popup_layer() -> CanvasLayer:
	var root = get_tree().current_scene
	if root:
		var layer = root.get_node_or_null("PopupLayer")
		if layer:
			return layer
	return _create_fallback_layer()


func _create_fallback_layer() -> CanvasLayer:
	var layer = CanvasLayer.new()
	layer.layer = 100
	get_tree().root.add_child(layer)
	return layer


func _on_popup_closed() -> void:
	_popup = null
