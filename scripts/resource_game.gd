extends Control

@onready var wood_label: Label = $TopPanel/MarginContainer/ResourceHBox/WoodLabel
@onready var stone_label: Label = $TopPanel/MarginContainer/ResourceHBox/StoneLabel
@onready var food_label: Label = $TopPanel/MarginContainer/ResourceHBox/FoodLabel
@onready var gold_label: Label = $TopPanel/MarginContainer/ResourceHBox/GoldLabel

@onready var wood_button: Button = $ContentHBox/GatherPanel/MarginContainer/GatherVBox/WoodRow/WoodButton
@onready var stone_button: Button = $ContentHBox/GatherPanel/MarginContainer/GatherVBox/StoneRow/StoneButton
@onready var food_button: Button = $ContentHBox/GatherPanel/MarginContainer/GatherVBox/FoodRow/FoodButton
@onready var gold_button: Button = $ContentHBox/GatherPanel/MarginContainer/GatherVBox/GoldRow/GoldButton

@onready var lumber_camp_button: Button = $ContentHBox/BuildingsPanel/MarginContainer/BuildingsVBox/LumberRow/LumberCampButton
@onready var quarry_button: Button = $ContentHBox/BuildingsPanel/MarginContainer/BuildingsVBox/QuarryRow/QuarryButton
@onready var farm_button: Button = $ContentHBox/BuildingsPanel/MarginContainer/BuildingsVBox/FarmRow/FarmButton
@onready var mine_button: Button = $ContentHBox/BuildingsPanel/MarginContainer/BuildingsVBox/MineRow/MineButton
@onready var upgrade_button: Button = $ContentHBox/BuildingsPanel/MarginContainer/BuildingsVBox/UpgradeRow/UpgradeButton

@onready var message_label: Label = $BottomPanel/MarginContainer/MessageLabel
@onready var tick_timer: Timer = $TickTimer

func _ready() -> void:
	wood_button.pressed.connect(_on_wood_pressed)
	stone_button.pressed.connect(_on_stone_pressed)
	food_button.pressed.connect(_on_food_pressed)
	gold_button.pressed.connect(_on_gold_pressed)

	lumber_camp_button.pressed.connect(_on_lumber_camp_pressed)
	quarry_button.pressed.connect(_on_quarry_pressed)
	farm_button.pressed.connect(_on_farm_pressed)
	mine_button.pressed.connect(_on_mine_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)

	ResourceManager.resources_updated.connect(_update_ui)
	ResourceManager.message_logged.connect(_show_message)

	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()

	_update_ui()

func _update_ui() -> void:
	wood_label.text = "Wood: %d" % ResourceManager.wood
	stone_label.text = "Stone: %d" % ResourceManager.stone
	food_label.text = "Food: %d" % ResourceManager.food
	gold_label.text = "Gold: %d" % ResourceManager.gold

	lumber_camp_button.text = "Lumber Camp (%d wood) - Own: %d" % [ResourceManager.lumber_camp_cost_wood, ResourceManager.lumber_camps]
	quarry_button.text = "Quarry (%d stone) - Own: %d" % [ResourceManager.quarry_cost_stone, ResourceManager.quarries]
	farm_button.text = "Farm (%d food) - Own: %d" % [ResourceManager.farm_cost_food, ResourceManager.farms]
	mine_button.text = "Mine (%d wood, %d stone) - Own: %d" % [ResourceManager.mine_cost_wood, ResourceManager.mine_cost_stone, ResourceManager.mines]
	upgrade_button.text = "Click Power (%d gold) - Level: %d" % [ResourceManager.click_power_cost_gold, ResourceManager.click_power]

	lumber_camp_button.disabled = ResourceManager.wood < ResourceManager.lumber_camp_cost_wood
	quarry_button.disabled = ResourceManager.stone < ResourceManager.quarry_cost_stone
	farm_button.disabled = ResourceManager.food < ResourceManager.farm_cost_food
	mine_button.disabled = ResourceManager.wood < ResourceManager.mine_cost_wood or ResourceManager.stone < ResourceManager.mine_cost_stone
	upgrade_button.disabled = ResourceManager.gold < ResourceManager.click_power_cost_gold

func _show_message(text: String) -> void:
	message_label.text = text
	await get_tree().create_timer(3.0).timeout
	if message_label.text == text:
		message_label.text = ""

func _on_wood_pressed() -> void:
	ResourceManager.gather_wood()

func _on_stone_pressed() -> void:
	ResourceManager.gather_stone()

func _on_food_pressed() -> void:
	ResourceManager.gather_food()

func _on_gold_pressed() -> void:
	ResourceManager.gather_gold()

func _on_lumber_camp_pressed() -> void:
	if not ResourceManager.buy_lumber_camp():
		_show_message("Not enough wood!")

func _on_quarry_pressed() -> void:
	if not ResourceManager.buy_quarry():
		_show_message("Not enough stone!")

func _on_farm_pressed() -> void:
	if not ResourceManager.buy_farm():
		_show_message("Not enough food!")

func _on_mine_pressed() -> void:
	if not ResourceManager.buy_mine():
		_show_message("Not enough resources for Mine!")

func _on_upgrade_pressed() -> void:
	if not ResourceManager.upgrade_click_power():
		_show_message("Not enough gold!")

func _on_tick() -> void:
	ResourceManager._on_tick()
