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
