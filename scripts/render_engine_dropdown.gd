extends "res://scripts/base_dropdown.gd"

signal engine_selected(engine: String)

var current_engine: String = ""


func _get_meta_key() -> String:
	return "engine"


func _on_open() -> void:
	_update_labels()
	_highlight_current(current_engine)


func get_current_label(current: String) -> String:
	for child in get_children():
		if child is Button and String(child.get_meta("engine", "")) == current:
			return String(child.get_meta("label_key", ""))
	return ""


func _update_labels() -> void:
	for child in get_children():
		if child is Button:
			child.text = "  " + tr(child.get_meta("label_key", ""))


func _highlight_current(current: String) -> void:
	for child in get_children():
		if child is Button:
			var is_current: bool = not current.is_empty() and child.get_meta("engine", "") == current
			var btn_normal: StyleBoxFlat = child.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			if btn_normal:
				btn_normal.bg_color = Color(1, 1, 1, 0.2) if is_current else Color(0.08, 0.16, 0.4, 0.95)
				child.add_theme_stylebox_override("normal", btn_normal)


func _on_option_pressed(value: String) -> void:
	engine_selected.emit(value)
	close()
