extends Node2D

@onready var ink_grid: InkGrid = $InkGrid


func _draw() -> void:
	var size := GameConstants.GRID_PIXEL_SIZE
	draw_rect(Rect2(Vector2.ZERO, size), GameConstants.PARCHMENT, true)

	for x in range(GameConstants.GRID_COLS + 1):
		var px := x * GameConstants.TILE_SIZE
		draw_line(Vector2(px, 0), Vector2(px, size.y), GameConstants.GRID_LINE, 1.0)

	for y in range(GameConstants.GRID_ROWS + 1):
		var py := y * GameConstants.TILE_SIZE
		draw_line(Vector2(0, py), Vector2(size.x, py), GameConstants.GRID_LINE, 1.0)

	_draw_portal(GameConstants.ENTRY_CELL, GameConstants.ENTRY_COLOR, "RIFT IN")
	_draw_portal(GameConstants.EXIT_CELL, GameConstants.EXIT_COLOR, "CORE")


func _draw_portal(cell: Vector2i, color: Color, label: String) -> void:
	var rect := Rect2(
		Vector2(cell.x, cell.y) * GameConstants.TILE_SIZE,
		Vector2(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)
	)
	draw_rect(rect.grow(2.0), color.lerp(Color.WHITE, 0.25), false, 2.0)
	draw_string(
		ThemeDB.fallback_font,
		rect.position + Vector2(2, -4),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		color
	)
