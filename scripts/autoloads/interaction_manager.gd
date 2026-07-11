extends Node

signal focus_changed(focused: Node2D)

var _nearby: Array[Node2D] = []
var _player: Node2D = null
var _focused: Node2D = null


func set_player(player: Node2D) -> void:
	_player = player


func register(obj: Node2D) -> void:
	if obj not in _nearby:
		_nearby.append(obj)
	_update_focus()


func unregister(obj: Node2D) -> void:
	_nearby.erase(obj)
	_update_focus()


func get_focused() -> Node2D:
	return _focused


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
		_focused = closest
		focus_changed.emit(_focused)
