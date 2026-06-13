class_name InkPool
extends RefCounted

var ink_type: InkType.Type
var max_capacity: float
var regen_rate: float
var current: float


func _init(type: InkType.Type, capacity: float, regen: float) -> void:
	ink_type = type
	max_capacity = capacity
	regen_rate = regen
	current = capacity


func fraction() -> float:
	if max_capacity <= 0.0:
		return 0.0
	return clampf(current / max_capacity, 0.0, 1.0)


func can_spend(amount: float = 1.0) -> bool:
	return current >= amount


func spend(amount: float = 1.0) -> bool:
	if not can_spend(amount):
		return false
	current -= amount
	return true


func tick(delta: float) -> void:
	current = minf(max_capacity, current + regen_rate * delta)
