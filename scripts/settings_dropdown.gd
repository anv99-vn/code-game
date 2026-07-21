extends "res://scripts/base_dropdown.gd"

signal option_selected(action: String)


func update_toggle(action: String, state: bool) -> void:
	for child in get_children():
		if child is Button and child.get_meta("action", "") == action:
			child.text = child.get_meta("label", "") + ": " + ("ON" if state else "OFF")
			break


func _on_option_pressed(value: String) -> void:
	option_selected.emit(value)
	close()
