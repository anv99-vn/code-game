@tool
extends VBoxContainer

signal option_selected(action: String)

var options: Array[Dictionary] = []:
	set(val):
		options = val
		if is_inside_tree():
			_rebuild.call_deferred()


func _ready() -> void:
	_rebuild.call_deferred()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	if options.is_empty():
		return

	for opt in options:
		var btn := Button.new()
		var action: String = opt.get("action", "")
		var is_toggle: bool = opt.get("toggle", false)
		var state: bool = opt.get("state", false)
		if is_toggle:
			btn.text = opt.get("label", "") + ": " + ("ON" if state else "OFF")
		else:
			btn.text = opt.get("label", "")
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var icon_path: String = opt.get("icon", "")
		if not icon_path.is_empty():
			btn.icon = load(icon_path)
		btn.pressed.connect(_on_option_pressed.bind(action))
		add_child(btn)


func open() -> void:
	_rebuild()
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
	)


func _on_option_pressed(action: String) -> void:
	option_selected.emit(action)
	close()
