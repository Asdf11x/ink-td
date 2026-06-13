extends Control

@onready var continue_button: Button = %ContinueButton
@onready var back_button: Button = %BackButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue)
	back_button.pressed.connect(_on_back)


func _on_continue() -> void:
	GameSession.start_run()
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
