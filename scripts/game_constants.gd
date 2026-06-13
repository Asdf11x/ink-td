class_name GameConstants
extends RefCounted

const TILE_SIZE := 16
const GRID_COLS := 56
const GRID_ROWS := 30
const GRID_SIZE := Vector2i(GRID_COLS, GRID_ROWS)
const GRID_PIXEL_SIZE := Vector2(GRID_COLS * TILE_SIZE, GRID_ROWS * TILE_SIZE)

const ENTRY_CELL := Vector2i(GRID_COLS - 1, GRID_ROWS / 2)
const EXIT_CELL := Vector2i(0, GRID_ROWS / 2)

const PARCHMENT := Color(0.18, 0.14, 0.11)
const GRID_LINE := Color(0.24, 0.19, 0.15, 0.35)
const ENTRY_COLOR := Color(0.95, 0.55, 0.18)
const EXIT_COLOR := Color(0.35, 0.85, 0.95)

const HUD_HEIGHT := 72.0
const PEN_BAR_HEIGHT := 128.0
const GAME_AREA_TOP := 112.0
const PEN_RESERVE_COLS := 16
const PEN_RESERVE_ROWS := 4

## Terrain visuals (distinct from player-drawn ink).
const DOCK_BLOCKED_COLOR := Color(0.3, 0.28, 0.34)
const FIXED_WALL_COLOR := Color(0.42, 0.4, 0.46)
const WATER_COLOR := Color(0.14, 0.3, 0.58)


static func pen_reserve_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var start_y: int = GRID_ROWS - PEN_RESERVE_ROWS
	for y: int in range(start_y, GRID_ROWS):
		for x: int in range(PEN_RESERVE_COLS):
			cells.append(Vector2i(x, y))
	return cells


static func cell_center_world(cell: Vector2i) -> Vector2:
	var half: float = TILE_SIZE * 0.5
	return Vector2(
		float(cell.x) * TILE_SIZE + half,
		float(cell.y) * TILE_SIZE + half
	)
