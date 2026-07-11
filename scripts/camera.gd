extends Camera2D

@export var smooth_speed: float = 8.0
@export var easing: float = -2.0

var target_position: Vector2 = Vector2.ZERO
var player_ref: Node2D

func _ready() -> void:
	player_ref = get_parent()
	target_position = player_ref.global_position

func _physics_process(delta: float) -> void:
	target_position = player_ref.global_position
	var t: float = clamp(smooth_speed * delta, 0.0, 1.0)
	var eased_t: float = ease(t, easing)
	global_position = global_position.lerp(target_position, eased_t)