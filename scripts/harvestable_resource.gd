class_name HarvestableResource
extends StaticBody2D

signal harvested(amount: int)
signal player_entered(body: Node2D)
signal player_exited(body: Node2D)
signal registered(pos: Vector2)
signal proximity_changed(nearby: bool)
signal depleted_changed(is_depleted: bool)

@export var main_sprite_path: NodePath
@export var depleted_sprite_path: NodePath
@export var interaction_area_path: NodePath
@export var prompt_label_path: NodePath
@export var health_bar_path: NodePath
@export var cooldown_label_path: NodePath
@export var respawn_bar_path: NodePath
@export var config_key: String = ""
@export var action: String = ""
@export var max_health: int = 3
@export var per_hit: int = 1
@export var bonus_on_deplete: int = 3
@export var respawn_time: float = 10.0
@export var health_per_respawn: int = 0
@export var max_health_cap: int = 0
@export var shake_amount: float = 3.0
@export var flash_color: Color = Color(1, 0.3, 0.3)

var _health: int = 0
var _player_nearby: bool = false
var _focused: bool = false
var _depleted: bool = false
var _respawn_at: float = 0.0
var _respawn_count: int = 0
var _base_max_health: int = 0

var _main_sprite: Sprite2D
var _depleted_sprite: Sprite2D
var _area: Area2D
var _prompt_label: Label
var _health_bar: ProgressBar
var _cooldown_label: Label
var _respawn_bar: ProgressBar

const GLOW_SHADER := preload(AssetRegistry.SHADERS_REBORN_GLOW)


func _ready() -> void:
	_main_sprite = get_node_or_null(main_sprite_path) as Sprite2D
	_depleted_sprite = get_node_or_null(depleted_sprite_path) as Sprite2D
	_area = get_node_or_null(interaction_area_path) as Area2D
	_prompt_label = get_node_or_null(prompt_label_path) as Label
	_health_bar = get_node_or_null(health_bar_path) as ProgressBar
	_cooldown_label = get_node_or_null(cooldown_label_path) as Label
	_respawn_bar = get_node_or_null(respawn_bar_path) as ProgressBar
	assert(_main_sprite != null, "HarvestableResource: main_sprite_path not set or not a Sprite2D on %s" % name)
	assert(_depleted_sprite != null, "HarvestableResource: depleted_sprite_path not set or not a Sprite2D on %s" % name)
	assert(_area != null, "HarvestableResource: interaction_area_path not set or not an Area2D on %s" % name)
	assert(_prompt_label != null, "HarvestableResource: prompt_label_path not set or not a Label on %s" % name)
	assert(_health_bar != null, "HarvestableResource: health_bar_path not set or not a ProgressBar on %s" % name)
	assert(_cooldown_label != null, "HarvestableResource: cooldown_label_path not set or not a Label on %s" % name)
	_load_config()
	_base_max_health = max_health
	_health = max_health
	_health_bar.max_value = max_health
	_health_bar.value = max_health
	if _respawn_bar:
		_respawn_bar.max_value = respawn_time
		_respawn_bar.value = 0.0
		_respawn_bar.visible = false
	_depleted_sprite.visible = false
	registered.emit(global_position)
	if not _area.body_entered.is_connected(_on_body_entered):
		_area.body_entered.connect(_on_body_entered)
	if not _area.body_exited.is_connected(_on_body_exited):
		_area.body_exited.connect(_on_body_exited)


func _load_config() -> void:
	if config_key.is_empty():
		return
	var config := YAMLParser.load_file(AssetRegistry.DATA_RESOURCES)
	if not config.has(config_key):
		return
	var data: Dictionary = config[config_key]
	max_health = int(data.get("max_health", max_health))
	per_hit = int(data.get("per_hit", per_hit))
	bonus_on_deplete = int(data.get("bonus_on_deplete", bonus_on_deplete))
	respawn_time = float(data.get("respawn_time", respawn_time))
	health_per_respawn = int(data.get("health_per_respawn", health_per_respawn))
	max_health_cap = int(data.get("max_health_cap", max_health_cap))


