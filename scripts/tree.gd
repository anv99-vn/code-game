extends StaticBody2D

signal tree_chopped
signal chop_proximity_changed(nearby: bool)

@export var max_health: int = 3
@export var wood_per_hit: int = 2
@export var wood_bonus_on_fall: int = 5
@export var respawn_time: float = 8.0

var _health: int = 0
var _player_nearby: bool = false
var _felled: bool = false
var _respawn_at: float = 0.0

@onready var tree_sprite: Sprite2D = $TreeSprite
@onready var stump_sprite: Sprite2D = $StumpSprite
@onready var chop_area: Area2D = $ChopArea
@onready var prompt_label: Label = $PromptLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var cooldown_label: Label = $CooldownLabel


func _ready() -> void:
	_health = max_health
	_felled = false
	tree_sprite.visible = true
	stump_sprite.visible = false
	prompt_label.visible = false
	health_bar.max_value = max_health
	health_bar.value = max_health
	health_bar.visible = false
	cooldown_label.visible = false
	add_to_group("trees")
	WorldManager.register_tree(global_position)
	if chop_area.is_connected("body_entered", _on_body_entered) == false:
		chop_area.body_entered.connect(_on_body_entered)
	if chop_area.is_connected("body_exited", _on_body_exited) == false:
		chop_area.body_exited.connect(_on_body_exited)
	InteractionManager.focus_changed.connect(_on_focus_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("chop") and _player_nearby and not _felled:
		_chop()


func _chop() -> void:
	_health -= 1
	_add_wood(wood_per_hit)
	_shake()
	_hit_flash()
	health_bar.value = _health
	health_bar.visible = true
	if _health <= 0:
		_fell()


func _hit_flash() -> void:
	var flash_tween := create_tween()
	flash_tween.tween_property(tree_sprite, "modulate", Color(1, 0.3, 0.3), 0.05)
	flash_tween.tween_property(tree_sprite, "modulate", Color.WHITE, 0.15)


func _add_wood(amount: int) -> void:
	ResourceManager.wood += amount
	ResourceLogic.resources_updated.emit()
	tree_chopped.emit()


func _shake() -> void:
	var tween := create_tween()
	tween.tween_property(tree_sprite, "position:x", 4.0, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tree_sprite, "position:x", -4.0, 0.05)
	tween.tween_property(tree_sprite, "position:x", 0.0, 0.05)


func _fell() -> void:
	_felled = true
	_add_wood(wood_bonus_on_fall)
	tree_sprite.visible = false
	stump_sprite.visible = true
	prompt_label.visible = false
	health_bar.visible = false
	InteractionManager.unregister(self)
	_respawn_at = Time.get_ticks_msec() / 1000.0 + respawn_time
	cooldown_label.visible = _player_nearby


func _process(_delta: float) -> void:
	if not _felled:
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
	_felled = false
	tree_sprite.visible = true
	stump_sprite.visible = false
	health_bar.value = max_health
	cooldown_label.visible = false
	cooldown_label.text = ""
	if _player_nearby:
		InteractionManager.register(self)
	_respawn_glow(tree_sprite)


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
		chop_proximity_changed.emit(true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		InteractionManager.unregister(self)
		prompt_label.visible = false
		health_bar.visible = false
		chop_proximity_changed.emit(false)


func _on_focus_changed(focused: Node2D) -> void:
	var is_focused: bool = focused == self
	if not _felled and _player_nearby:
		prompt_label.visible = is_focused
		health_bar.visible = is_focused
