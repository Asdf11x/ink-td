class_name PenBar
extends Control

const PEN_WIDTH := 50.0
const PEN_SLOT_HEIGHT := 128.0
const PEN_TIP_VISIBLE := 30.0
const PEN_FULL_HEIGHT := 116.0

var ink_manager: InkManager
var _show_shortcuts := false

@onready var pens_root: HBoxContainer = %PensRoot


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	pens_root.mouse_filter = Control.MOUSE_FILTER_PASS
	z_index = 20
	for ink_type: InkType.Type in InkType.all_tool_types():
		pens_root.add_child(_create_pen_widget(ink_type))


func bind_manager(manager: InkManager) -> void:
	if ink_manager:
		ink_manager.selection_changed.disconnect(_on_selection_changed)
		ink_manager.capacity_changed.disconnect(_on_capacity_changed)
	ink_manager = manager
	ink_manager.selection_changed.connect(_on_selection_changed)
	ink_manager.capacity_changed.connect(_on_capacity_changed)
	_refresh_all_pens()
	_on_selection_changed(ink_manager.selected)


func set_shortcuts_visible(visible: bool) -> void:
	if _show_shortcuts == visible:
		return
	_show_shortcuts = visible
	_refresh_all_pens()


func _create_pen_widget(ink_type: InkType.Type) -> Control:
	var pen := Control.new()
	pen.name = "Pen_%s" % InkType.DISPLAY_NAMES[ink_type]
	pen.custom_minimum_size = Vector2(PEN_WIDTH, PEN_SLOT_HEIGHT)
	pen.set_meta("ink_type", ink_type)
	pen.mouse_filter = Control.MOUSE_FILTER_STOP
	pen.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if ink_manager:
				ink_manager.select(ink_type)
	)
	pen.draw.connect(func() -> void: _draw_pen(pen, ink_type))
	return pen


func _draw_pen(pen: Control, ink_type: InkType.Type) -> void:
	var selected: bool = ink_manager != null and ink_manager.selected == ink_type
	var pool: InkPool = ink_manager.get_pool(ink_type) if ink_manager else null
	var width: float = pen.size.x
	var bottom: float = pen.size.y
	var visible_h: float = PEN_FULL_HEIGHT if selected else PEN_TIP_VISIBLE
	var top: float = bottom - visible_h
	var ink_color: Color = InkType.COLORS[ink_type]
	var glow: Color = InkType.GLOW_COLORS[ink_type]
	var nib_base_y: float = top + 16.0

	if ink_type == InkType.Type.ERASER:
		ink_color = Color(0.85, 0.82, 0.78)
		glow = Color(0.95, 0.92, 0.88)

	pen.draw_colored_polygon(
		PackedVector2Array([
			Vector2(width * 0.5, top + 2.0),
			Vector2(width * 0.5 - 8.0, nib_base_y),
			Vector2(width * 0.5 + 8.0, nib_base_y),
		]),
		ink_color.lerp(glow, 0.15)
	)
	var barrel_top: float = nib_base_y + 2.0
	var barrel_bottom: float = bottom - 14.0
	if barrel_bottom > barrel_top:
		pen.draw_rect(Rect2(10.0, barrel_top, width - 20.0, barrel_bottom - barrel_top), Color(0.14, 0.12, 0.17), true)
		if pool and ink_type != InkType.Type.ERASER:
			var fraction: float = pool.fraction()
			var tube_h: float = barrel_bottom - barrel_top - 4.0
			var fill_h: float = tube_h * fraction
			pen.draw_rect(
				Rect2(15.0, barrel_bottom - fill_h - 2.0, width - 30.0, fill_h),
				ink_color.lerp(glow, 0.35), true
			)

	pen.draw_rect(Rect2(6.0, bottom - 12.0, width - 12.0, 10.0), Color(0.2, 0.17, 0.24), true)

	if selected:
		pen.draw_rect(Rect2(2.0, top, width - 4.0, visible_h), glow, false, 2.0)
		if pool and ink_type != InkType.Type.ERASER:
			pen.draw_string(
				ThemeDB.fallback_font,
				Vector2(width * 0.5, barrel_top + 22.0),
				str(int(pool.current)),
				HORIZONTAL_ALIGNMENT_CENTER, int(width), 14, Color(0.95, 0.92, 0.88)
			)
		elif ink_type == InkType.Type.ERASER:
			pen.draw_string(
				ThemeDB.fallback_font,
				Vector2(width * 0.5, barrel_top + 22.0),
				"Rub",
				HORIZONTAL_ALIGNMENT_CENTER, int(width), 11, Color(0.85, 0.82, 0.78)
			)

	if _show_shortcuts:
		pen.draw_string(
			ThemeDB.fallback_font,
			Vector2(width * 0.5, bottom - 1.0),
			InkType.HOTKEY_LABELS[ink_type],
			HORIZONTAL_ALIGNMENT_CENTER, int(width), 12, Color(0.95, 0.88, 0.55)
		)


func _refresh_all_pens() -> void:
	for pen: Control in pens_root.get_children():
		pen.queue_redraw()


func _on_selection_changed(_ink_type: InkType.Type) -> void:
	_refresh_all_pens()


func _on_capacity_changed(_ink_type: InkType.Type, _c: float, _m: float) -> void:
	_refresh_all_pens()
