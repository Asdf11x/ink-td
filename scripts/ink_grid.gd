class_name InkGrid
extends TileMapLayer

signal ink_placed(cell: Vector2i, ink_type: InkType.Type)
signal ink_denied(cell: Vector2i, ink_type: InkType.Type, reason: String)

enum AtlasTile { FLOOR, WALL, DAMAGE, POISON, SLOW }

var walls: Dictionary = {}
var special_inks: Dictionary = {}

@onready var special_layer_a: TileMapLayer = %SpecialLayerA
@onready var special_layer_b: TileMapLayer = %SpecialLayerB


func _ready() -> void:
	_setup_tileset()
	special_layer_b.modulate = Color(1, 1, 1, 0.72)
	_paint_floor()


func _setup_tileset() -> void:
	var tile_set_resource := TileSet.new()
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/tiles/ink_atlas.png")
	atlas.texture_region_size = Vector2i(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)

	for x in 5:
		atlas.create_tile(Vector2i(x, 0))

	tile_set_resource.add_source(atlas, 0)
	tile_set = tile_set_resource
	special_layer_a.tile_set = tile_set_resource
	special_layer_b.tile_set = tile_set_resource


func _paint_floor() -> void:
	for y in GameConstants.GRID_ROWS:
		for x in GameConstants.GRID_COLS:
			set_cell(Vector2i(x, y), 0, Vector2i(AtlasTile.FLOOR, 0))


func cell_from_world(world_pos: Vector2) -> Vector2i:
	return local_to_map(to_local(world_pos))


func is_inside_grid(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.y >= 0
		and cell.x < GameConstants.GRID_COLS
		and cell.y < GameConstants.GRID_ROWS
	)


func try_paint(cell: Vector2i, ink_type: InkType.Type) -> bool:
	if not is_inside_grid(cell):
		return false

	if ink_type == InkType.Type.WALL:
		return _try_paint_wall(cell)
	return _try_paint_special(cell, ink_type)


func _try_paint_wall(cell: Vector2i) -> bool:
	if cell == GameConstants.ENTRY_CELL or cell == GameConstants.EXIT_CELL:
		ink_denied.emit(cell, InkType.Type.WALL, "Sacred rift points cannot be walled.")
		return false

	if walls.has(cell):
		return false

	walls[cell] = true
	if not PathValidator.has_path(
		walls,
		GameConstants.ENTRY_CELL,
		GameConstants.EXIT_CELL,
		GameConstants.GRID_SIZE
	):
		walls.erase(cell)
		ink_denied.emit(cell, InkType.Type.WALL, "That wall would seal the path to the core.")
		return false

	set_cell(cell, 0, Vector2i(AtlasTile.WALL, 0))
	ink_placed.emit(cell, InkType.Type.WALL)
	return true


func _try_paint_special(cell: Vector2i, ink_type: InkType.Type) -> bool:
	var existing: Array = special_inks.get(cell, [])
	if ink_type in existing:
		return false

	if existing.size() >= 2:
		ink_denied.emit(cell, ink_type, "Only two effect inks can overlap here.")
		return false

	var updated: Array = existing.duplicate()
	updated.append(ink_type)
	special_inks[cell] = updated
	_refresh_special_layers(cell, updated)
	ink_placed.emit(cell, ink_type)
	return true


func _refresh_special_layers(cell: Vector2i, inks: Array) -> void:
	special_layer_a.erase_cell(cell)
	special_layer_b.erase_cell(cell)

	if inks.is_empty():
		return

	special_layer_a.set_cell(cell, 0, Vector2i(_atlas_for_type(inks[0]), 0))
	if inks.size() > 1:
		special_layer_b.set_cell(cell, 0, Vector2i(_atlas_for_type(inks[1]), 0))


func _atlas_for_type(ink_type: InkType.Type) -> int:
	match ink_type:
		InkType.Type.DAMAGE:
			return AtlasTile.DAMAGE
		InkType.Type.POISON:
			return AtlasTile.POISON
		InkType.Type.SLOW:
			return AtlasTile.SLOW
	return AtlasTile.FLOOR
