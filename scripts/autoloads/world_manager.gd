extends Node

var stone_positions: Array[Vector2] = []
var tree_positions: Array[Vector2] = []

func register_stone(pos: Vector2) -> void:
	stone_positions.append(pos)

func register_tree(pos: Vector2) -> void:
	tree_positions.append(pos)

func clear_positions() -> void:
	stone_positions.clear()
	tree_positions.clear()