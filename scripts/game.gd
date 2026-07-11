extends Node2D

func _ready() -> void:
	var player: CharacterBody2D = $Player
	WorldManager.generate_objects(self, player.global_position)
