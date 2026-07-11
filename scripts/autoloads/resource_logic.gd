extends Node

signal resources_updated
signal building_updated(building_name: String)
signal message_logged(text: String)

var _tick_timer: Timer
const TICK_INTERVAL: float = 1.0

func _ready() -> void:
	_tick_timer = Timer.new()
	_tick_timer.wait_time = TICK_INTERVAL
	_tick_timer.autostart = false
	_tick_timer.timeout.connect(on_tick)
	add_child(_tick_timer)
	resources_updated.emit()

func start_passive_income() -> void:
	if not _tick_timer.is_inside_tree():
		return
	_tick_timer.start()

func stop_passive_income() -> void:
	_tick_timer.stop()

func reset_resources() -> void:
	ResourceManager.wood = 50
	ResourceManager.stone = 50
	ResourceManager.food = 50
	ResourceManager.gold = 50
	ResourceManager.click_power = 1
	ResourceManager.lumber_camps = 1
	ResourceManager.quarries = 1
	ResourceManager.farms = 1
	ResourceManager.mines = 1
	ResourceManager.lumber_camp_cost_wood = 50
	ResourceManager.quarry_cost_stone = 50
	ResourceManager.farm_cost_food = 50
	ResourceManager.mine_cost_wood = 150
	ResourceManager.mine_cost_stone = 150
	ResourceManager.click_power_cost_gold = 25
	resources_updated.emit()

func gather_wood() -> void:
	var before := ResourceManager.wood
	ResourceManager.wood += ResourceManager.click_power
	print("[Wood] Gathered +%d (click_power=%d) | %d -> %d" % [ResourceManager.click_power, ResourceManager.click_power, before, ResourceManager.wood])
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
		var before := ResourceManager.wood
		ResourceManager.wood -= ResourceManager.lumber_camp_cost_wood
		print("[Wood] Spent %d on Lumber Camp | %d -> %d" % [ResourceManager.lumber_camp_cost_wood, before, ResourceManager.wood])
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
		var before_wood := ResourceManager.wood
		ResourceManager.wood -= ResourceManager.mine_cost_wood
		print("[Wood] Spent %d on Mine | %d -> %d" % [ResourceManager.mine_cost_wood, before_wood, ResourceManager.wood])
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
	if ResourceManager.lumber_camps > 0:
		var before := ResourceManager.wood
		ResourceManager.wood += ResourceManager.lumber_camps
		print("[Wood] Passive +%d (lumber_camps=%d) | %d -> %d" % [ResourceManager.lumber_camps, ResourceManager.lumber_camps, before, ResourceManager.wood])
	ResourceManager.stone += ResourceManager.quarries
	ResourceManager.food += ResourceManager.farms
	ResourceManager.gold += ResourceManager.mines
	resources_updated.emit()
