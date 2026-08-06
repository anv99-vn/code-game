extends Control

signal quit_confirmed
signal quit_cancelled


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$CardBg/VBox/BtnRow/CancelBtn.pressed.connect(_on_cancel)
	$CardBg/VBox/BtnRow/QuitBtn.pressed.connect(_on_quit)


func open() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = true
	get_tree().paused = true


func _on_cancel() -> void:
	get_tree().paused = false
	quit_cancelled.emit()
	_free_parent_layer()


func _on_quit() -> void:
	get_tree().paused = false
	quit_confirmed.emit()
	_free_parent_layer()
	get_tree().quit()


func _free_parent_layer() -> void:
	var p = get_parent()
	queue_free()
	if p is CanvasLayer and p.name != "PopupLayer":
		p.queue_free()
