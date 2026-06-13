extends Node

## Persistent XP and skill tree progress. XP from kills; spend XP to upgrade skills.

signal skills_changed

const SAVE_PATH := "user://skill_progress.cfg"
const TIERS_PER_SKILL := 3
const TIERS_TO_UNLOCK_NEXT := 2
const XP_PER_KILL := 10
const XP_PER_BOSS := 50
const BASE_LEVEL_XP := 40
const LEVEL_XP_STEP := 20

const SKILL_WALL_PIXELS := &"wall_pixels"
const SKILL_FIRE_PIXELS := &"fire_pixels"
const SKILL_FIRE_DMG := &"fire_dmg"
const SKILL_POISON_PIXELS := &"poison_pixels"
const SKILL_POISON_DMG := &"poison_dmg"
const SKILL_FREEZE_PIXELS := &"freeze_pixels"
const SKILL_FREEZE_DMG := &"freeze_dmg"
const SKILL_ERASER_PIXELS := &"eraser_pixels"
const SKILL_TOWER_DMG := &"tower_dmg"
const SKILL_TOWER_RANGE := &"tower_range"
const SKILL_TOWER_RATE := &"tower_rate"

var total_xp: int = 0
var spent_xp: int = 0
var run_xp_gained: int = 0
var _tiers: Dictionary[StringName, int] = {}


func _ready() -> void:
	load_progress()
	_ensure_skills()


func get_available_xp() -> int:
	return maxi(0, total_xp - spent_xp)


func award_kill_xp(is_boss: bool = false) -> int:
	var gained: int = XP_PER_BOSS if is_boss else XP_PER_KILL
	total_xp += gained
	run_xp_gained += gained
	save_progress()
	skills_changed.emit()
	return gained


func reset_run_xp() -> void:
	run_xp_gained = 0


func get_skill_tier(skill_id: StringName) -> int:
	return int(_tiers.get(skill_id, 0))


func get_tier_cost(tier: int) -> int:
	return BASE_LEVEL_XP + (tier - 1) * LEVEL_XP_STEP


func get_upgrade_cost(skill_id: StringName) -> int:
	var next_tier: int = get_skill_tier(skill_id) + 1
	if next_tier > TIERS_PER_SKILL:
		return 0
	return get_tier_cost(next_tier)


func can_upgrade(skill_id: StringName) -> bool:
	var tier: int = get_skill_tier(skill_id)
	if tier >= TIERS_PER_SKILL:
		return false
	if get_available_xp() < get_upgrade_cost(skill_id):
		return false
	if tier == 0:
		return true
	var flow_spent: int = _points_spent_in_flow(_flow_for(skill_id))
	return flow_spent >= TIERS_TO_UNLOCK_NEXT


func try_upgrade(skill_id: StringName) -> bool:
	if not can_upgrade(skill_id):
		return false
	var cost: int = get_upgrade_cost(skill_id)
	spent_xp += cost
	_tiers[skill_id] = get_skill_tier(skill_id) + 1
	save_progress()
	skills_changed.emit()
	return true


func get_damage_bonus_percent(ink_type: InkType.Type) -> float:
	var skill: StringName = &""
	match ink_type:
		InkType.Type.FIRE:
			skill = SKILL_FIRE_DMG
		InkType.Type.POISON:
			skill = SKILL_POISON_DMG
		InkType.Type.FREEZE:
			skill = SKILL_FREEZE_DMG
		_:
			return 0.0
	return float(get_skill_tier(skill) * 10)


func get_tower_damage_multiplier() -> float:
	return 1.0 + float(get_skill_tier(SKILL_TOWER_DMG)) * 0.12


func get_tower_range_cells() -> float:
	return 2.5 + float(get_skill_tier(SKILL_TOWER_RANGE)) * 0.4


func get_tower_attack_interval() -> float:
	var tier: int = get_skill_tier(SKILL_TOWER_RATE)
	return maxf(0.35, 0.85 - float(tier) * 0.12)


func get_pixel_bonus(skill_id: StringName) -> int:
	var tier: int = get_skill_tier(skill_id)
	match skill_id:
		SKILL_WALL_PIXELS, SKILL_FIRE_PIXELS, SKILL_POISON_PIXELS, SKILL_FREEZE_PIXELS:
			return tier * 10
		SKILL_ERASER_PIXELS:
			match tier:
				1: return 2
				2: return 5
				3: return 10
				_: return 0
	return 0


func get_global_level() -> int:
	var level: int = 1
	var remaining: int = total_xp
	var step: int = BASE_LEVEL_XP
	while remaining >= step:
		remaining -= step
		level += 1
		step += LEVEL_XP_STEP
	return level


func get_level_progress() -> Dictionary:
	var level: int = get_global_level()
	var xp_into_level: int = total_xp
	var step: int = BASE_LEVEL_XP
	for _i: int in range(level - 1):
		xp_into_level -= step
		step += LEVEL_XP_STEP
	return {"level": level, "current": xp_into_level, "needed": step}


func _points_spent_in_flow(flow: StringName) -> int:
	var spent: int = 0
	for skill_id: StringName in _tiers.keys():
		if _flow_for(skill_id) == flow:
			spent += get_skill_tier(skill_id)
	return spent


func _flow_for(skill_id: StringName) -> StringName:
	if skill_id == SKILL_WALL_PIXELS:
		return &"wall"
	if skill_id == SKILL_ERASER_PIXELS:
		return &"eraser"
	if skill_id.begins_with("tower"):
		return &"tower"
	if skill_id.begins_with("fire"):
		return &"fire"
	if skill_id.begins_with("poison"):
		return &"poison"
	if skill_id.begins_with("freeze"):
		return &"freeze"
	return &"unknown"


func _ensure_skills() -> void:
	var ids: Array[StringName] = [
		SKILL_WALL_PIXELS,
		SKILL_FIRE_PIXELS, SKILL_FIRE_DMG,
		SKILL_POISON_PIXELS, SKILL_POISON_DMG,
		SKILL_FREEZE_PIXELS, SKILL_FREEZE_DMG,
		SKILL_ERASER_PIXELS,
		SKILL_TOWER_DMG, SKILL_TOWER_RANGE, SKILL_TOWER_RATE,
	]
	for id: StringName in ids:
		if not _tiers.has(id):
			_tiers[id] = 0


func _spent_xp_from_tiers() -> int:
	var spent: int = 0
	for skill_id: StringName in _tiers.keys():
		for tier: int in range(1, get_skill_tier(skill_id) + 1):
			spent += get_tier_cost(tier)
	return spent


func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		_ensure_skills()
		return
	total_xp = int(config.get_value("skills", "total_xp", 0))
	for key in config.get_section_keys("skill_tiers"):
		_tiers[StringName(key)] = int(config.get_value("skill_tiers", key, 0))
	_ensure_skills()
	if config.has_section_key("skills", "spent_xp"):
		spent_xp = int(config.get_value("skills", "spent_xp", 0))
	else:
		total_xp += int(config.get_value("skills", "unspent_points", 0))
		spent_xp = _spent_xp_from_tiers()


func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("skills", "total_xp", total_xp)
	config.set_value("skills", "spent_xp", spent_xp)
	for skill_id: StringName in _tiers.keys():
		config.set_value("skill_tiers", str(skill_id), get_skill_tier(skill_id))
	config.save(SAVE_PATH)
