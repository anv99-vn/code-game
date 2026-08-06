extends Control

signal quit_confirmed
signal quit_cancelled


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$CardBg/VBox/BtnRow/CancelBtn.pressed.connect(_on_cancel)
	$CardBg/VBox/BtnRow/QuitBtn.pressed.connect(_on_quit)


func open() -> void:
	visible = true
	get_tree().paused = true


func _on_cancel() -> void:
	get_tree().paused = false
	visible = false
	quit_cancelled.emit()


func _on_quit() -> void:
	get_tree().paused = false
	quit_confirmed.emit()
	get_tree().quit()
