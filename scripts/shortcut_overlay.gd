class_name ShortcutOverlay
extends Node

signal alt_visible_changed(visible: bool)

var _alt_showing := false


func _process(_delta: float) -> void:
	var alt_pressed: bool = Input.is_key_pressed(KEY_ALT)
	if alt_pressed == _alt_showing:
		return
	_alt_showing = alt_pressed
	alt_visible_changed.emit(alt_pressed)
