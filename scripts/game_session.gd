extends Node

signal run_started
signal run_finished(elapsed_seconds: float, is_victory: bool)
signal level_changed(level: int)
signal wave_changed(wave: int)
signal lives_changed(lives: int)

const SAVE_PATH := "user://ink_td_save.cfg"
const STARTING_LIVES := 3

var elapsed_seconds: float = 0.0
var run_active: bool = false
var current_level: int = 1
var current_wave: int = 1
var lives: int = STARTING_LIVES
var fastest_run_seconds: float = -1.0
var run_intro_pending: bool = false
var waves_cleared_this_run: int = 0


func _ready() -> void:
	load_progress()


func _process(delta: float) -> void:
	if run_active:
		elapsed_seconds += delta


func start_run() -> void:
	elapsed_seconds = 0.0
	run_active = true
	current_level = 1
	current_wave = 1
	lives = STARTING_LIVES
	waves_cleared_this_run = 0
	run_intro_pending = true
	SkillProgress.reset_run_xp()
	run_started.emit()
	level_changed.emit(current_level)
	wave_changed.emit(current_wave)
	lives_changed.emit(lives)


func stop_run(is_victory: bool) -> void:
	if not run_active:
		return

	run_active = false
	if is_victory and (fastest_run_seconds < 0.0 or elapsed_seconds < fastest_run_seconds):
		fastest_run_seconds = elapsed_seconds
		save_progress()

	run_finished.emit(elapsed_seconds, is_victory)


func advance_wave() -> bool:
	waves_cleared_this_run += 1
	if current_wave < LevelConfig.WAVES_PER_LEVEL:
		current_wave += 1
		wave_changed.emit(current_wave)
		return true
	return false


func advance_level() -> bool:
	if current_level >= LevelConfig.TOTAL_LEVELS:
		return false
	current_level += 1
	current_wave = 1
	level_changed.emit(current_level)
	wave_changed.emit(current_wave)
	return true


func lose_life() -> bool:
	lives -= 1
	lives_changed.emit(lives)
	return lives <= 0


func debug_set_level_wave(level: int, wave: int) -> void:
	current_level = clampi(level, 1, LevelConfig.TOTAL_LEVELS)
	current_wave = clampi(wave, 1, LevelConfig.WAVES_PER_LEVEL)
	level_changed.emit(current_level)
	wave_changed.emit(current_wave)


func has_fastest_run() -> bool:
	return fastest_run_seconds >= 0.0


func get_fastest_run_text() -> String:
	if not has_fastest_run():
		return ""
	return TimeFormatter.format_duration(fastest_run_seconds)


func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	fastest_run_seconds = float(config.get_value("progress", "fastest_run_seconds", -1.0))


func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "fastest_run_seconds", fastest_run_seconds)
	config.save(SAVE_PATH)
