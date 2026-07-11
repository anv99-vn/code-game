extends Node

signal resources_updated

func _ready() -> void:
	resources_updated.emit()

func reset_resources() -> void:
	ResourceManager.wood = 0
	ResourceManager.stone = 0
	ResourceManager.food = 0
	ResourceManager.gold = 0
	resources_updated.emit()
