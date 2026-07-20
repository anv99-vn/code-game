extends Node2D

@export var duration: float = 0.35
@export var radius: float = 12.0
@export var ring_width: float = 3.0
@export var effect_color: Color = Color(1, 1, 1, 0.8)

var _elapsed: float = 0.0

func _ready() -> void:
	z_index = 100

func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = _elapsed / duration
	if t >= 1.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t: float = _elapsed / duration
	var current_radius: float = radius * (0.3 + 0.7 * t)
	var alpha: float = effect_color.a * (1.0 - t)
	var col: Color = Color(effect_color.r, effect_color.g, effect_color.b, alpha)
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 64, col, ring_width)