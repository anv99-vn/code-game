extends CharacterBody2D

@export var speed: float = 200.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0

func _physics_process(_delta: float) -> void:
	var input_vector: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_vector != Vector2.ZERO:
		velocity = velocity.lerp(input_vector * speed, acceleration * _delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction * _delta)
	move_and_slide()
