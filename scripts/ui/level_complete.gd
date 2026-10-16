extends Control
## LevelComplete - standalone completion panel (also embedded in the HUD).

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var stats_label: Label = $Panel/VBox/StatsLabel
@onready var best_label: Label = $Panel/VBox/BestLabel
@onready var replay_button: Button = $Panel/VBox/Buttons/ReplayButton
@onready var next_button: Button = $Panel/VBox/Buttons/NextButton
@onready var menu_button: Button = $Panel/VBox/Buttons/MenuButton


func _ready() -> void:
	if replay_button != null:
		replay_button.pressed.connect(_on_replay)
	if next_button != null:
		next_button.pressed.connect(_on_next)
	if menu_button != null:
		menu_button.pressed.connect(_on_menu)


func setup(gems: int, total: int, time_sec: float, best: float, new_best: bool) -> void:
	if stats_label != null:
		stats_label.text = "Gems: %d / %d\nTime: %s" % [gems, total, _fmt(time_sec)]
	if best_label != null:
		if new_best:
			best_label.text = "★ New best time! ★"
		elif best > 0.0:
			best_label.text = "Best: %s" % _fmt(best)
		else:
			best_label.text = ""


func _fmt(sec: float) -> String:
	return "%02d:%02d.%02d" % [int(sec) / 60, int(sec) % 60, int(sec * 100.0) % 100]


func _on_replay() -> void:
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").restart_level()


func _on_next() -> void:
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if not gm.next_level():
			gm.load_main_menu()


func _on_menu() -> void:
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").load_main_menu()
