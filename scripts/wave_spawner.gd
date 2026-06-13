class_name WaveSpawner
extends Node

signal wave_cleared
signal core_breached
signal enemy_count_changed(remaining: int)
signal xp_earned(amount: int)

@export var creep_scene: PackedScene = preload("res://scenes/creep.tscn")

var ink_grid: InkGrid
var enemies_root: Node2D

var _level: int = 1
var _wave: int = 1
var _to_spawn: int = 0
var _spawned: int = 0
var _alive: int = 0
var _spawn_timer: float = 0.0
var _spawn_interval: float = 1.0
var _active: bool = false


func configure(ink_grid_ref: InkGrid, enemies: Node2D, level: int, wave: int) -> void:
	ink_grid = ink_grid_ref
	enemies_root = enemies
	_level = level
	_wave = wave
	_to_spawn = LevelConfig.creeps_per_wave(level, wave)
	if LevelConfig.is_boss_wave(level, wave):
		_to_spawn += 1
	_spawned = 0
	_alive = 0
	_spawn_timer = 0.0
	_spawn_interval = LevelConfig.spawn_interval(level, wave)
	_active = false
	_emit_enemy_count()


func begin_spawning() -> void:
	_active = true


func halt() -> void:
	_active = false


func _process(delta: float) -> void:
	if not _active:
		return
	if _spawned >= _to_spawn:
		if _alive <= 0:
			_active = false
			wave_cleared.emit()
		return
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = _spawn_interval
	_spawn_next()


func _spawn_next() -> void:
	var is_boss: bool = LevelConfig.is_boss_wave(_level, _wave) and _spawned == _to_spawn - 1
	var creep: Creep = creep_scene.instantiate() as Creep
	enemies_root.add_child(creep)
	var hp: float = LevelConfig.boss_hp(_level) if is_boss else LevelConfig.creep_hp(_level, _wave)
	var speed: float = LevelConfig.boss_speed(_level) if is_boss else LevelConfig.creep_speed(_level)
	creep.setup(ink_grid, GameConstants.ENTRY_CELL, hp, speed, is_boss)
	creep.died.connect(_on_creep_died)
	creep.reached_core.connect(_on_creep_reached_core)
	_spawned += 1
	_alive += 1
	_emit_enemy_count()


func _on_creep_died(creep: Creep) -> void:
	_alive -= 1
	var gained: int = SkillProgress.award_kill_xp(creep.is_boss)
	xp_earned.emit(gained)
	_emit_enemy_count()


func _on_creep_reached_core(_creep: Creep) -> void:
	_alive -= 1
	core_breached.emit()
	_emit_enemy_count()


func _emit_enemy_count() -> void:
	var remaining: int = maxi(0, _to_spawn - _spawned) + _alive
	enemy_count_changed.emit(remaining)
