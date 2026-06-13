class_name PauseMenu
extends Control

signal resume_pressed
signal quit_to_menu_pressed

@onready var resume_button: Button = %ResumeButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 40
	resume_button.pressed.connect(func() -> void: resume_pressed.emit())
	quit_button.pressed.connect(func() -> void: quit_to_menu_pressed.emit())


func show_menu() -> void:
	visible = true


func hide_menu() -> void:
	visible = false