func _unhandled_input(event: InputEvent) -> void:
	if action.is_empty():
		return
	if event.is_action_pressed(action) and _player_nearby and _focused and not _depleted:
		_interact()


func _interact() -> void:
	_health -= 1
	harvested.emit(per_hit)
	_shake()
	_hit_flash()
	_health_bar.value = _health
	_health_bar.visible = true
	if _health <= 0:
		_deplete()


func _hit_flash() -> void:
	var flash_tween := create_tween()
	flash_tween.tween_property(_main_sprite, "modulate", flash_color, 0.05)
	flash_tween.tween_property(_main_sprite, "modulate", Color.WHITE, 0.15)


func _shake() -> void:
	var tween := create_tween()
	tween.tween_property(_main_sprite, "position:x", shake_amount, 0.05).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_main_sprite, "position:x", -shake_amount, 0.05)
	tween.tween_property(_main_sprite, "position:x", 0.0, 0.05)


func _deplete() -> void:
	_depleted = true
	depleted_changed.emit(true)
	harvested.emit(bonus_on_deplete)
	_main_sprite.visible = false
	_depleted_sprite.visible = true
	_prompt_label.visible = false
	_health_bar.visible = false
	_respawn_at = Time.get_ticks_msec() / 1000.0 + respawn_time
	if _respawn_bar:
		_respawn_bar.value = 0.0
		_respawn_bar.max_value = respawn_time
		_respawn_bar.visible = _player_nearby
	else:
		_cooldown_label.visible = _player_nearby


func _process(_delta: float) -> void:
	if not _depleted:
		return
	var remaining := _respawn_at - Time.get_ticks_msec() / 1000.0
	if remaining <= 0.0:
		if _respawn_bar:
			_respawn_bar.visible = false
		else:
			_cooldown_label.visible = false
		_respawn()
		return
	if _respawn_bar:
		_respawn_bar.value = respawn_time - remaining
		_respawn_bar.visible = _player_nearby
	else:
		_cooldown_label.text = "%ds" % ceil(remaining)
		_cooldown_label.visible = _player_nearby


func _respawn() -> void:
	_respawn_count += 1
	if health_per_respawn > 0:
		max_health = _base_max_health + health_per_respawn * _respawn_count
		if max_health_cap > 0:
			max_health = min(max_health, max_health_cap)
	_health = max_health
	_depleted = false
	depleted_changed.emit(false)
	_main_sprite.visible = true
	_depleted_sprite.visible = false
	_health_bar.max_value = max_health
	_health_bar.value = max_health
	if _respawn_bar:
		_respawn_bar.visible = false
		_respawn_bar.value = 0.0
	else:
		_cooldown_label.visible = false
		_cooldown_label.text = ""
	_respawn_glow(_main_sprite)


func _respawn_glow(sprite: Sprite2D) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = GLOW_SHADER
	mat.set_shader_parameter("intensity", 1.0)
	sprite.material = mat
	var tween := create_tween()
	tween.bind_node(sprite)
	tween.tween_property(mat, "shader_parameter/intensity", 0.0, 0.3)
	tween.finished.connect(func() -> void:
		if is_instance_valid(sprite):
			sprite.material = null
	)


func set_focused(focused: bool) -> void:
	_focused = focused
	if _depleted or not _player_nearby:
		_prompt_label.visible = false
		_health_bar.visible = false
		return
	_prompt_label.visible = focused
	_health_bar.visible = focused


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		player_entered.emit(body)
		proximity_changed.emit(true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		player_exited.emit(body)
		_prompt_label.visible = false
		_health_bar.visible = false
		if _respawn_bar:
			_respawn_bar.visible = false
		proximity_changed.emit(false)
