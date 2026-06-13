extends SceneTree

## Headless project validator.
## Run:  godot --headless --path . --script res://tools/validate_project.gd
## Or:   .\tools\validate.ps1

const SCRIPT_DIRS: Array[String] = ["res://scripts"]
const SCENES: Array[String] = [
	"res://scenes/main_menu.tscn",
	"res://scenes/main_game.tscn",
	"res://scenes/creep.tscn",
]


func _init() -> void:
	var failed := false

	for path: String in _gather_gd_scripts():
		if not _validate_script(path):
			failed = true

	for scene_path: String in SCENES:
		if not _validate_scene(scene_path):
			failed = true

	if failed:
		push_error("=== Validation FAILED ===")
		quit(1)
	else:
		print("=== All scripts and scenes validated OK ===")
		quit(0)


func _validate_script(path: String) -> bool:
	var script: GDScript = load(path)
	if script == null:
		push_error("FAIL script: %s" % path)
		return false
	print("OK   script: %s" % path)
	return true


func _validate_scene(path: String) -> bool:
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("FAIL scene:  %s" % path)
		return false
	print("OK   scene:  %s" % path)
	return true


func _gather_gd_scripts() -> PackedStringArray:
	var results: PackedStringArray = []
	for dir_path: String in SCRIPT_DIRS:
		_collect_in_dir(dir_path, results)
	return results


func _collect_in_dir(dir_path: String, results: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Cannot open: %s" % dir_path)
		return

	for entry_name: String in dir.get_files():
		if entry_name.ends_with(".gd"):
			results.append("%s/%s" % [dir_path, entry_name])

	for entry_name: String in dir.get_directories():
		if entry_name.begins_with("."):
			continue
		_collect_in_dir("%s/%s" % [dir_path, entry_name], results)
