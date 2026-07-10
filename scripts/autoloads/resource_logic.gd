extends Node

signal resources_updated
signal building_updated(building_name: String)
signal message_logged(text: String)

func _ready() -> void:
	ResourceManager.wood = 10
	ResourceManager.stone = 10
	ResourceManager.food = 10
	ResourceManager.gold = 0
	resources_updated.emit()

func gather_wood() -> void:
	ResourceManager.wood += ResourceManager.click_power
	resources_updated.emit()

func gather_stone() -> void:
	ResourceManager.stone += ResourceManager.click_power
	resources_updated.emit()

func gather_food() -> void:
	ResourceManager.food += ResourceManager.click_power
	resources_updated.emit()

func gather_gold() -> void:
	ResourceManager.gold += ResourceManager.click_power
	resources_updated.emit()

func buy_lumber_camp() -> bool:
	if ResourceManager.wood >= ResourceManager.lumber_camp_cost_wood:
		ResourceManager.wood -= ResourceManager.lumber_camp_cost_wood
		ResourceManager.lumber_camps += 1
		ResourceManager.lumber_camp_cost_wood = int(ResourceManager.lumber_camp_cost_wood * 1.5)
		resources_updated.emit()
		building_updated.emit("lumber_camp")
		message_logged.emit("Built Lumber Camp! Now generating +%d wood/sec." % ResourceManager.lumber_camps)
		return true
	return false

func buy_quarry() -> bool:
	if ResourceManager.stone >= ResourceManager.quarry_cost_stone:
		ResourceManager.stone -= ResourceManager.quarry_cost_stone
		ResourceManager.quarries += 1
		ResourceManager.quarry_cost_stone = int(ResourceManager.quarry_cost_stone * 1.5)
		resources_updated.emit()
		building_updated.emit("quarry")
		message_logged.emit("Built Quarry! Now generating +%d stone/sec." % ResourceManager.quarries)
		return true
	return false

func buy_farm() -> bool:
	if ResourceManager.food >= ResourceManager.farm_cost_food:
		ResourceManager.food -= ResourceManager.farm_cost_food
		ResourceManager.farms += 1
		ResourceManager.farm_cost_food = int(ResourceManager.farm_cost_food * 1.5)
		resources_updated.emit()
		building_updated.emit("farm")
		message_logged.emit("Built Farm! Now generating +%d food/sec." % ResourceManager.farms)
		return true
	return false

func buy_mine() -> bool:
	if ResourceManager.wood >= ResourceManager.mine_cost_wood and ResourceManager.stone >= ResourceManager.mine_cost_stone:
		ResourceManager.wood -= ResourceManager.mine_cost_wood
		ResourceManager.stone -= ResourceManager.mine_cost_stone
		ResourceManager.mines += 1
		ResourceManager.mine_cost_wood = int(ResourceManager.mine_cost_wood * 1.5)
		ResourceManager.mine_cost_stone = int(ResourceManager.mine_cost_stone * 1.5)
		resources_updated.emit()
		building_updated.emit("mine")
		message_logged.emit("Built Mine! Now generating +%d gold/sec." % ResourceManager.mines)
		return true
	return false

func upgrade_click_power() -> bool:
	if ResourceManager.gold >= ResourceManager.click_power_cost_gold:
		ResourceManager.gold -= ResourceManager.click_power_cost_gold
		ResourceManager.click_power += 1
		ResourceManager.click_power_cost_gold = int(ResourceManager.click_power_cost_gold * 2.0)
		resources_updated.emit()
		building_updated.emit("upgrade")
		message_logged.emit("Upgraded Click Power! Now gathering +%d per click." % ResourceManager.click_power)
		return true
	return false

func on_tick() -> void:
	ResourceManager.wood += ResourceManager.lumber_camps
	ResourceManager.stone += ResourceManager.quarries
	ResourceManager.food += ResourceManager.farms
	ResourceManager.gold += ResourceManager.mines
	resources_updated.emit()
