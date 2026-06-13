class_name Creep
extends Node2D

signal died(creep: Creep)
signal reached_core(creep: Creep)

const DAMAGE_TICK := 1.0
const BASE_DAMAGE := 12.0
const POISON_DAMAGE := 4.0
const SLOW_FACTOR := 0.45
const REPATH_INTERVAL := 0.45
const ARRIVE_EPSILON := 0.75

var grid_cell: Vector2i
var hp: float
var max_hp: float
var move_speed: float
var is_boss: bool = false

var _path: Array[Vector2i] = []
var _path_index: int = 0
var _target_pos: Vector2 = Vector2.ZERO
var _ink_grid: InkGrid
var _effect_timers: Dictionary[InkType.Type, float] = {
	InkType.Type.FIRE: 0.0,
	InkType.Type.POISON: 0.0,
}
var _slow_timer: float = 0.0
var _repath_timer: float = 0.0
var _alive: bool = true


func setup(
	ink_grid: InkGrid,
	start_cell: Vector2i,
	health: float,
	speed: float,
	boss: bool = false
) -> void:
	_ink_grid = ink_grid
	grid_cell = start_cell
	hp = health
	max_hp = health
	move_speed = speed
	is_boss = boss
	scale = Vector2.ONE * (LevelConfig.boss_scale() if boss else 1.0)
	position = GameConstants.cell_center_world(start_cell)
	_target_pos = position
	_request_path(true)
	queue_redraw()


func _process(delta: float) -> void:
	if not _alive:
		return
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_request_path(false)
		_repath_timer = REPATH_INTERVAL
	_slow_timer = maxf(0.0, _slow_timer - delta)
	_apply_ink_effects(delta)
	_move_along_path(delta)
	if grid_cell == GameConstants.EXIT_CELL:
		_alive = false
		reached_core.emit(self)
		queue_free()


func _move_along_path(delta: float) -> void:
	if _ink_grid.is_blocked(grid_cell) or _ink_grid.walls.has(grid_cell):
		position = GameConstants.cell_center_world(grid_cell)
		_path.clear()
		return
	if _path.is_empty() or _path_index >= _path.size() - 1:
		return
	var next_cell: Vector2i = _path[_path_index + 1]
	if not _can_enter_cell(next_cell):
		_path.clear()
		return
	var speed_mult: float = SLOW_FACTOR if _slow_timer > 0.0 else 1.0
	_target_pos = GameConstants.cell_center_world(next_cell)
	position = _move_axis_locked(position, _target_pos, move_speed * speed_mult * delta)
	if position.distance_to(_target_pos) <= ARRIVE_EPSILON:
		grid_cell = next_cell
		position = _target_pos
		_path_index += 1


func _move_axis_locked(from: Vector2, to: Vector2, step: float) -> Vector2:
	var pos: Vector2 = from
	var dx: float = to.x - pos.x
	var dy: float = to.y - pos.y
	if absf(dx) > ARRIVE_EPSILON:
		pos.x += signf(dx) * minf(absf(dx), step)
	elif absf(dy) > ARRIVE_EPSILON:
		pos.y += signf(dy) * minf(absf(dy), step)
	return pos


func _can_enter_cell(cell: Vector2i) -> bool:
	if _ink_grid.is_blocked(cell) or _ink_grid.walls.has(cell):
		return false
	var delta: Vector2i = (cell - grid_cell).abs()
	return delta.x + delta.y == 1 and _ink_grid.is_inside_grid(cell)


func _request_path(force: bool) -> void:
	if not force and not _path.is_empty() and _path_index < _path.size() - 1:
		var next_cell: Vector2i = _path[_path_index + 1]
		if _can_enter_cell(next_cell):
			return
	var new_path: Array[Vector2i] = PathFinder.find_path(
		_ink_grid.get_path_obstacles(), grid_cell, GameConstants.EXIT_CELL, GameConstants.GRID_SIZE
	)
	if new_path.is_empty():
		_path.clear()
		_path_index = 0
		return
	_path = new_path
	_sync_path_index()


func _sync_path_index() -> void:
	_path_index = 0
	for i: int in _path.size():
		if _path[i] == grid_cell:
			_path_index = i
			return


func _apply_ink_effects(delta: float) -> void:
	var inks: Array[InkType.Type] = _ink_grid.get_effects_at(grid_cell)
	if inks.is_empty():
		return
	if InkType.Type.FREEZE in inks:
		_slow_timer = DAMAGE_TICK
	for ink_type: InkType.Type in inks:
		if ink_type == InkType.Type.FREEZE:
			continue
		var timer: float = _effect_timers.get(ink_type, 0.0) - delta
		_effect_timers[ink_type] = maxf(0.0, timer)
		if _effect_timers[ink_type] > 0.0:
			continue
		_effect_timers[ink_type] = DAMAGE_TICK
		var bonus: float = SkillProgress.get_damage_bonus_percent(ink_type) / 100.0
		match ink_type:
			InkType.Type.FIRE:
				_take_damage(BASE_DAMAGE * (1.0 + bonus))
			InkType.Type.POISON:
				_take_damage(POISON_DAMAGE * (1.0 + bonus))


func take_damage(amount: float) -> void:
	_take_damage(amount)


func _take_damage(amount: float) -> void:
	hp -= amount
	queue_redraw()
	if hp <= 0.0 and _alive:
		_alive = false
		died.emit(self)
		queue_free()


func _draw() -> void:
	var radius: float = GameConstants.TILE_SIZE * (0.42 if is_boss else 0.32)
	var body_color: Color = Color(0.86, 0.28, 0.34) if is_boss else Color(0.72, 0.18, 0.24)
	draw_circle(Vector2.ZERO, radius, body_color)
	draw_circle(Vector2.ZERO, radius * 0.55, Color(0.95, 0.55, 0.45, 0.85))
	if max_hp > 0.0:
		var bar_w: float = radius * 2.4
		var bar_h: float = 4.0 if is_boss else 3.0
		var bar_y: float = -radius - 8.0
		var hp_ratio: float = clampf(hp / max_hp, 0.0, 1.0)
		draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w, bar_h), Color(0.1, 0.08, 0.1, 0.85), true)
		draw_rect(Rect2(-bar_w * 0.5, bar_y, bar_w * hp_ratio, bar_h), Color(0.35, 0.9, 0.45), true)
