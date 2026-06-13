extends Control

@onready var level_label: Label = %LevelLabel
@onready var wave_label: Label = %WaveLabel
@onready var timer_label: Label = %TimerLabel
@onready var enemies_label: Label = %EnemiesLabel
@onready var hearts_root: HBoxContainer = %HeartsRoot
@onready var menu_button: Button = %HudMenuButton
@onready var xp_label: Label = %XpLabel

var _menu_hint: ShortcutHint


func _ready() -> void:
	_menu_hint = ShortcutHint.attach(menu_button, "Esc")
	SkillProgress.skills_changed.connect(_on_xp_changed)
	GameSession.level_changed.connect(_on_level_changed)
	GameSession.wave_changed.connect(_on_wave_changed)
	GameSession.lives_changed.connect(_on_lives_changed)
	_on_level_changed(GameSession.current_level)
	_on_wave_changed(GameSession.current_wave)
	_on_lives_changed(GameSession.lives)
	_on_xp_changed()


func _process(_delta: float) -> void:
	timer_label.text = TimeFormatter.format_duration(GameSession.elapsed_seconds)


func _on_xp_changed(_unused: int = 0) -> void:
	var progress: Dictionary = SkillProgress.get_level_progress()
	xp_label.text = "XP %d  ·  Lv %d" % [SkillProgress.get_available_xp(), progress["level"]]


func _on_level_changed(level: int) -> void:
	level_label.text = "Level %d / %d" % [level, LevelConfig.TOTAL_LEVELS]


func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Wave %d / %d" % [wave, LevelConfig.WAVES_PER_LEVEL]


func _on_lives_changed(lives: int) -> void:
	_update_hearts(lives)


func set_enemies_remaining(count: int) -> void:
	enemies_label.text = "Intruders: %d" % count


func set_shortcuts_visible(visible: bool) -> void:
	if _menu_hint:
		_menu_hint.visible = visible


func _update_hearts(lives: int) -> void:
	for child in hearts_root.get_children():
		child.queue_free()
	for i in GameSession.STARTING_LIVES:
		var heart := _HeartIcon.new()
		heart.filled = i < lives
		hearts_root.add_child(heart)


class _HeartIcon extends Control:
	var filled: bool = true
	const SIZE := 18.0

	func _ready() -> void:
		custom_minimum_size = Vector2(SIZE + 4, SIZE + 2)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c: Color = Color(0.92, 0.22, 0.28) if filled else Color(0.25, 0.2, 0.24)
		var cx: float = size.x * 0.5
		var cy: float = size.y * 0.55
		draw_circle(Vector2(cx - 4, cy - 2), 4.5, c)
		draw_circle(Vector2(cx + 4, cy - 2), 4.5, c)
		draw_colored_polygon(
			PackedVector2Array([Vector2(cx, cy + 7), Vector2(cx - 9, cy - 1), Vector2(cx + 9, cy - 1)]),
			c
		)
