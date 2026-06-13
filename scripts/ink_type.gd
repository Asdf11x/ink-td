class_name InkType
extends RefCounted

enum Type { WALL, FIRE, POISON, FREEZE, ERASER }

enum Combo { NONE, PURPLE, BROWN, TEAL }


const DISPLAY_NAMES: Dictionary[Type, String] = {
	Type.WALL: "Wall",
	Type.FIRE: "Fire",
	Type.POISON: "Poison",
	Type.FREEZE: "Freeze",
	Type.ERASER: "Rubber",
}

const COLORS: Dictionary[Type, Color] = {
	Type.WALL: Color(0.07, 0.05, 0.1),
	Type.FIRE: Color(0.82, 0.22, 0.18),
	Type.POISON: Color(0.22, 0.68, 0.30),
	Type.FREEZE: Color(0.22, 0.48, 0.84),
	Type.ERASER: Color(0.75, 0.72, 0.68),
}

const GLOW_COLORS: Dictionary[Type, Color] = {
	Type.WALL: Color(0.35, 0.28, 0.48),
	Type.FIRE: Color(1.0, 0.45, 0.35),
	Type.POISON: Color(0.45, 1.0, 0.55),
	Type.FREEZE: Color(0.45, 0.75, 1.0),
	Type.ERASER: Color(0.95, 0.9, 0.85),
}

const COMBO_COLORS: Dictionary[Combo, Color] = {
	Combo.PURPLE: Color(0.62, 0.22, 0.78),
	Combo.BROWN: Color(0.55, 0.32, 0.18),
	Combo.TEAL: Color(0.18, 0.62, 0.58),
}

const INPUT_ACTIONS: Dictionary[Type, StringName] = {
	Type.WALL: &"select_wall",
	Type.FIRE: &"select_fire",
	Type.POISON: &"select_poison",
	Type.FREEZE: &"select_freeze",
	Type.ERASER: &"select_eraser",
}

const HOTKEY_LABELS: Dictionary[Type, String] = {
	Type.WALL: "1",
	Type.FIRE: "2",
	Type.POISON: "3",
	Type.FREEZE: "4",
	Type.ERASER: "5",
}

const PAINT_TYPES: Array[Type] = [Type.WALL, Type.FIRE, Type.POISON, Type.FREEZE]
const BASE_EFFECT_TYPES: Array[Type] = [Type.FIRE, Type.POISON, Type.FREEZE]


static func all_tool_types() -> Array[Type]:
	return [Type.WALL, Type.FIRE, Type.POISON, Type.FREEZE, Type.ERASER]


static func combo_from_pair(a: Type, b: Type) -> Combo:
	if a == Type.FIRE and b == Type.FREEZE or a == Type.FREEZE and b == Type.FIRE:
		return Combo.PURPLE
	if a == Type.FIRE and b == Type.POISON or a == Type.POISON and b == Type.FIRE:
		return Combo.BROWN
	if a == Type.POISON and b == Type.FREEZE or a == Type.FREEZE and b == Type.POISON:
		return Combo.TEAL
	return Combo.NONE


static func combo_has_fire(combo: Combo) -> bool:
	return combo == Combo.PURPLE or combo == Combo.BROWN


static func combo_has_poison(combo: Combo) -> bool:
	return combo == Combo.BROWN or combo == Combo.TEAL


static func combo_has_freeze(combo: Combo) -> bool:
	return combo == Combo.PURPLE or combo == Combo.TEAL
