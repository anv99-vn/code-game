@tool
extends VBoxContainer

signal language_selected(locale: String)

var options: Array[Dictionary] = []:
	set(val):
		options = val
		if is_inside_tree():
			_rebuild()


func _ready() -> void:
	pivot_offset = Vector2(50, 0)
	_rebuild()


func _rebuild(current_locale: String = "") -> void:
	for child in get_children():
		child.queue_free()

	if options.is_empty():
		return

	for opt in options:
		var btn := Button.new()
		btn.text = opt.get("label", opt.get("locale", ""))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not current_locale.is_empty() and opt.get("locale") == current_locale:
			btn.visible = false
		var locale: String = opt.get("locale", "")
		btn.pressed.connect(_on_option_pressed.bind(locale))
		add_child(btn)


func open(current_locale: String = "") -> void:
	_rebuild(current_locale)
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


func _on_option_pressed(locale: String) -> void:
	language_selected.emit(locale)
	close()
