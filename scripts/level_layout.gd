class_name LevelLayout
extends RefCounted

## Hand-crafted layouts per level.
## x / # = indestructible black wall (blocks mobs + ink)
## ~ / w = water (mobs pass, no wall ink; effects OK)


static func get_blocked_cells(level: int) -> Array[Vector2i]:
	return get_layout(level)["blocked"]


static func get_water_cells(level: int) -> Array[Vector2i]:
	return get_layout(level)["water"]


static func get_tower_cells(level: int) -> Array[Vector2i]:
	if level < 3:
		return []
	var towers: Array[Vector2i] = []
	var middle: Vector2i = Vector2i(GameConstants.GRID_COLS / 2, GameConstants.GRID_ROWS / 2)
	if _tower_cell_valid(level, towers, middle):
		towers.append(middle)
	if level >= 4:
		var back: Vector2i = _pick_tower_cell(level, 4, true, towers)
		if back != Vector2i(-1, -1):
			towers.append(back)
	if level >= 5:
		var back: Vector2i = _pick_tower_cell(level, 5, true, towers)
		if back != Vector2i(-1, -1) and back not in towers:
			towers.append(back)
		var front: Vector2i = _pick_tower_cell(level, 5, false, towers)
		if front != Vector2i(-1, -1) and front not in towers:
			towers.append(front)
	return towers


static func _pick_tower_cell(
	level: int, seed_offset: int, near_exit: bool, existing: Array[Vector2i]
) -> Vector2i:
	var rng := RandomNumberGenerator.new()
	rng.seed = level * 9001 + seed_offset + (1 if near_exit else 99)
	var blocked: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in get_blocked_cells(level):
		blocked[cell] = true
	for cell: Vector2i in get_water_cells(level):
		blocked[cell] = true
	for cell: Vector2i in GameConstants.pen_reserve_cells():
		blocked[cell] = true
	var candidates: Array[Vector2i] = []
	for y: int in range(4, GameConstants.GRID_ROWS - 4):
		for x: int in range(3, GameConstants.GRID_COLS - 3):
			var cell := Vector2i(x, y)
			if blocked.has(cell):
				continue
			if near_exit:
				if x > 18:
					continue
			else:
				if x < 36:
					continue
			if cell == GameConstants.ENTRY_CELL or cell == GameConstants.EXIT_CELL:
				continue
			if cell in existing:
				continue
			candidates.append(cell)
	rng.shuffle(candidates)
	for cell: Vector2i in candidates:
		if _tower_cell_valid(level, existing, cell):
			return cell
	return Vector2i(-1, -1)


static func _tower_cell_valid(level: int, existing: Array[Vector2i], cell: Vector2i) -> bool:
	if cell == GameConstants.ENTRY_CELL or cell == GameConstants.EXIT_CELL:
		return false
	if cell in existing:
		return false
	var obstacles: Dictionary = _layout_obstacles(level)
	for tower: Vector2i in existing:
		obstacles[tower] = true
	obstacles[cell] = true
	return PathValidator.has_path(
		obstacles, GameConstants.ENTRY_CELL, GameConstants.EXIT_CELL, GameConstants.GRID_SIZE
	)


static func _layout_obstacles(level: int) -> Dictionary:
	var obstacles: Dictionary = {}
	for c: Vector2i in get_blocked_cells(level):
		obstacles[c] = true
	for c: Vector2i in GameConstants.pen_reserve_cells():
		obstacles[c] = true
	return obstacles


