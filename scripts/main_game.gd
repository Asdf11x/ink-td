extends Node2D

enum Phase { INTRO, PREP, WAVE, INTERMISSION, ENDED }

const INTRO_STEP_DURATION := 0.85
const GO_HINT_FADE_SEC := 3.0

@onready var ink_manager: InkManager = $InkManager
@onready var ink_grid: InkGrid = $GameArea/InkGrid
@onready var pen_bar: PenBar = $UI/PenBar
@onready var game_area: Node2D = $GameArea
@onready var feedback_label: Label = $UI/FeedbackLabel
@onready var wave_spawner: WaveSpawner = $WaveSpawner
@onready var enemies_root: Node2D = $GameArea/Enemies
@onready var towers_root: Node2D = $GameArea/Towers
@onready var projectiles_root: Node2D = $GameArea/Projectiles
@onready var hud: Control = $UI/HUD
@onready var level_banner: Control = $UI/LevelBanner
@onready var results_overlay: Control = $UI/ResultsOverlay
@onready var wave_controls: WaveControls = $UI/WaveControls
@onready var eraser_cursor: Node2D = $GameArea/EraserCursor
@onready var hud_menu_button: Button = %HudMenuButton
@onready var debug_menu: DebugMenu = $UI/DebugMenu
@onready var shortcut_overlay: ShortcutOverlay = $ShortcutOverlay
@onready var pause_menu: PauseMenu = $UI/PauseMenu

var _is_painting := false
var _last_cell := Vector2i(-9999, -9999)
var _feedback_timer := 0.0
var _phase := Phase.PREP
var _intro_timer := 0.0
var _intro_index := 0
var _go_hint_timer := 0.0
var _show_go_hint := false
var _pause_menu_open := false


func _ready() -> void:
	GameShortcuts.ensure_input_actions()
	Engine.time_scale = 1.0
	ink_manager.reset_pools_for_run()
	pen_bar.bind_manager(ink_manager)
	eraser_cursor.setup(ink_grid, ink_manager)
	ink_grid.bind_enemies(enemies_root)
	ink_grid.ink_denied.connect(_on_ink_denied)
	wave_spawner.wave_cleared.connect(_on_wave_cleared)
	wave_spawner.core_breached.connect(_on_core_breached)
	wave_spawner.enemy_count_changed.connect(_on_enemy_count_changed)
	wave_spawner.xp_earned.connect(_on_xp_earned)
	results_overlay.menu_requested.connect(_on_menu_requested)
	wave_controls.go_pressed.connect(_on_go_pressed)
	hud_menu_button.pressed.connect(_open_pause_menu)
	pause_menu.resume_pressed.connect(_on_pause_menu_resume)
	pause_menu.quit_to_menu_pressed.connect(_quit_to_main_menu)
	debug_menu.unlimited_ink_toggled.connect(_on_debug_unlimited_ink)
	debug_menu.jump_requested.connect(_on_debug_jump)
	shortcut_overlay.alt_visible_changed.connect(_on_shortcuts_visible)
	_layout_game_area()
	_apply_level_layout()
	if GameSession.run_intro_pending:
		_begin_intro()
	else:
		_begin_wave_prep(false)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.05, 0.04, 0.07), true)


func _layout_game_area() -> void:
	game_area.position = Vector2(
		(get_viewport_rect().size.x - GameConstants.GRID_PIXEL_SIZE.x) * 0.5,
		GameConstants.GAME_AREA_TOP
	)


func _apply_level_layout() -> void:
	var level: int = GameSession.current_level
	_clear_towers()
	ink_grid.apply_level_layout(
		LevelLayout.get_blocked_cells(level),
		LevelLayout.get_water_cells(level)
	)
	var tower_cells: Array[Vector2i] = LevelLayout.get_tower_cells(level)
	ink_grid.apply_tower_cells(tower_cells)
	_spawn_towers(tower_cells)


func _spawn_towers(cells: Array[Vector2i]) -> void:
	for cell: Vector2i in cells:
		var tower := Tower.new()
		towers_root.add_child(tower)
		tower.setup(cell, enemies_root, projectiles_root)


func _clear_towers() -> void:
	for child in towers_root.get_children():
		child.queue_free()
	for child in projectiles_root.get_children():
		child.queue_free()


