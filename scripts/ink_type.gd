class_name InkType
extends RefCounted

enum Type { WALL, DAMAGE, POISON, SLOW }

const DISPLAY_NAMES: Dictionary = {
	Type.WALL: "Void",
	Type.DAMAGE: "Ember",
	Type.POISON: "Verdant",
	Type.SLOW: "Aether",
}

const DESCRIPTIONS: Dictionary = {
	Type.WALL: "Maze walls — blocks the rift path",
	Type.DAMAGE: "Burns intruders on contact",
	Type.POISON: "Corrodes over time",
	Type.SLOW: "Thickens movement",
}

const COLORS: Dictionary = {
	Type.WALL: Color(0.11, 0.09, 0.13),
	Type.DAMAGE: Color(0.82, 0.22, 0.18),
	Type.POISON: Color(0.22, 0.68, 0.30),
	Type.SLOW: Color(0.22, 0.48, 0.84),
}

const GLOW_COLORS: Dictionary = {
	Type.WALL: Color(0.35, 0.28, 0.48),
	Type.DAMAGE: Color(1.0, 0.45, 0.35),
	Type.POISON: Color(0.45, 1.0, 0.55),
	Type.SLOW: Color(0.45, 0.75, 1.0),
}

const INPUT_ACTIONS: Dictionary = {
	Type.WALL: &"select_wall",
	Type.DAMAGE: &"select_damage",
	Type.POISON: &"select_poison",
	Type.SLOW: &"select_slow",
}

const HOTKEY_LABELS: Dictionary = {
	Type.WALL: "1",
	Type.DAMAGE: "2",
	Type.POISON: "3",
	Type.SLOW: "4",
}

static func all_types() -> Array[Type]:
	return [Type.WALL, Type.DAMAGE, Type.POISON, Type.SLOW]
