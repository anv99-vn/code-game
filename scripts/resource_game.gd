extends Control

@onready var wood_label: Label = $TopPanel/MarginContainer/ResourceHBox/WoodLabel
@onready var stone_label: Label = $TopPanel/MarginContainer/ResourceHBox/StoneLabel
@onready var food_label: Label = $TopPanel/MarginContainer/ResourceHBox/FoodLabel
@onready var gold_label: Label = $TopPanel/MarginContainer/ResourceHBox/GoldLabel


func _ready() -> void:
	pass


func _update_display(wood: int, stone: int, food: int, gold: int) -> void:
	wood_label.text = tr("RES_WOOD") % wood
	stone_label.text = tr("RES_STONE") % stone
	food_label.text = tr("RES_FOOD") % food
	gold_label.text = tr("RES_GOLD") % gold
