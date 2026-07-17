extends Node

signal resources_updated(wood: int, stone: int, food: int, gold: int)

var wood: int = 0
var stone: int = 0
var food: int = 0
var gold: int = 0

const RESOURCE_GROUPS := {"trees": "wood", "stones": "stone", "gold_sources": "gold"}


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func add_resource(type: String, amount: int) -> void:
	match type:
		"wood": wood += amount
		"stone": stone += amount
		"food": food += amount
		"gold": gold += amount
	_emit_update()


func reset() -> void:
	wood = 0
	stone = 0
	food = 0
	gold = 0
	_emit_update()


func _emit_update() -> void:
	resources_updated.emit(wood, stone, food, gold)


func _on_node_added(node: Node) -> void:
	for group in RESOURCE_GROUPS:
		if node.is_in_group(group) and node.has_signal("harvested"):
			var bound := _on_harvested.bind(RESOURCE_GROUPS[group])
			if not node.harvested.is_connected(bound):
				node.harvested.connect(bound)
	if node.is_in_group("resource_display") and node.has_method("_update_display"):
		if not resources_updated.is_connected(node._update_display):
			resources_updated.connect(node._update_display)
			node._update_display(wood, stone, food, gold)


func _on_harvested(amount: int, type: String) -> void:
	add_resource(type, amount)
