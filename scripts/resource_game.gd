extends Control

@onready var wood_label: Label = $TopPanel/MarginContainer/ResourceHBox/WoodLabel
@onready var stone_label: Label = $TopPanel/MarginContainer/ResourceHBox/StoneLabel
@onready var food_label: Label = $TopPanel/MarginContainer/ResourceHBox/FoodLabel
@onready var gold_label: Label = $TopPanel/MarginContainer/ResourceHBox/GoldLabel

func _ready() -> void:
	ResourceLogic.resources_updated.connect(_update_ui)

	_update_ui()

func _update_ui() -> void:
	wood_label.text = tr("RES_WOOD") % ResourceManager.wood
	stone_label.text = tr("RES_STONE") % ResourceManager.stone
	food_label.text = tr("RES_FOOD") % ResourceManager.food
	gold_label.text = tr("RES_GOLD") % ResourceManager.gold
