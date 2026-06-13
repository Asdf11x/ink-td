extends Control

@onready var message_label: Label = %BannerLabel


func show_countdown(number_text: String) -> void:
	message_label.text = number_text
	message_label.add_theme_font_size_override("font_size", 64)
	visible = true


func show_message(text: String) -> void:
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.text = text
	visible = true


func hide_message() -> void:
	visible = false
