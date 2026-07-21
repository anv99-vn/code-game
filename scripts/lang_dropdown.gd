@tool
extends "res://scripts/base_dropdown.gd"

signal language_selected(locale: String)


func _get_meta_key() -> String:
	return "locale"


func _on_open() -> void:
	_update_labels()
	_highlight_current(TranslationServer.get_locale().left(2))


func get_current_label(current_locale: String) -> String:
	for child in get_children():
		if child is Button and String(child.get_meta("locale", "")) == current_locale:
			return String(child.get_meta("label_key", ""))
	return ""


func _update_labels() -> void:
	for child in get_children():
		if child is Button:
			child.text = "  " + tr(child.get_meta("label_key", ""))


func _highlight_current(current_locale: String) -> void:
	for child in get_children():
		if child is Button:
			var is_current: bool = not current_locale.is_empty() and child.get_meta("locale", "") == current_locale
			var btn_normal: StyleBoxFlat = child.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			if btn_normal:
				btn_normal.bg_color = Color(1, 1, 1, 0.2) if is_current else Color(0.08, 0.16, 0.4, 0.95)
				child.add_theme_stylebox_override("normal", btn_normal)


func _on_option_pressed(value: String) -> void:
	language_selected.emit(value)
	close()
