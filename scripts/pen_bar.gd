class_name PenBar
extends Control

const PEN_WIDTH := 72.0
const PEN_HEIGHT_COLLAPSED := 34.0
const PEN_HEIGHT_SELECTED := 118.0

var ink_manager: InkManager

@onready var pens_root: HBoxContainer = %PensRoot
@onready var hint_label: Label = %HintLabel


func _ready() -> void:
	for ink_type: InkType.Type in InkType.all_types():
		var pen := _create_pen_widget(ink_type)
		pens_root.add_child(pen)


func bind_manager(manager: InkManager) -> void:
	if ink_manager:
		ink_manager.selection_changed.disconnect(_on_selection_changed)
		ink_manager.capacity_changed.disconnect(_on_capacity_changed)

	ink_manager = manager
	ink_manager.selection_changed.connect(_on_selection_changed)
	ink_manager.capacity_changed.connect(_on_capacity_changed)
	_refresh_all_pens()
	_on_selection_changed(ink_manager.selected)


func _create_pen_widget(ink_type: InkType.Type) -> Control:
	var pen := Control.new()
	pen.name = "Pen_%s" % InkType.DISPLAY_NAMES[ink_type]
	pen.custom_minimum_size = Vector2(PEN_WIDTH, PEN_HEIGHT_SELECTED)
	pen.set_meta("ink_type", ink_type)
	pen.mouse_filter = Control.MOUSE_FILTER_STOP
	pen.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if ink_manager:
				ink_manager.select(ink_type)
	)
	pen.draw.connect(func() -> void:
		_draw_pen(pen, ink_type)
	)
	return pen


func _draw_pen(pen: Control, ink_type: InkType.Type) -> void:
	var selected := ink_manager != null and ink_manager.selected == ink_type
	var pool: InkPool = ink_manager.get_pool(ink_type) if ink_manager else null
	var fraction := pool.fraction() if pool else 1.0

	var width := pen.size.x
	var height := PEN_HEIGHT_SELECTED if selected else PEN_HEIGHT_COLLAPSED
	var origin := Vector2(0.0, PEN_HEIGHT_SELECTED - height)

	var body_color := Color(0.12, 0.10, 0.14)
	var ink_color: Color = InkType.COLORS[ink_type]
	var glow: Color = InkType.GLOW_COLORS[ink_type]

	pen.draw_rect(Rect2(origin.x + 8, origin.y + 4, width - 16, height - 8), body_color, true, 0.0, true)
	pen.draw_rect(Rect2(origin.x + 8, origin.y + 4, width - 16, height - 8), glow.darkened(0.35), false, 2.0, true)

	var cap_height := 14.0 if selected else 10.0
	pen.draw_rect(Rect2(origin.x + 14, origin.y + 6, width - 28, cap_height), Color(0.22, 0.18, 0.24), true)

	var tube_top := origin.y + cap_height + 8.0
	var tube_bottom := origin.y + height - 12.0
	var tube_height := maxf(8.0, tube_bottom - tube_top)
	var fill_height := tube_height * fraction
	pen.draw_rect(
		Rect2(origin.x + 22, tube_top + tube_height - fill_height, width - 44, fill_height),
		ink_color.lerp(glow, 0.35),
		true
	)
	pen.draw_rect(Rect2(origin.x + 22, tube_top, width - 44, tube_height), glow.darkened(0.5), false, 1.5, true)

	if selected:
		pen.draw_rect(Rect2(origin.x + 4, origin.y + 2, width - 8, height - 4), glow, false, 2.0, true)
		var nib_y := origin.y + height - 8.0
		pen.draw_colored_polygon(
			PackedVector2Array([
				Vector2(origin.x + width * 0.5, nib_y + 8.0),
				Vector2(origin.x + width * 0.5 - 8.0, nib_y),
				Vector2(origin.x + width * 0.5 + 8.0, nib_y),
			]),
			ink_color
		)

	var key_label := InkType.HOTKEY_LABELS[ink_type]
	pen.draw_string(
		ThemeDB.fallback_font,
		Vector2(origin.x + 12, origin.y + height - 2),
		key_label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color(0.85, 0.78, 0.68)
	)

	if selected:
		var name_pos := Vector2(origin.x + width * 0.5, origin.y + cap_height + 18.0)
		pen.draw_string(
			ThemeDB.fallback_font,
			name_pos,
			InkType.DISPLAY_NAMES[ink_type],
			HORIZONTAL_ALIGNMENT_CENTER,
			int(width - 8),
			12,
			glow
		)
		var amount_text := "%d" % int(pool.current) if pool else "0"
		pen.draw_string(
			ThemeDB.fallback_font,
			Vector2(origin.x + width * 0.5, tube_top + tube_height * 0.55),
			amount_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			int(width - 8),
			11,
			Color(0.92, 0.88, 0.82)
		)


func _refresh_all_pens() -> void:
	for pen: Control in pens_root.get_children():
		pen.queue_redraw()


func _on_selection_changed(_ink_type: InkType.Type) -> void:
	if hint_label and ink_manager:
		var t: InkType.Type = ink_manager.selected
		hint_label.text = "%s — %s" % [InkType.DISPLAY_NAMES[t], InkType.DESCRIPTIONS[t]]
	for pen: Control in pens_root.get_children():
		var selected := ink_manager.selected == pen.get_meta("ink_type")
		pen.custom_minimum_size.y = PEN_HEIGHT_SELECTED if selected else PEN_HEIGHT_COLLAPSED
		pen.queue_redraw()


func _on_capacity_changed(_ink_type: InkType.Type, _current: float, _max_capacity: float) -> void:
	_refresh_all_pens()
