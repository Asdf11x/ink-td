extends Control

class_name WaveControls

signal go_pressed
signal pause_pressed
signal speed_selected(multiplier: float)

@onready var go_button: Button = %GoButton
@onready var pause_button: Button = %PauseButton
@onready var speed_1_button: Button = %Speed1Button
@onready var speed_3_button: Button = %Speed3Button
@onready var speed_5_button: Button = %Speed5Button

const COLOR_ACTIVE := Color(0.45, 0.85, 0.55, 1)
const COLOR_INACTIVE := Color(0.55, 0.52, 0.62, 1)
const COLOR_SPEED_ON := Color(0.95, 0.78, 0.35, 1)
const COLOR_SPEED_OFF := Color(0.65, 0.6, 0.72, 1)

var _paused: bool = false
var _speed: float = 1.0
var _shortcut_hints: Array[ShortcutHint] = []


func _ready() -> void:
	go_button.pressed.connect(func() -> void: go_pressed.emit())
	pause_button.pressed.connect(_toggle_pause)
	speed_1_button.pressed.connect(func() -> void: _select_speed(1.0))
	speed_3_button.pressed.connect(func() -> void: _select_speed(3.0))
	speed_5_button.pressed.connect(func() -> void: _select_speed(5.0))
	_shortcut_hints = [
		ShortcutHint.attach(go_button, "Space", true, 22.0),
		ShortcutHint.attach(pause_button, "Space", true, 22.0),
		ShortcutHint.attach(speed_1_button, "Q"),
		ShortcutHint.attach(speed_3_button, "W"),
		ShortcutHint.attach(speed_5_button, "E"),
	]
	_style_go()
	_update_pause_visual()
	_update_speed_visual()
	set_paused(false)


func set_go_enabled(enabled: bool) -> void:
	go_button.disabled = not enabled
	go_button.modulate = Color.WHITE if enabled else Color(0.55, 0.55, 0.55, 1)


func set_paused(paused: bool) -> void:
	_paused = paused
	_update_pause_visual()
	_apply_time_scale()


func reset_speed() -> void:
	_speed = 1.0
	_update_speed_visual()
	_apply_time_scale()


func is_paused() -> bool:
	return _paused


func toggle_pause() -> void:
	_toggle_pause()


func select_speed(multiplier: float) -> void:
	_select_speed(multiplier)


func reapply_time_scale() -> void:
	_apply_time_scale()


func set_shortcuts_visible(visible: bool) -> void:
	for hint: ShortcutHint in _shortcut_hints:
		hint.visible = visible


func _toggle_pause() -> void:
	_paused = not _paused
	_update_pause_visual()
	_apply_time_scale()
	pause_pressed.emit()


func _select_speed(multiplier: float) -> void:
	_speed = multiplier
	_update_speed_visual()
	_apply_time_scale()
	speed_selected.emit(multiplier)


func _style_go() -> void:
	go_button.text = "▶  GO"


func _update_pause_visual() -> void:
	pause_button.text = "▶  Resume" if _paused else "⏸  Pause"
	pause_button.modulate = COLOR_ACTIVE if _paused else Color.WHITE


func _update_speed_visual() -> void:
	for pair: Array in [[speed_1_button, 1.0], [speed_3_button, 3.0], [speed_5_button, 5.0]]:
		var btn: Button = pair[0]
		var mult: float = pair[1]
		var on: bool = is_equal_approx(_speed, mult)
		btn.modulate = COLOR_SPEED_ON if on else COLOR_SPEED_OFF
		btn.add_theme_color_override("font_color", COLOR_SPEED_ON if on else COLOR_INACTIVE)


func _apply_time_scale() -> void:
	Engine.time_scale = 0.0 if _paused else _speed
