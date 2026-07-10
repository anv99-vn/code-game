extends CanvasLayer

@onready var logout_button: Button = %LogoutButton

func _ready() -> void:
	logout_button.pressed.connect(_on_logout_pressed)

func _on_logout_pressed() -> void:
	DirAccess.remove_absolute("user://login.cfg")
	get_tree().change_scene_to_file("res://scenes/login.tscn")
