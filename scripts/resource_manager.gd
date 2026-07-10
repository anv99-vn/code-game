extends Node

signal resources_updated
signal building_updated(building_name: String)
signal message_logged(text: String)

# Resources
var wood: int = 0
var stone: int = 0
var food: int = 0
var gold: int = 0

# Click power (base gather amount)
var click_power: int = 1

# Buildings (counts)
var lumber_camps: int = 0
var quarries: int = 0
var farms: int = 0
var mines: int = 0

# Building costs
var lumber_camp_cost_wood: int = 50
var quarry_cost_stone: int = 50
var farm_cost_food: int = 50
var mine_cost_wood: int = 150
var mine_cost_stone: int = 150

# Upgrade costs
var click_power_cost_gold: int = 25

func _ready() -> void:
	# Give starting resources so player can do something immediately
	wood = 10
	stone = 10
	food = 10
	gold = 0
	resources_updated.emit()

func gather_wood() -> void:
	wood += click_power
	resources_updated.emit()

func gather_stone() -> void:
	stone += click_power
	resources_updated.emit()

func gather_food() -> void:
	food += click_power
	resources_updated.emit()

func gather_gold() -> void:
	gold += click_power
	resources_updated.emit()

func buy_lumber_camp() -> bool:
	if wood >= lumber_camp_cost_wood:
		wood -= lumber_camp_cost_wood
		lumber_camps += 1
		lumber_camp_cost_wood = int(lumber_camp_cost_wood * 1.5)
		resources_updated.emit()
		building_updated.emit("lumber_camp")
		message_logged.emit("Built Lumber Camp! Now generating +%d wood/sec." % lumber_camps)
		return true
	return false

func buy_quarry() -> bool:
	if stone >= quarry_cost_stone:
		stone -= quarry_cost_stone
		quarries += 1
		quarry_cost_stone = int(quarry_cost_stone * 1.5)
		resources_updated.emit()
		building_updated.emit("quarry")
		message_logged.emit("Built Quarry! Now generating +%d stone/sec." % quarries)
		return true
	return false

func buy_farm() -> bool:
	if food >= farm_cost_food:
		food -= farm_cost_food
		farms += 1
		farm_cost_food = int(farm_cost_food * 1.5)
		resources_updated.emit()
		building_updated.emit("farm")
		message_logged.emit("Built Farm! Now generating +%d food/sec." % farms)
		return true
	return false

func buy_mine() -> bool:
	if wood >= mine_cost_wood and stone >= mine_cost_stone:
		wood -= mine_cost_wood
		stone -= mine_cost_stone
		mines += 1
		mine_cost_wood = int(mine_cost_wood * 1.5)
		mine_cost_stone = int(mine_cost_stone * 1.5)
		resources_updated.emit()
		building_updated.emit("mine")
		message_logged.emit("Built Mine! Now generating +%d gold/sec." % mines)
		return true
	return false

func upgrade_click_power() -> bool:
	if gold >= click_power_cost_gold:
		gold -= click_power_cost_gold
		click_power += 1
		click_power_cost_gold = int(click_power_cost_gold * 2.0)
		resources_updated.emit()
		building_updated.emit("upgrade")
		message_logged.emit("Upgraded Click Power! Now gathering +%d per click." % click_power)
		return true
	return false

func _on_tick() -> void:
	wood += lumber_camps
	stone += quarries
	food += farms
	gold += mines
	resources_updated.emit()
