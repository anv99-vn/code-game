extends Node

# Resources
var wood: int = 0
var stone: int = 0
var food: int = 0
var gold: int = 0

func _ready() -> void:
	_load_asset_packs()

func _load_asset_packs() -> void:
	var packs := ["assets_core.pck"]
	for pack in packs:
		var path := "res://" + pack
		if FileAccess.file_exists(path):
			var ok := ProjectSettings.load_resource_pack(path)
			if ok:
				print("Loaded pack: ", pack)
			else:
				push_error("Failed to load pack: ", pack)
