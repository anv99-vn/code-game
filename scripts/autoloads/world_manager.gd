extends Node

signal objects_generated

const STONE_SCENE := preload("res://scenes/stone.tscn")
const TREE_SCENE := preload("res://scenes/tree.tscn")

@export var map_bounds: Rect2 = Rect2(80, 120, 1000, 440)
@export var tree_count: int = 6
@export var stone_count: int = 4
@export var min_distance_from_player: float = 90.0
@export var min_distance_between: float = 70.0
@export var placement_attempts: int = 40

var stone_positions: Array[Vector2] = []
var tree_positions: Array[Vector2] = []

func register_stone(pos: Vector2) -> void:
	stone_positions.append(pos)

func register_tree(pos: Vector2) -> void:
	tree_positions.append(pos)

func clear_positions() -> void:
	stone_positions.clear()
	tree_positions.clear()

func clear_objects() -> void:
	for node in get_tree().get_nodes_in_group("stones"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("trees"):
		node.queue_free()
	clear_positions()

func generate_objects(parent: Node2D, player_pos: Vector2 = Vector2(400, 300)) -> void:
	clear_objects()
	var placed: Array[Vector2] = []
	var trees_made := 0
	var stones_made := 0
	for _i in tree_count:
		if _try_place(TREE_SCENE, parent, player_pos, placed) != null:
			trees_made += 1
	for _i in stone_count:
		if _try_place(STONE_SCENE, parent, player_pos, placed) != null:
			stones_made += 1
	print("WorldManager: generated %d trees, %d stones" % [trees_made, stones_made])
	objects_generated.emit()

func _try_place(scene: PackedScene, parent: Node2D, player_pos: Vector2, placed: Array[Vector2]) -> Node2D:
	for _attempt in placement_attempts:
		var pos := Vector2(
			randf_range(map_bounds.position.x, map_bounds.end.x),
			randf_range(map_bounds.position.y, map_bounds.end.y)
		)
		if pos.distance_to(player_pos) < min_distance_from_player:
			continue
		var too_close := false
		for other in placed:
			if pos.distance_to(other) < min_distance_between:
				too_close = true
				break
		if too_close:
			continue
		var node := scene.instantiate()
		node.position = pos
		parent.add_child(node)
		placed.append(pos)
		return node
	push_warning("WorldManager: could not find a valid spot after %d attempts" % placement_attempts)
	return null
