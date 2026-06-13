class_name PathValidator
extends RefCounted

static func has_path(
	walls: Dictionary,
	entry: Vector2i,
	exit: Vector2i,
	grid_size: Vector2i
) -> bool:
	if walls.has(entry) or walls.has(exit):
		return false

	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [entry]
	visited[entry] = true
	var dirs: Array[Vector2i] = [
		Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN
	]

	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell == exit:
			return true

		for dir: Vector2i in dirs:
			var next: Vector2i = cell + dir
			if next.x < 0 or next.y < 0 or next.x >= grid_size.x or next.y >= grid_size.y:
				continue
			if walls.has(next) or visited.has(next):
				continue
			visited[next] = true
			queue.append(next)

	return false