func _on_shortcuts_visible(visible: bool) -> void:
	pen_bar.set_shortcuts_visible(visible)
	wave_controls.set_shortcuts_visible(visible)
	hud.set_shortcuts_visible(visible)
	debug_menu.set_shortcuts_visible(visible)


func _process(delta: float) -> void:
	if _feedback_timer > 0.0:
		_feedback_timer -= delta
		if _feedback_timer <= 0.0:
			feedback_label.modulate.a = 0.0

	if _show_go_hint:
		_go_hint_timer -= delta
		if _go_hint_timer <= 0.0:
			_show_go_hint = false
			level_banner.hide_message()

	if _pause_menu_open:
		return

	match _phase:
		Phase.INTRO:
			_process_intro(delta)
		Phase.PREP:
			_process_prep(delta)

	if _is_painting and _can_draw():
		var cell: Vector2i = ink_grid.cell_from_world(get_global_mouse_position())
		if cell != _last_cell:
			_paint_cell(cell)


func _can_draw() -> bool:
	return _phase == Phase.PREP or _phase == Phase.WAVE


func _process_intro(delta: float) -> void:
	_intro_timer -= delta
	if _intro_timer > 0.0:
		return
	_intro_index += 1
	if _intro_index >= 4:
		GameSession.run_intro_pending = false
		_begin_wave_prep(true)
		return
	_intro_timer = INTRO_STEP_DURATION
	if _intro_index < 3:
		level_banner.show_countdown(str(3 - _intro_index))
	else:
		level_banner.show_message("Draw!")


func _process_prep(_delta: float) -> void:
	if _show_go_hint:
		level_banner.show_message("Press GO when ready (Space)")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(GameShortcuts.ACTION_MENU):
		if _phase != Phase.INTRO and _phase != Phase.ENDED:
			if _pause_menu_open:
				_on_pause_menu_resume()
			else:
				_open_pause_menu()
			get_viewport().set_input_as_handled()
		return

	if _pause_menu_open or _phase == Phase.ENDED or _phase == Phase.INTRO:
		return

	if event.is_action_pressed(GameShortcuts.ACTION_DEBUG):
		debug_menu.toggle_open()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(GameShortcuts.ACTION_SPACE):
		if _phase == Phase.PREP and not wave_controls.go_button.disabled:
			_on_go_pressed()
			get_viewport().set_input_as_handled()
		elif _phase == Phase.WAVE:
			wave_controls.toggle_pause()
			get_viewport().set_input_as_handled()
		return

	for action: StringName in GameShortcuts.SPEED_BY_ACTION.keys():
		if event.is_action_pressed(action):
			wave_controls.select_speed(GameShortcuts.SPEED_BY_ACTION[action])
			get_viewport().set_input_as_handled()
			return

	for ink_type: InkType.Type in InkType.all_tool_types():
		if event.is_action_pressed(InkType.INPUT_ACTIONS[ink_type]):
			ink_manager.select(ink_type)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and _can_draw():
		if event.pressed:
			_is_painting = true
			_last_cell = Vector2i(-9999, -9999)
			_paint_cell(ink_grid.cell_from_world(get_global_mouse_position()))
		else:
			_is_painting = false
			_last_cell = Vector2i(-9999, -9999)


func _begin_intro() -> void:
	_phase = Phase.INTRO
	_intro_index = 0
	_intro_timer = INTRO_STEP_DURATION
	wave_controls.set_go_enabled(false)
	level_banner.show_countdown("3")


func _begin_wave_prep(first_after_intro: bool) -> void:
	_phase = Phase.PREP
	_clear_enemies()
	wave_spawner.configure(
		ink_grid, enemies_root, GameSession.current_level, GameSession.current_wave
	)
	wave_controls.set_paused(false)
	wave_controls.set_go_enabled(true)
	hud.set_enemies_remaining(
		LevelConfig.creeps_per_wave(GameSession.current_level, GameSession.current_wave)
		+ (1 if LevelConfig.is_boss_wave(GameSession.current_level, GameSession.current_wave) else 0)
	)
	if first_after_intro and GameSession.current_level == 1 and GameSession.current_wave == 1:
		_show_go_hint = true
		_go_hint_timer = GO_HINT_FADE_SEC
		level_banner.show_message("Press GO when ready (Space)")
	else:
		level_banner.hide_message()


