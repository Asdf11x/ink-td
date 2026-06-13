extends Control

@onready var back_button: Button = %BackButton
@onready var xp_label: Label = %XpLabel

var _buttons: Dictionary[StringName, Button] = {}


func _ready() -> void:
	back_button.pressed.connect(_on_back)
	_buttons[SkillProgress.SKILL_WALL_PIXELS] = $"Margin/VBox/Flows/WallRow/B"
	_buttons[SkillProgress.SKILL_FIRE_PIXELS] = $"Margin/VBox/Flows/FireRow/P"
	_buttons[SkillProgress.SKILL_FIRE_DMG] = $"Margin/VBox/Flows/FireRow/D"
	_buttons[SkillProgress.SKILL_POISON_PIXELS] = $"Margin/VBox/Flows/PoisonRow/P"
	_buttons[SkillProgress.SKILL_POISON_DMG] = $"Margin/VBox/Flows/PoisonRow/D"
	_buttons[SkillProgress.SKILL_FREEZE_PIXELS] = $"Margin/VBox/Flows/FreezeRow/P"
	_buttons[SkillProgress.SKILL_FREEZE_DMG] = $"Margin/VBox/Flows/FreezeRow/D"
	_buttons[SkillProgress.SKILL_ERASER_PIXELS] = $"Margin/VBox/Flows/EraserRow/B"
	_buttons[SkillProgress.SKILL_TOWER_DMG] = $"Margin/VBox/Flows/TowerRow/D"
	_buttons[SkillProgress.SKILL_TOWER_RANGE] = $"Margin/VBox/Flows/TowerRow/R"
	_buttons[SkillProgress.SKILL_TOWER_RATE] = $"Margin/VBox/Flows/TowerRow/S"
	for skill_id: StringName in _buttons.keys():
		var id: StringName = skill_id
		_buttons[skill_id].pressed.connect(func() -> void: _on_upgrade(id))
	SkillProgress.skills_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var progress: Dictionary = SkillProgress.get_level_progress()
	xp_label.text = (
		"XP: %d available  ·  %d earned  ·  Global Lv %d (%d / %d)"
		% [
			SkillProgress.get_available_xp(),
			SkillProgress.total_xp,
			progress["level"],
			progress["current"],
			progress["needed"],
		]
	)
	_set_btn(SkillProgress.SKILL_WALL_PIXELS, SkillProgress.SKILL_WALL_PIXELS)
	_set_btn(SkillProgress.SKILL_FIRE_PIXELS, SkillProgress.SKILL_FIRE_PIXELS)
	_set_btn(SkillProgress.SKILL_FIRE_DMG, SkillProgress.SKILL_FIRE_DMG)
	_set_btn(SkillProgress.SKILL_POISON_PIXELS, SkillProgress.SKILL_POISON_PIXELS)
	_set_btn(SkillProgress.SKILL_POISON_DMG, SkillProgress.SKILL_POISON_DMG)
	_set_btn(SkillProgress.SKILL_FREEZE_PIXELS, SkillProgress.SKILL_FREEZE_PIXELS)
	_set_btn(SkillProgress.SKILL_FREEZE_DMG, SkillProgress.SKILL_FREEZE_DMG)
	_set_btn(SkillProgress.SKILL_ERASER_PIXELS, SkillProgress.SKILL_ERASER_PIXELS)
	_set_btn(SkillProgress.SKILL_TOWER_DMG, SkillProgress.SKILL_TOWER_DMG)
	_set_btn(SkillProgress.SKILL_TOWER_RANGE, SkillProgress.SKILL_TOWER_RANGE)
	_set_btn(SkillProgress.SKILL_TOWER_RATE, SkillProgress.SKILL_TOWER_RATE)


func _set_btn(skill_id: StringName, _unused: StringName) -> void:
	var btn: Button = _buttons[skill_id]
	var tier: int = SkillProgress.get_skill_tier(skill_id)
	if tier >= SkillProgress.TIERS_PER_SKILL:
		btn.text = "Maxed (%d/3)" % tier
		btn.disabled = true
		return
	var cost: int = SkillProgress.get_upgrade_cost(skill_id)
	btn.text = "Tier %d/3  ·  %d XP" % [tier, cost]
	btn.disabled = not SkillProgress.can_upgrade(skill_id)


func _on_upgrade(skill_id: StringName) -> void:
	if SkillProgress.try_upgrade(skill_id):
		_refresh()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
