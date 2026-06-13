class_name TowerBullet
extends Node2D

const SPEED := 480.0
const HIT_RADIUS := 7.0

var _target: Creep
var _damage: float = 0.0


func launch(from: Vector2, target: Creep, damage: float) -> void:
	global_position = from
	_target = target
	_damage = damage
	queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		queue_free()
		return
	var to_target: Vector2 = _target.global_position - global_position
	var dist: float = to_target.length()
	if dist <= HIT_RADIUS:
		_target.take_damage(_damage)
		queue_free()
		return
	global_position += to_target / dist * SPEED * delta
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(0.98, 0.86, 0.28, 0.35))
	draw_circle(Vector2.ZERO, 2.8, Color(1.0, 0.92, 0.45))
	draw_circle(Vector2.ZERO, 1.2, Color(1.0, 0.98, 0.82))
