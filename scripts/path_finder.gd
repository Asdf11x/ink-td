class_name PathFinder
extends RefCounted

const NO_PARENT := Vector2i(-99999, -99999)


static func find_path(
	walls: Dictionary,
	from_cell: Vector2i,
	to_cell: Vector2i,
	grid_size: Vector2i
) -> Array[Vector2i]:
	if from_cell == to_cell:
		return [from_cell]

	var visited: Dictionary[Vector2i, Vector2i] = {from_cell: NO_PARENT}
	var queue: Array[Vector2i] = [from_cell]
	var dirs: Array[Vector2i] = [
		Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN
	]

	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell == to_cell:
			return _reconstruct_path(visited, to_cell)

		for dir: Vector2i in dirs:
			var next: Vector2i = cell + dir
			if next.x < 0 or next.y < 0 or next.x >= grid_size.x or next.y >= grid_size.y:
				continue
			if walls.has(next) or visited.has(next):
				continue
			visited[next] = cell
			queue.append(next)

	return []


static func _reconstruct_path(came_from: Dictionary[Vector2i, Vector2i], end: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [end]
	var current: Vector2i = end
	while came_from[current] != NO_PARENT:
		current = came_from[current]
		path.push_front(current)
	return path
