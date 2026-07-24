extends CharacterBody2D

@export var speed: float = 200.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0
@export var click_speed: float = 250.0
@export var arrival_distance: float = 4.0

var click_target: Vector2 = Vector2.INF
var _click_effect_scene: PackedScene = preload(AssetRegistry.SCENES_CLICK_EFFECT)

func _unhandled_input(event: InputEvent) -> void:
	if SettingsManager.click_to_move and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		click_target = get_global_mouse_position()
		_spawn_click_effect(click_target)

func _spawn_click_effect(pos: Vector2) -> void:
	var effect: Node2D = _click_effect_scene.instantiate() as Node2D
	effect.global_position = pos
	get_tree().current_scene.add_child(effect)

func _physics_process(delta: float) -> void:
	var input_vector: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	if input_vector != Vector2.ZERO:
		click_target = Vector2.INF
		velocity = velocity.lerp(input_vector * speed, acceleration * delta)
	elif click_target != Vector2.INF:
		var to_target: Vector2 = click_target - global_position
		if to_target.length() < arrival_distance:
			click_target = Vector2.INF
			velocity = velocity.lerp(Vector2.ZERO, friction * delta)
		else:
			velocity = velocity.lerp(to_target.normalized() * click_speed, acceleration * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
	move_and_slide()
