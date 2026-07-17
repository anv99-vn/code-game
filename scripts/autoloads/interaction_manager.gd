extends Node

signal focus_changed(focused: Node2D)

var _nearby: Array[Node2D] = []
var _player: Node2D = null
var _focused: Node2D = null

const INTERACTABLE_GROUPS := ["trees", "stones", "gold_sources"]


func get_focused() -> Node2D:
	return _focused


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	for group in INTERACTABLE_GROUPS:
		if node.is_in_group(group):
			if node.has_signal("player_entered") and not node.player_entered.is_connected(_on_player_entered):
				node.player_entered.connect(_on_player_entered.bind(node))
			if node.has_signal("player_exited") and not node.player_exited.is_connected(_on_player_exited):
				node.player_exited.connect(_on_player_exited.bind(node))
			return
	if node.is_in_group("game_ui") and node.has_method("_on_focus_changed"):
		if not focus_changed.is_connected(node._on_focus_changed):
			focus_changed.connect(node._on_focus_changed)


func _on_player_entered(body: Node2D, node: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		if node not in _nearby:
			_nearby.append(node)
		_update_focus()


func _on_player_exited(_body: Node2D, node: Node2D) -> void:
	_nearby.erase(node)
	_update_focus()


func _update_focus() -> void:
	var closest: Node2D = null
	var closest_dist: float = INF
	for obj in _nearby:
		if not is_instance_valid(obj):
			continue
		if _player:
			var dist: float = _player.global_position.distance_to(obj.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = obj
		else:
			closest = obj
			break
	if closest != _focused:
		if _focused and _focused.has_method("set_focused"):
			_focused.set_focused(false)
		_focused = closest
		if _focused and _focused.has_method("set_focused"):
			_focused.set_focused(true)
		focus_changed.emit(_focused)
