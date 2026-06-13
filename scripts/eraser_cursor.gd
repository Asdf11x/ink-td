extends Node2D

var ink_grid: InkGrid
var ink_manager: InkManager
var _hover_cell: Vector2i = Vector2i(-999, -999)


func setup(grid: InkGrid, manager: InkManager) -> void:
	ink_grid = grid
	ink_manager = manager
	ink_manager.selection_changed.connect(_on_selection_changed)


func _process(_delta: float) -> void:
	if ink_manager == null or ink_manager.selected != InkType.Type.ERASER:
		if _hover_cell.x >= 0:
			_hover_cell = Vector2i(-999, -999)
			queue_redraw()
		return
	var cell: Vector2i = ink_grid.cell_from_world(get_global_mouse_position())
	if cell != _hover_cell:
		_hover_cell = cell
		queue_redraw()


func _on_selection_changed(_t: InkType.Type) -> void:
	_hover_cell = Vector2i(-999, -999)
	queue_redraw()


func _draw() -> void:
	if ink_manager == null or ink_manager.selected != InkType.Type.ERASER:
		return
	if not ink_grid.is_inside_grid(_hover_cell):
		return
	var tile: float = float(GameConstants.TILE_SIZE)
	var rect := Rect2(
		Vector2(_hover_cell) * tile,
		Vector2(tile, tile)
	)
	draw_rect(rect, Color(0.95, 0.15, 0.12, 0.15), true)
	draw_rect(rect, Color(0.95, 0.2, 0.15, 0.95), false, 2.0)
