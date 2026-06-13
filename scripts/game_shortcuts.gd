class_name GameShortcuts
extends RefCounted

const ALT_HINT := "Hold Alt for shortcuts"

const ACTION_SPACE := &"game_pause"
const ACTION_MENU := &"game_menu"
const ACTION_DEBUG := &"game_debug"
const ACTION_SPEED_1 := &"game_speed_1"
const ACTION_SPEED_2 := &"game_speed_2"
const ACTION_SPEED_3 := &"game_speed_3"

const SPEED_BY_ACTION: Dictionary = {
	ACTION_SPEED_1: 1.0,
	ACTION_SPEED_2: 3.0,
	ACTION_SPEED_3: 5.0,
}


static func ensure_input_actions() -> void:
	_set_keys(InkType.INPUT_ACTIONS[InkType.Type.WALL], [KEY_1])
	_set_keys(InkType.INPUT_ACTIONS[InkType.Type.FIRE], [KEY_2])
	_set_keys(InkType.INPUT_ACTIONS[InkType.Type.POISON], [KEY_3])
	_set_keys(InkType.INPUT_ACTIONS[InkType.Type.FREEZE], [KEY_4])
	_set_keys(InkType.INPUT_ACTIONS[InkType.Type.ERASER], [KEY_5])
	_set_keys(ACTION_SPEED_1, [KEY_Q])
	_set_keys(ACTION_SPEED_2, [KEY_W])
	_set_keys(ACTION_SPEED_3, [KEY_E])
	_set_keys(ACTION_SPACE, [KEY_SPACE])
	_set_keys(ACTION_MENU, [KEY_ESCAPE])
	_set_keys(ACTION_DEBUG, [KEY_D])


static func _set_keys(action: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event: InputEvent in InputMap.action_get_events(action):
		InputMap.action_erase_event(action, event)
	for key: int in keys:
		var new_event := InputEventKey.new()
		new_event.physical_keycode = key as Key
		InputMap.action_add_event(action, new_event)
