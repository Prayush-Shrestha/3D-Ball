extends Node
## GameManager (autoload) - level list, scene transitions, shared input map.
## Levels: 1 = Sky Meadow, 2 = Crystal Bridges, 3 = Skyfall Challenge.

const LEVELS := [
	{"name": "Sky Meadow", "path": "res://scenes/levels/level_01_sky_meadow.tscn"},
	{"name": "Crystal Bridges", "path": "res://scenes/levels/level_02_crystal_bridges.tscn"},
	{"name": "Skyfall Challenge", "path": "res://scenes/levels/level_03_skyfall_challenge.tscn"},
]
const MAIN_MENU := "res://scenes/menus/main_menu.tscn"

var current_level := 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_input_actions()


func level_count() -> int:
	return LEVELS.size()


func level_name(index: int) -> String:
	if index >= 1 and index <= LEVELS.size():
		return String(LEVELS[index - 1]["name"])
	return "Unknown"


func level_path(index: int) -> String:
	if index >= 1 and index <= LEVELS.size():
		return String(LEVELS[index - 1]["path"])
	return MAIN_MENU


func load_main_menu() -> void:
	current_level = 0
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)


func load_level(index: int) -> void:
	index = clampi(index, 1, LEVELS.size())
	current_level = index
	get_tree().paused = false
	get_tree().change_scene_to_file(level_path(index))


func next_level() -> bool:
	if current_level + 1 <= LEVELS.size():
		load_level(current_level + 1)
		return true
	return false


func restart_level() -> void:
	get_tree().paused = false
	if current_level >= 1:
		get_tree().change_scene_to_file(level_path(current_level))
	else:
		get_tree().reload_current_scene()


func click() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("click")


func _ensure_input_actions() -> void:
	# Creates keyboard actions at runtime so the game works even if the
	# project.godot input section is edited by hand. Safe to call twice.
	_add_key_action("move_forward", [KEY_W, KEY_UP])
	_add_key_action("move_back", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("jump", [KEY_SPACE])
	_add_key_action("restart_checkpoint", [KEY_R])
	_add_key_action("pause_game", [KEY_ESCAPE, KEY_P])


func _add_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for k in keys:
		var exists := false
		for e in InputMap.action_get_events(action):
			if e is InputEventKey and e.physical_keycode == k:
				exists = true
				break
		if not exists:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
