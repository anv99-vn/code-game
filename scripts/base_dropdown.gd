extends VBoxContainer

signal closed


func _ready() -> void:
	for child in get_children():
		if child is Button:
			var key := _get_meta_key()
			child.pressed.connect(_on_option_pressed.bind(String(child.get_meta(key, ""))))


func open() -> void:
	_on_open()
	visible = true
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func close() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.1)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	tween.tween_callback(func():
		visible = false
		closed.emit()
	)


func _get_meta_key() -> String:
	return "action"


func _on_open() -> void:
	pass


func _on_option_pressed(_value: String) -> void:
	pass
