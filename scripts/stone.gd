extends StaticBody2D

signal stone_mined
signal mine_proximity_changed(nearby: bool)

var max_health: int = 4
var per_hit: int = 2
var bonus_on_deplete: int = 5
var respawn_time: float = 10.0

var _health: int = 0
var _player_nearby: bool = false
var _depleted: bool = false
var _respawn_at: float = 0.0

@onready var stone_sprite: Sprite2D = $StoneSprite
@onready var depleted_sprite: Sprite2D = $DepletedSprite
@onready var mine_area: Area2D = $MineArea
@onready var prompt_label: Label = $PromptLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var cooldown_label: Label = $CooldownLabel


func _ready() -> void:
	_load_config()
	_health = max_health
	add_to_group("stones")
	WorldManager.register_stone(global_position)
	if mine_area.is_connected("body_entered", _on_body_entered) == false:
		mine_area.body_entered.connect(_on_body_entered)
	if mine_area.is_connected("body_exited", _on_body_exited) == false:
		mine_area.body_exited.connect(_on_body_exited)
	InteractionManager.focus_changed.connect(_on_focus_changed)


func _load_config() -> void:
	var config := YAMLParser.load_file("res://data/resources.yml")
	if config.has("stone"):
		var stone_data: Dictionary = config["stone"]
		max_health = stone_data.get("max_health", max_health)
		per_hit = stone_data.get("per_hit", per_hit)
		bonus_on_deplete = stone_data.get("bonus_on_deplete", bonus_on_deplete)
		respawn_time = stone_data.get("respawn_time", respawn_time)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mine") and _player_nearby and not _depleted:
		_mine()


func _mine() -> void:
	_health -= 1
	_add_stone(per_hit)
	_shake()
	_hit_flash()
	health_bar.value = _health
	health_bar.visible = true
	if _health <= 0:
		_deplete()


func _hit_flash() -> void:
	var flash_tween := create_tween()
	flash_tween.tween_property(stone_sprite, "modulate", Color(1, 0.3, 0.3), 0.05)
	flash_tween.tween_property(stone_sprite, "modulate", Color.WHITE, 0.15)


func _add_stone(amount: int) -> void:
	ResourceManager.stone += amount
	ResourceLogic.resources_updated.emit()
	stone_mined.emit()


func _shake() -> void:
	var tween := create_tween()
	tween.tween_property(stone_sprite, "position:x", 3.0, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(stone_sprite, "position:x", -3.0, 0.05)
	tween.tween_property(stone_sprite, "position:x", 0.0, 0.05)


func _deplete() -> void:
	_depleted = true
	_add_stone(bonus_on_deplete)
	stone_sprite.visible = false
	depleted_sprite.visible = true
	prompt_label.visible = false
	health_bar.visible = false
	InteractionManager.unregister(self)
	_respawn_at = Time.get_ticks_msec() / 1000.0 + respawn_time
	cooldown_label.visible = _player_nearby


func _process(_delta: float) -> void:
	if not _depleted:
		return
	var remaining := _respawn_at - Time.get_ticks_msec() / 1000.0
	if remaining <= 0.0:
		cooldown_label.visible = false
		_respawn()
		return
	cooldown_label.text = "%ds" % ceil(remaining)
	cooldown_label.visible = _player_nearby


func _respawn() -> void:
	_health = max_health
	_depleted = false
	stone_sprite.visible = true
	depleted_sprite.visible = false
	health_bar.value = max_health
	cooldown_label.visible = false
	cooldown_label.text = ""
	if _player_nearby:
		InteractionManager.register(self)
	_respawn_glow(stone_sprite)


func _respawn_glow(sprite: Sprite2D) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/reborn_glow.gdshader")
	mat.set_shader_parameter("intensity", 1.0)
	sprite.material = mat
	var tween := create_tween()
	tween.tween_property(mat, "shader_parameter/intensity", 0.0, 0.3)
	tween.finished.connect(func() -> void:
		sprite.material = null
	)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		InteractionManager.set_player(body)
		InteractionManager.register(self)
		mine_proximity_changed.emit(true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		InteractionManager.unregister(self)
		prompt_label.visible = false
		health_bar.visible = false
		mine_proximity_changed.emit(false)


func _on_focus_changed(focused: Node2D) -> void:
	var is_focused: bool = focused == self
	if not _depleted and _player_nearby:
		prompt_label.visible = is_focused
		health_bar.visible = is_focused
