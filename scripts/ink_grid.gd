class_name InkGrid
extends TileMapLayer

signal ink_placed(cell: Vector2i, ink_type: InkType.Type)
signal ink_erased(cell: Vector2i)
signal ink_denied(cell: Vector2i, ink_type: InkType.Type, reason: String)

enum AtlasTile { FLOOR, WALL, FIRE, POISON, FREEZE, PURPLE, BROWN, TEAL, BLOCKED, FIXED_WALL, WATER }

var walls: Dictionary[Vector2i, bool] = {}
var effect_cells: Dictionary[Vector2i, InkType.Type] = {}
var combo_cells: Dictionary[Vector2i, InkType.Combo] = {}
var water_cells: Dictionary[Vector2i, bool] = {}
var _permanent_blocked: Dictionary[Vector2i, bool] = {}
var _level_blocked: Dictionary[Vector2i, bool] = {}
var _tower_cells: Dictionary[Vector2i, bool] = {}
var _enemies_root: Node2D

@onready var special_layer: TileMapLayer = %SpecialLayerA


func bind_enemies(enemies_root: Node2D) -> void:
	_enemies_root = enemies_root


func has_creep_at(cell: Vector2i) -> bool:
	if _enemies_root == null:
		return false
	for child: Node in _enemies_root.get_children():
		if child is Creep and child.grid_cell == cell:
			return true
	return false


func _ready() -> void:
	_setup_tileset()
	_paint_floor()
	apply_permanent_blocked(GameConstants.pen_reserve_cells())
	_paint_terrain()


func apply_permanent_blocked(cells: Array[Vector2i]) -> void:
	for cell: Vector2i in cells:
		if not is_inside_grid(cell):
			continue
		_permanent_blocked[cell] = true


func apply_level_layout(blocked: Array[Vector2i], water: Array[Vector2i]) -> void:
	_level_blocked.clear()
	water_cells.clear()
	for cell: Vector2i in blocked:
		if not is_inside_grid(cell) or _permanent_blocked.has(cell):
			continue
		_level_blocked[cell] = true
	for cell: Vector2i in water:
		if not is_inside_grid(cell) or is_blocked(cell):
			continue
		water_cells[cell] = true
	_paint_terrain()


func apply_tower_cells(cells: Array[Vector2i]) -> void:
	_tower_cells.clear()
	for cell: Vector2i in cells:
		if not is_inside_grid(cell) or _permanent_blocked.has(cell):
			continue
		_tower_cells[cell] = true


func has_tower_at(cell: Vector2i) -> bool:
	return _tower_cells.has(cell)


func get_path_obstacles() -> Dictionary:
	var obstacles: Dictionary = walls.duplicate()
	for cell: Vector2i in _permanent_blocked.keys():
		obstacles[cell] = true
	for cell: Vector2i in _level_blocked.keys():
		obstacles[cell] = true
	for cell: Vector2i in _tower_cells.keys():
		obstacles[cell] = true
	return obstacles


func is_blocked(cell: Vector2i) -> bool:
	return _permanent_blocked.has(cell) or _level_blocked.has(cell)


func is_water(cell: Vector2i) -> bool:
	return water_cells.has(cell)


func _paint_terrain() -> void:
	for cell: Vector2i in _permanent_blocked.keys():
		set_cell(cell, 0, Vector2i(AtlasTile.BLOCKED, 0))
	for cell: Vector2i in _level_blocked.keys():
		set_cell(cell, 0, Vector2i(AtlasTile.FIXED_WALL, 0))
	for cell: Vector2i in water_cells.keys():
		set_cell(cell, 0, Vector2i(AtlasTile.WATER, 0))


func _setup_tileset() -> void:
	var tile_set_resource := TileSet.new()
	var atlas := TileSetAtlasSource.new()
	var img := Image.create(AtlasTile.size() * GameConstants.TILE_SIZE, GameConstants.TILE_SIZE, false, Image.FORMAT_RGBA8)
	var colors: Array[Color] = [
		Color(0, 0, 0, 0),
		InkType.COLORS[InkType.Type.WALL],
		InkType.COLORS[InkType.Type.FIRE],
		InkType.COLORS[InkType.Type.POISON],
		InkType.COLORS[InkType.Type.FREEZE],
		InkType.COMBO_COLORS[InkType.Combo.PURPLE],
		InkType.COMBO_COLORS[InkType.Combo.BROWN],
		InkType.COMBO_COLORS[InkType.Combo.TEAL],
		GameConstants.DOCK_BLOCKED_COLOR,
		GameConstants.FIXED_WALL_COLOR,
		GameConstants.WATER_COLOR,
	]
	for i: int in colors.size():
		for y in GameConstants.TILE_SIZE:
			for x in GameConstants.TILE_SIZE:
				img.set_pixel(i * GameConstants.TILE_SIZE + x, y, colors[i])
	var tex := ImageTexture.create_from_image(img)
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)
	for x in colors.size():
		atlas.create_tile(Vector2i(x, 0))
	tile_set_resource.add_source(atlas, 0)
	tile_set = tile_set_resource
	special_layer.tile_set = tile_set_resource


func _paint_floor() -> void:
	for y in GameConstants.GRID_ROWS:
		for x in GameConstants.GRID_COLS:
			set_cell(Vector2i(x, y), 0, Vector2i(AtlasTile.FLOOR, 0))


func cell_from_world(world_pos: Vector2) -> Vector2i:
	return local_to_map(to_local(world_pos))


