class_name ShortcutHint
extends Label

const HINT_COLOR := Color(0.95, 0.88, 0.55, 0.95)


static func attach(
	parent_control: Control,
	key_text: String,
	above: bool = true,
	half_width: float = 16.0
) -> ShortcutHint:
	var hint := ShortcutHint.new()
	hint.text = key_text
	hint.visible = false
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", HINT_COLOR)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_CENTER_TOP if above else Control.PRESET_CENTER_BOTTOM)
	hint.offset_left = -half_width
	hint.offset_right = half_width
	if above:
		hint.offset_top = -14.0
		hint.offset_bottom = -2.0
	else:
		hint.offset_top = 2.0
		hint.offset_bottom = 14.0
	hint.z_index = 10
	parent_control.add_child(hint)
	return hint
