class_name InkManager
extends Node

signal selection_changed(ink_type: InkType.Type)
signal capacity_changed(ink_type: InkType.Type, current: float, max_capacity: float)

var selected: InkType.Type = InkType.Type.WALL
var _pools: Dictionary = {}


func _ready() -> void:
	_pools[InkType.Type.WALL] = InkPool.new(InkType.Type.WALL, 480.0, 10.0)
	_pools[InkType.Type.DAMAGE] = InkPool.new(InkType.Type.DAMAGE, 220.0, 6.0)
	_pools[InkType.Type.POISON] = InkPool.new(InkType.Type.POISON, 220.0, 6.0)
	_pools[InkType.Type.SLOW] = InkPool.new(InkType.Type.SLOW, 220.0, 6.0)


func _process(delta: float) -> void:
	for pool: InkPool in _pools.values():
		var before := pool.current
		pool.tick(delta)
		if not is_equal_approx(before, pool.current):
			capacity_changed.emit(pool.ink_type, pool.current, pool.max_capacity)


func select(ink_type: InkType.Type) -> void:
	if selected == ink_type:
		return
	selected = ink_type
	selection_changed.emit(ink_type)


func get_pool(ink_type: InkType.Type) -> InkPool:
	return _pools[ink_type]


func try_spend(ink_type: InkType.Type, amount: float = 1.0) -> bool:
	var pool: InkPool = _pools[ink_type]
	if not pool.spend(amount):
		return false
	capacity_changed.emit(ink_type, pool.current, pool.max_capacity)
	return true
