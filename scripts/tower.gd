class_name Tower
extends Node2D

const BASE_DAMAGE := 14.0
const HOVER_RADIUS_CELLS := 0.75

var grid_cell: Vector2i
var _cooldown: float = 0.0
var _enemies_root: Node2D
var _projectiles_root: Node2D
var _hovered: bool = false


func setup(cell: Vector2i, enemies: Node2D, projectiles: Node2D) -> void:
	grid_cell = cell
	_enemies_root = enemies
	_projectiles_root = projectiles
	position = GameConstants.cell_center_world(cell)
	queue_redraw()


func _process(delta: float) -> void:
	_update_hover()
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var target: Creep = _find_target()
	if target == null:
		return
	_cooldown = SkillProgress.get_tower_attack_interval()
	_fire_at(target)
	queue_redraw()


func _fire_at(target: Creep) -> void:
	if _projectiles_root == null or not is_instance_valid(target):
		return
	var bullet := TowerBullet.new()
	_projectiles_root.add_child(bullet)
	bullet.launch(global_position, target, BASE_DAMAGE * SkillProgress.get_tower_damage_multiplier())


func _update_hover() -> void:
	var mouse: Vector2 = get_global_mouse_position()
	var hover_px: float = HOVER_RADIUS_CELLS * GameConstants.TILE_SIZE
	var hovered: bool = global_position.distance_to(mouse) <= hover_px
	if hovered != _hovered:
		_hovered = hovered
		queue_redraw()


func _find_target() -> Creep:
	var range_px: float = _range_pixels()
	var best: Creep = null
	var best_dist: float = range_px
	for child in _enemies_root.get_children():
		if child is not Creep:
			continue
		var creep: Creep = child as Creep
		var dist: float = global_position.distance_to(creep.global_position)
		if dist <= range_px and dist < best_dist:
			best_dist = dist
			best = creep
	return best


func _range_pixels() -> float:
	return SkillProgress.get_tower_range_cells() * GameConstants.TILE_SIZE


func _draw() -> void:
	var body_r: float = GameConstants.TILE_SIZE * 0.38
	draw_circle(Vector2.ZERO, body_r, Color(0.55, 0.48, 0.32))
	draw_circle(Vector2.ZERO, body_r * 0.55, Color(0.78, 0.62, 0.28))
	draw_rect(
		Rect2(-body_r * 0.22, -body_r * 0.22, body_r * 0.44, body_r * 0.44),
		Color(0.95, 0.82, 0.35),
		false,
		1.5
	)
	if _hovered:
		var range_px: float = _range_pixels()
		draw_arc(Vector2.ZERO, range_px, 0, TAU, 64, Color(0.95, 0.82, 0.35, 0.55), 2.0)
		draw_arc(Vector2.ZERO, range_px, 0, TAU, 64, Color(0.95, 0.82, 0.35, 0.08), range_px)