func is_inside_grid(cell: Vector2i) -> bool:
	return (
		cell.x >= 0 and cell.y >= 0
		and cell.x < GameConstants.GRID_COLS
		and cell.y < GameConstants.GRID_ROWS
	)


func try_paint(cell: Vector2i, ink_type: InkType.Type) -> bool:
	if not is_inside_grid(cell):
		return false
	if has_creep_at(cell):
		ink_denied.emit(cell, ink_type, "Cannot ink over an intruder.")
		return false
	if is_blocked(cell):
		ink_denied.emit(cell, ink_type, "This tile cannot be changed.")
		return false
	if has_tower_at(cell):
		ink_denied.emit(cell, ink_type, "Cannot ink over a tower.")
		return false
	if ink_type == InkType.Type.WALL and is_water(cell):
		ink_denied.emit(cell, ink_type, "Cannot build walls on water.")
		return false
	if ink_type == InkType.Type.ERASER:
		return try_erase(cell)
	if ink_type == InkType.Type.WALL:
		return _try_paint_wall(cell)
	return _try_paint_effect(cell, ink_type)


func try_erase(cell: Vector2i) -> bool:
	if not is_inside_grid(cell) or is_blocked(cell) or has_tower_at(cell):
		return false
	var removed := false
	if walls.has(cell):
		walls.erase(cell)
		if is_water(cell):
			set_cell(cell, 0, Vector2i(AtlasTile.WATER, 0))
		else:
			set_cell(cell, 0, Vector2i(AtlasTile.FLOOR, 0))
		removed = true
	if effect_cells.has(cell) or combo_cells.has(cell):
		effect_cells.erase(cell)
		combo_cells.erase(cell)
		special_layer.erase_cell(cell)
		removed = true
	if removed:
		ink_erased.emit(cell)
	return removed


func _try_paint_wall(cell: Vector2i) -> bool:
	if cell == GameConstants.ENTRY_CELL or cell == GameConstants.EXIT_CELL:
		ink_denied.emit(cell, InkType.Type.WALL, "Entry and exit cannot be walled.")
		return false
	if walls.has(cell) or effect_cells.has(cell) or combo_cells.has(cell):
		return false
	walls[cell] = true
	if not PathValidator.has_path(get_path_obstacles(), GameConstants.ENTRY_CELL, GameConstants.EXIT_CELL, GameConstants.GRID_SIZE):
		walls.erase(cell)
		ink_denied.emit(cell, InkType.Type.WALL, "That wall would seal the path.")
		return false
	set_cell(cell, 0, Vector2i(AtlasTile.WALL, 0))
	ink_placed.emit(cell, InkType.Type.WALL)
	return true


func _try_paint_effect(cell: Vector2i, ink_type: InkType.Type) -> bool:
	if walls.has(cell):
		ink_denied.emit(cell, ink_type, "Cannot paint over wall ink.")
		return false
	if combo_cells.has(cell):
		ink_denied.emit(cell, ink_type, "Combined ink cannot be overpainted.")
		return false
	if effect_cells.has(cell):
		var existing: InkType.Type = effect_cells[cell]
		if existing == ink_type:
			return false
		var combo: InkType.Combo = InkType.combo_from_pair(existing, ink_type)
		if combo == InkType.Combo.NONE:
			ink_denied.emit(cell, ink_type, "These inks cannot combine here.")
			return false
		effect_cells.erase(cell)
		combo_cells[cell] = combo
		_refresh_effect_cell(cell)
		ink_placed.emit(cell, ink_type)
		return true
	effect_cells[cell] = ink_type
	_refresh_effect_cell(cell)
	ink_placed.emit(cell, ink_type)
	return true


func _refresh_effect_cell(cell: Vector2i) -> void:
	special_layer.erase_cell(cell)
	if combo_cells.has(cell):
		special_layer.set_cell(cell, 0, Vector2i(_atlas_for_combo(combo_cells[cell]), 0))
	elif effect_cells.has(cell):
		special_layer.set_cell(cell, 0, Vector2i(_atlas_for_type(effect_cells[cell]), 0))


func get_effects_at(cell: Vector2i) -> Array[InkType.Type]:
	var result: Array[InkType.Type] = []
	if combo_cells.has(cell):
		var combo: InkType.Combo = combo_cells[cell]
		if InkType.combo_has_fire(combo):
			result.append(InkType.Type.FIRE)
		if InkType.combo_has_poison(combo):
			result.append(InkType.Type.POISON)
		if InkType.combo_has_freeze(combo):
			result.append(InkType.Type.FREEZE)
	elif effect_cells.has(cell):
		result.append(effect_cells[cell])
	return result


func reset_grid() -> void:
	for cell: Vector2i in special_layer.get_used_cells():
		special_layer.erase_cell(cell)
	walls.clear()
	effect_cells.clear()
	combo_cells.clear()
	_level_blocked.clear()
	_tower_cells.clear()
	water_cells.clear()
	_paint_floor()
	_paint_terrain()


func _atlas_for_type(ink_type: InkType.Type) -> int:
	match ink_type:
		InkType.Type.FIRE: return AtlasTile.FIRE
		InkType.Type.POISON: return AtlasTile.POISON
		InkType.Type.FREEZE: return AtlasTile.FREEZE
	return AtlasTile.FLOOR


func _atlas_for_combo(combo: InkType.Combo) -> int:
	match combo:
		InkType.Combo.PURPLE: return AtlasTile.PURPLE
		InkType.Combo.BROWN: return AtlasTile.BROWN
		InkType.Combo.TEAL: return AtlasTile.TEAL
	return AtlasTile.FLOOR