static func get_layout(level: int) -> Dictionary:
	var blocked: Array[Vector2i] = []
	var water: Array[Vector2i] = []
	match level:
		1:
			# Four staggered vertical pillars (zigzag funnel).
			blocked.append_array(_vline(18, 9, 20))
			blocked.append_array(_vline(26, 5, 16))
			blocked.append_array(_vline(34, 14, 25))
			blocked.append_array(_vline(42, 9, 20))
		2:
			# Top/bottom rails + partial mid wall from center toward entry (fork).
			blocked.append_array(_hline(10, 8, 48))
			blocked.append_array(_hline(20, 8, 48))
			blocked.append_array(_hline(15, 30, 52))
		3:
			blocked.append_array(_hline(10, 36, 47))
			blocked.append_array(_hline(20, 36, 47))
			water.append_array(_rect(48, 6, 49, 24))
			water.append_array(_rect(22, 12, 23, 18))
		4:
			blocked.append_array(_hline(10, 36, 47))
			blocked.append_array(_hline(20, 36, 47))
			water.append_array(_rect(48, 6, 49, 24))
			water.append_array(_rect(22, 12, 23, 18))
			blocked.append_array(_exit_random_walls(4))
			water.append_array(_exit_random_water(4))
		5:
			blocked.append_array(_hline(10, 36, 47))
			blocked.append_array(_hline(20, 36, 47))
			water.append_array(_rect(48, 6, 49, 24))
			water.append_array(_rect(22, 12, 23, 18))
			blocked.append_array(_exit_random_walls(5))
			water.append_array(_exit_random_water(5))
	return {
		"blocked": _dedupe(blocked),
		"water": _dedupe(water),
	}


static func _vline(x: int, y0: int, y1: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in range(mini(y0, y1), maxi(y0, y1) + 1):
		out.append(Vector2i(x, y))
	return out


static func _hline(y: int, x0: int, x1: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x: int in range(mini(x0, x1), maxi(x0, x1) + 1):
		out.append(Vector2i(x, y))
	return out


static func _rect(x0: int, y0: int, x1: int, y1: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in range(mini(y0, y1), maxi(y0, y1) + 1):
		for x: int in range(mini(x0, x1), maxi(x0, x1) + 1):
			out.append(Vector2i(x, y))
	return out


static func _exit_random_walls(level: int) -> Array[Vector2i]:
	var rng := RandomNumberGenerator.new()
	rng.seed = level * 1337 + 42
	var out: Array[Vector2i] = []
	var cluster_count: int = 4 if level == 4 else 7
	for _i: int in cluster_count:
		var cx: int = rng.randi_range(3, 17)
		var cy: int = rng.randi_range(7, 23)
		if cy == GameConstants.EXIT_CELL.y:
			cy += 3 if cy < GameConstants.GRID_ROWS / 2 else -3
		match rng.randi_range(0, 2):
			0:
				out.append_array(_vline(cx, cy, cy + rng.randi_range(1, 3)))
				out.append_array(_hline(cy, cx, cx + rng.randi_range(1, 2)))
			1:
				out.append_array(_rect(cx, cy, cx + 1, cy + 1))
			2:
				out.append(Vector2i(cx, cy))
				out.append(Vector2i(cx + 1, cy + 1))
	# Keep a lane open near the core.
	for cell: Vector2i in out.duplicate():
		if cell.x <= 2 and cell.y == GameConstants.EXIT_CELL.y:
			out.erase(cell)
	return _dedupe(out)


static func _exit_random_water(level: int) -> Array[Vector2i]:
	var rng := RandomNumberGenerator.new()
	rng.seed = level * 4242 + 7
	var out: Array[Vector2i] = []
	var pool_count: int = 10 if level == 4 else 16
	for _i: int in pool_count:
		var cx: int = rng.randi_range(2, 20)
		var cy: int = rng.randi_range(6, 24)
		if cy == GameConstants.EXIT_CELL.y and cx <= 4:
			continue
		match rng.randi_range(0, 3):
			0:
				out.append(Vector2i(cx, cy))
			1:
				out.append_array(_rect(cx, cy, cx + 1, cy))
			2:
				out.append_array(_rect(cx, cy, cx, cy + 1))
			3:
				out.append_array(_rect(cx, cy, cx + 1, cy + 1))
	return _dedupe(out)


static func _dedupe(cells: Array[Vector2i]) -> Array[Vector2i]:
	var seen: Dictionary[Vector2i, bool] = {}
	var out: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if seen.has(cell) or not _in_grid(cell):
			continue
		if cell == GameConstants.ENTRY_CELL or cell == GameConstants.EXIT_CELL:
			continue
		seen[cell] = true
		out.append(cell)
	return out


static func _in_grid(cell: Vector2i) -> bool:
	return (
		cell.x >= 0 and cell.y >= 0
		and cell.x < GameConstants.GRID_COLS
		and cell.y < GameConstants.GRID_ROWS
	)
