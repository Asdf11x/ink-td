class_name InkManager
extends Node

signal selection_changed(ink_type: InkType.Type)
signal capacity_changed(ink_type: InkType.Type, current: float, max_capacity: float)

const START_WALL := 40.0
const START_EFFECT := 10.0
const REGEN_WALL := 1.0
const REGEN_EFFECT := 0.35

var selected: InkType.Type = InkType.Type.WALL
var debug_unlimited_ink: bool = false
var _pools: Dictionary[InkType.Type, InkPool] = {}


func _ready() -> void:
	reset_pools_for_run()


func reset_pools_for_run() -> void:
	var wall_cap: float = START_WALL + float(SkillProgress.get_pixel_bonus(SkillProgress.SKILL_WALL_PIXELS))
	_pools[InkType.Type.WALL] = InkPool.new(InkType.Type.WALL, wall_cap, REGEN_WALL)
	_pools[InkType.Type.FIRE] = InkPool.new(
		InkType.Type.FIRE,
		START_EFFECT + float(SkillProgress.get_pixel_bonus(SkillProgress.SKILL_FIRE_PIXELS)),
		REGEN_EFFECT
	)
	_pools[InkType.Type.POISON] = InkPool.new(
		InkType.Type.POISON,
		START_EFFECT + float(SkillProgress.get_pixel_bonus(SkillProgress.SKILL_POISON_PIXELS)),
		REGEN_EFFECT
	)
	_pools[InkType.Type.FREEZE] = InkPool.new(
		InkType.Type.FREEZE,
		START_EFFECT + float(SkillProgress.get_pixel_bonus(SkillProgress.SKILL_FREEZE_PIXELS)),
		REGEN_EFFECT
	)
	for ink_type: InkType.Type in InkType.PAINT_TYPES:
		capacity_changed.emit(ink_type, _pools[ink_type].current, _pools[ink_type].max_capacity)


func _process(delta: float) -> void:
	for pool: InkPool in _pools.values():
		var before: float = pool.current
		pool.tick(delta)
		if not is_equal_approx(before, pool.current):
			capacity_changed.emit(pool.ink_type, pool.current, pool.max_capacity)


func select(ink_type: InkType.Type) -> void:
	if selected == ink_type:
		return
	selected = ink_type
	selection_changed.emit(ink_type)


func get_pool(ink_type: InkType.Type) -> InkPool:
	return _pools.get(ink_type)


func try_spend(ink_type: InkType.Type, amount: float = 1.0) -> bool:
	if ink_type == InkType.Type.ERASER:
		return true
	if debug_unlimited_ink:
		return true
	var pool: InkPool = _pools.get(ink_type)
	if pool == null:
		return false
	if not pool.spend(amount):
		return false
	capacity_changed.emit(ink_type, pool.current, pool.max_capacity)
	return true
