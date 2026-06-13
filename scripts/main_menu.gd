extends Control

@onready var start_button: Button = %StartButton
@onready var skill_tree_button: Button = %SkillTreeButton
@onready var exit_button: Button = %ExitButton
@onready var record_label: Label = %RecordLabel
@onready var xp_label: Label = %XpLabel


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	skill_tree_button.pressed.connect(_on_skill_tree_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	SkillProgress.skills_changed.connect(_refresh_meta)
	_refresh_meta()
	_refresh_record_label()


func _refresh_meta() -> void:
	xp_label.text = "Global Lv %d  ·  %d XP to spend" % [
		SkillProgress.get_global_level(),
		SkillProgress.get_available_xp(),
	]


func _refresh_record_label() -> void:
	if GameSession.has_fastest_run():
		record_label.text = "Swiftest Seal: %s" % GameSession.get_fastest_run_text()
	else:
		record_label.text = "Swiftest Seal: —"


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/instructions_screen.tscn")


func _on_skill_tree_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/skill_tree_screen.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
