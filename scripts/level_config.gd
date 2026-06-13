class_name LevelConfig
extends RefCounted

const TOTAL_LEVELS := 5
const WAVES_PER_LEVEL := 5


static func creeps_per_wave(level: int, wave: int) -> int:
	return 2 + wave + level


static func creep_hp(level: int, wave: int) -> float:
	return 16.0 + level * 8.0 + wave * 3.0


static func creep_speed(level: int) -> float:
	return 40.0 + level * 3.0


static func spawn_interval(level: int, wave: int) -> float:
	return maxf(0.3, 1.0 - level * 0.08 - wave * 0.04)


static func prep_seconds(level: int, wave: int) -> float:
	if level == 1 and wave == 1:
		return 999.0
	return 5.0


static func is_boss_wave(level: int, wave: int) -> bool:
	return level == TOTAL_LEVELS and wave == WAVES_PER_LEVEL


static func boss_hp(level: int) -> float:
	return 220.0 + level * 40.0


static func boss_speed(level: int) -> float:
	return creep_speed(level) * 0.48


static func boss_scale() -> float:
	return 2.2
