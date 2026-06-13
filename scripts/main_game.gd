extends Node2D

@onready var ink_manager: InkManager = $InkManager
@onready var ink_grid: InkGrid = $GameArea/InkGrid
@onready var pen_bar: PenBar = $UI/PenBar
@onready var game_area: Node2D = $GameArea
@onready var feedback_label: Label = $UI/FeedbackLabel

var _is_painting := false
var _last_cell := Vector2i(-9999, -9999)
var _feedback_timer := 0.0


func _ready() -> void:
	pen_bar.bind_manager(ink_manager)
	ink_grid.ink_denied.connect(_on_ink_denied)
	_center_game_area()
	_update_feedback("Draw Void walls. Enemies will enter from the right rift.")


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.05, 0.04, 0.07), true)


func _center_game_area() -> void:
	var viewport_size := get_viewport_rect().size
	var ui_height := 148.0
	game_area.position = Vector2(
		(viewport_size.x - GameConstants.GRID_PIXEL_SIZE.x) * 0.5,
		maxf(16.0, (viewport_size.y - ui_height - GameConstants.GRID_PIXEL_SIZE.y) * 0.5)
	)


func _process(delta: float) -> void:
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
		if _feedback_timer <= 0.0:
			feedback_label.modulate.a = 0.0

	if not _is_painting:
		return

	var cell := ink_grid.cell_from_world(get_global_mouse_position())
	if cell == _last_cell:
		return

	_paint_cell(cell)


func _unhandled_input(event: InputEvent) -> void:
	for ink_type: InkType.Type in InkType.all_types():
		if event.is_action_pressed(InkType.INPUT_ACTIONS[ink_type]):
			ink_manager.select(ink_type)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_painting = true
			_last_cell = Vector2i(-9999, -9999)
			_paint_cell(ink_grid.cell_from_world(get_global_mouse_position()))
		else:
			_is_painting = false
			_last_cell = Vector2i(-9999, -9999)


func _paint_cell(cell: Vector2i) -> void:
	if cell == _last_cell:
		return

	var ink_type := ink_manager.selected
	if not ink_manager.try_spend(ink_type, 1.0):
		_update_feedback("Out of %s ink." % InkType.DISPLAY_NAMES[ink_type])
		return

	if ink_grid.try_paint(cell, ink_type):
		_last_cell = cell
	else:
		ink_manager.get_pool(ink_type).current += 1.0
		ink_manager.capacity_changed.emit(
			ink_type,
			ink_manager.get_pool(ink_type).current,
			ink_manager.get_pool(ink_type).max_capacity
		)


func _on_ink_denied(_cell: Vector2i, ink_type: InkType.Type, reason: String) -> void:
	_update_feedback(reason if reason != "" else "Cannot place %s here." % InkType.DISPLAY_NAMES[ink_type])


func _update_feedback(text: String) -> void:
	feedback_label.text = text
	feedback_label.modulate.a = 1.0
	_feedback_timer = 2.4
