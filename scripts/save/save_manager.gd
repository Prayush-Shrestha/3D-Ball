extends Node
## SaveManager (autoload) - lightweight JSON save in user:// directory.
## Stores unlocked levels, completed levels, gems, best times, audio + camera prefs.

const SAVE_PATH := "user://rolling_realms_save.json"

var unlocked_levels: int = 1
var completed_levels: Array = []
var total_gems: int = 0
var best_times: Dictionary = {}
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var camera_sensitivity: float = 1.0
var show_touch_controls: int = 0  # 0 = auto, 1 = always on, 2 = always off

var _loaded := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()


func default_data() -> Dictionary:
	return {
		"unlocked_levels": 1,
		"completed_levels": [],
		"total_gems": 0,
		"best_times": {},
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"camera_sensitivity": 1.0,
		"show_touch_controls": 0,
	}


func load_game() -> void:
	_loaded = true
	if not FileAccess.file_exists(SAVE_PATH):
		_apply_data(default_data())
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: could not open save file, using defaults.")
		_apply_data(default_data())
		return
	var text := file.get_as_text()
	file.close()
	if text.strip_edges().is_empty():
		_apply_data(default_data())
		return
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: invalid save data, using defaults.")
		_apply_data(default_data())
		return
	_apply_data(parsed)


func _apply_data(d: Dictionary) -> void:
	unlocked_levels = clampi(int(d.get("unlocked_levels", 1)), 1, 3)
	completed_levels = d.get("completed_levels", [])
	if typeof(completed_levels) != TYPE_ARRAY:
		completed_levels = []
	total_gems = maxi(0, int(d.get("total_gems", 0)))
	best_times = d.get("best_times", {})
	if typeof(best_times) != TYPE_DICTIONARY:
		best_times = {}
	master_volume = clampf(float(d.get("master_volume", 1.0)), 0.0, 1.0)
	music_volume = clampf(float(d.get("music_volume", 0.8)), 0.0, 1.0)
	sfx_volume = clampf(float(d.get("sfx_volume", 1.0)), 0.0, 1.0)
	camera_sensitivity = clampf(float(d.get("camera_sensitivity", 1.0)), 0.2, 3.0)
	show_touch_controls = clampi(int(d.get("show_touch_controls", 0)), 0, 2)


func save_game() -> void:
	var d := {
		"unlocked_levels": unlocked_levels,
		"completed_levels": completed_levels,
		"total_gems": total_gems,
		"best_times": best_times,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"camera_sensitivity": camera_sensitivity,
		"show_touch_controls": show_touch_controls,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: could not write save file.")
		return
	file.store_string(JSON.stringify(d, "\t"))
	file.close()


func is_unlocked(level_index: int) -> bool:
	return level_index <= unlocked_levels


func is_completed(level_index: int) -> bool:
	return completed_levels.has(level_index)


func complete_level(level_index: int, gems_collected: int, time_sec: float) -> bool:
	# Returns true if this was a new best time.
	var new_best := false
	var key := str(level_index)
	if not completed_levels.has(level_index):
		completed_levels.append(level_index)
	if level_index >= unlocked_levels and unlocked_levels < 3:
		unlocked_levels = mini(3, level_index + 1)
	total_gems += gems_collected
	if time_sec > 0.0:
		if not best_times.has(key) or time_sec < float(best_times[key]):
			best_times[key] = snappedf(time_sec, 0.01)
			new_best = true
	save_game()
	return new_best


func get_best_time(level_index: int) -> float:
	var key := str(level_index)
	if best_times.has(key):
		return float(best_times[key])
	return -1.0


func set_volumes(master: float, music: float, sfx: float) -> void:
	master_volume = clampf(master, 0.0, 1.0)
	music_volume = clampf(music, 0.0, 1.0)
	sfx_volume = clampf(sfx, 0.0, 1.0)
	save_game()
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").apply_volumes()