func _on_go_pressed() -> void:
	if _phase == Phase.PREP:
		_show_go_hint = false
		level_banner.hide_message()
		_begin_wave()
	elif _phase == Phase.WAVE and wave_controls.is_paused():
		wave_controls.set_paused(false)


func _begin_wave() -> void:
	if _phase == Phase.ENDED:
		return
	_phase = Phase.WAVE
	wave_controls.set_go_enabled(false)
	level_banner.hide_message()
	wave_spawner.begin_spawning()


func _paint_cell(cell: Vector2i) -> void:
	if cell == _last_cell:
		return
	var ink_type: InkType.Type = ink_manager.selected
	if not ink_manager.try_spend(ink_type, 1.0):
		_update_feedback("Out of %s ink." % InkType.DISPLAY_NAMES[ink_type])
		return
	if ink_grid.try_paint(cell, ink_type):
		_last_cell = cell
	elif ink_type != InkType.Type.ERASER and not ink_manager.debug_unlimited_ink:
		var pool: InkPool = ink_manager.get_pool(ink_type)
		if pool:
			pool.current += 1.0


func _on_ink_denied(_cell: Vector2i, ink_type: InkType.Type, reason: String) -> void:
	_update_feedback(reason if reason != "" else "Cannot place %s here." % InkType.DISPLAY_NAMES[ink_type])


func _on_wave_cleared() -> void:
	if _phase == Phase.ENDED:
		return
	if GameSession.current_wave < LevelConfig.WAVES_PER_LEVEL:
		GameSession.advance_wave()
		_begin_wave_prep(false)
		return
	if GameSession.current_level >= LevelConfig.TOTAL_LEVELS:
		_end_run(true)
		return
	_phase = Phase.INTERMISSION
	level_banner.show_message("Level %d complete!" % GameSession.current_level)
	await get_tree().create_timer(2.0).timeout
	if _phase != Phase.INTERMISSION:
		return
	GameSession.advance_level()
	ink_grid.reset_grid()
	_apply_level_layout()
	_begin_wave_prep(false)


func _on_core_breached() -> void:
	if _phase == Phase.ENDED:
		return
	if GameSession.lose_life():
		_end_run(false)


func _on_enemy_count_changed(remaining: int) -> void:
	hud.set_enemies_remaining(remaining)


func _on_xp_earned(amount: int) -> void:
	_update_feedback("+%d XP" % amount)


func _end_run(victory: bool) -> void:
	_phase = Phase.ENDED
	_is_painting = false
	Engine.time_scale = 1.0
	GameSession.stop_run(victory)
	level_banner.hide_message()
	if victory:
		results_overlay.show_victory(GameSession.elapsed_seconds)
	else:
		results_overlay.show_game_over(GameSession.elapsed_seconds)


func _clear_enemies() -> void:
	for child in enemies_root.get_children():
		child.queue_free()


func _on_menu_requested() -> void:
	_quit_to_main_menu()


func _open_pause_menu() -> void:
	if _phase == Phase.ENDED or _phase == Phase.INTRO or _pause_menu_open:
		return
	_is_painting = false
	_pause_menu_open = true
	Engine.time_scale = 0.0
	pause_menu.show_menu()


func _on_pause_menu_resume() -> void:
	if not _pause_menu_open:
		return
	_pause_menu_open = false
	pause_menu.hide_menu()
	if _phase == Phase.WAVE:
		wave_controls.reapply_time_scale()
	else:
		Engine.time_scale = 1.0


func _quit_to_main_menu() -> void:
	_pause_menu_open = false
	pause_menu.hide_menu()
	Engine.time_scale = 1.0
	var tree := get_tree()
	if tree == null:
		return
	tree.change_scene_to_file("res://scenes/main_menu.tscn")


func _update_feedback(text: String) -> void:
	feedback_label.text = text
	feedback_label.modulate.a = 1.0
	_feedback_timer = 2.4


func _on_debug_unlimited_ink(enabled: bool) -> void:
	ink_manager.debug_unlimited_ink = enabled


func _on_debug_jump(level: int, wave: int) -> void:
	if _phase == Phase.ENDED:
		return
	GameSession.debug_set_level_wave(level, wave)
	_is_painting = false
	_show_go_hint = false
	wave_spawner.halt()
	_clear_enemies()
	ink_grid.reset_grid()
	_apply_level_layout()
	_begin_wave_prep(false)
