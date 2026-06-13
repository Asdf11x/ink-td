class_name DebugMenu
extends Control

signal unlimited_ink_toggled(enabled: bool)
signal jump_requested(level: int, wave: int)

@onready var panel: PanelContainer = %DebugPanel
@onready var toggle_button: Button = %DebugToggleButton
@onready var unlimited_check: CheckBox = %UnlimitedInkCheck
@onready var level_spin: SpinBox = %LevelSpin
@onready var wave_spin: SpinBox = %WaveSpin
@onready var go_button: Button = %DebugGoButton

var _debug_hint: ShortcutHint


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	z_index = 25
	panel.visible = false
	_debug_hint = ShortcutHint.attach(toggle_button, "D", false)
	toggle_button.pressed.connect(_toggle_panel)
	unlimited_check.toggled.connect(func(enabled: bool) -> void: unlimited_ink_toggled.emit(enabled))
	go_button.pressed.connect(_on_go_pressed)
	level_spin.min_value = 1
	level_spin.max_value = LevelConfig.TOTAL_LEVELS
	level_spin.value = GameSession.current_level
	wave_spin.min_value = 1
	wave_spin.max_value = LevelConfig.WAVES_PER_LEVEL
	wave_spin.value = GameSession.current_wave
	GameSession.level_changed.connect(_sync_spins)
	GameSession.wave_changed.connect(_sync_spins)


func toggle_open() -> void:
	_toggle_panel()


func set_shortcuts_visible(visible: bool) -> void:
	if _debug_hint:
		_debug_hint.visible = visible


func _toggle_panel() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		_sync_spins()


func _sync_spins(_value: int = 0) -> void:
	level_spin.set_value_no_signal(GameSession.current_level)
	wave_spin.set_value_no_signal(GameSession.current_wave)


func _on_go_pressed() -> void:
	jump_requested.emit(int(level_spin.value), int(wave_spin.value))
