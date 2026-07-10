extends Node

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
