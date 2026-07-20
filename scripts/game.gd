extends Node2D

@export var map_bounds: Rect2 = Rect2(80, 120, 1000, 440)
@export var tree_count: int = 6
@export var stone_count: int = 4
@export var gold_source_count: int = 3
@export var min_distance_from_player: float = 90.0
@export var min_distance_between: float = 70.0
@export var placement_attempts: int = 40

var _tree_scene: PackedScene = null
var _stone_scene: PackedScene = null
var _gold_source_scene: PackedScene = null


func _ready() -> void:
	_tree_scene = load("res://scenes/tree.tscn")
	_stone_scene = load("res://scenes/stone.tscn")
	_gold_source_scene = load("res://scenes/gold_source.tscn")
	call_deferred("_generate_objects")


func _generate_objects() -> void:
	var player := get_node_or_null("Player") as CharacterBody2D
	if not player:
		return
	var player_pos := player.global_position
	var placed: Array[Vector2] = []
	for _i in tree_count:
		_try_place(_tree_scene, player_pos, placed)
	for _i in stone_count:
		_try_place(_stone_scene, player_pos, placed)
	for _i in gold_source_count:
		_try_place(_gold_source_scene, player_pos, placed)


func _try_place(scene: PackedScene, player_pos: Vector2, placed: Array[Vector2]) -> void:
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
		add_child(node)
		placed.append(pos)
		return
	push_warning("game.gd: could not find a valid spot after %d attempts" % placement_attempts)
