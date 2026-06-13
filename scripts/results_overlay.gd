extends Control

signal menu_requested

@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel
@onready var time_label: Label = %TimeLabel
@onready var menu_button: Button = %ResultsMenuButton


func _ready() -> void:
	visible = false
	menu_button.pressed.connect(_on_menu_pressed)


func show_victory(elapsed_seconds: float) -> void:
	title_label.text = "The Core Holds!"
	message_label.text = "Congratulations — all five levels cleared!"
	time_label.text = "Run completed in %s" % TimeFormatter.format_duration(elapsed_seconds)
	if GameSession.has_fastest_run():
		time_label.text += "\nSwiftest Seal: %s" % GameSession.get_fastest_run_text()
	_show()


func show_game_over(elapsed_seconds: float) -> void:
	title_label.text = "The Core Fell"
	message_label.text = "Intruders breached the heart. Try a tighter maze and hotter inks."
	time_label.text = "Run lasted %s" % TimeFormatter.format_duration(elapsed_seconds)
	_show()


func _show() -> void:
	visible = true


func _on_menu_pressed() -> void:
	menu_requested.emit()
