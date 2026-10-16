extends Control
## MainMenu - title screen with Play, Level Select, Settings, Help, Quit.

@onready var play_button: Button = $Center/VBox/PlayButton
@onready var levels_button: Button = $Center/VBox/LevelsButton
@onready var settings_button: Button = $Center/VBox/SettingsButton
@onready var help_button: Button = $Center/VBox/HelpButton
@onready var quit_button: Button = $Center/VBox/QuitButton
@onready var gems_label: Label = $Center/VBox/GemsLabel
@onready var level_panel: PanelContainer = $LevelPanel
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var help_panel: PanelContainer = $HelpPanel


func _ready() -> void:
	play_button.pressed.connect(_on_play)
	levels_button.pressed.connect(func() -> void: _show_only(level_panel))
	settings_button.pressed.connect(func() -> void: _show_only(settings_panel))
	help_button.pressed.connect(func() -> void: _show_only(help_panel))
	quit_button.pressed.connect(_on_quit)
	level_panel.get_node("VBox/CloseButton").pressed.connect(func() -> void: _show_only(null))
	settings_panel.get_node("VBox/CloseButton").pressed.connect(func() -> void: _show_only(null))
	help_panel.get_node("VBox/CloseButton").pressed.connect(func() -> void: _show_only(null))
	_show_only(null)
	_refresh()
	_build_level_buttons()


func _refresh() -> void:
	if has_node("/root/SaveManager"):
		var sm = get_node("/root/SaveManager")
		gems_label.text = "💎 Total gems: %d" % sm.total_gems
	# Quit only makes sense on desktop.
	quit_button.visible = OS.has_feature("windows") or OS.has_feature("linux") or OS.has_feature("macos")


func _show_only(panel: Control) -> void:
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").click()
	level_panel.visible = panel == level_panel
	settings_panel.visible = panel == settings_panel
	help_panel.visible = panel == help_panel


func _on_play() -> void:
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		var sm = get_node("/root/SaveManager")
		# Continue at the highest unlocked, uncompleted level.
		var target := 1
		for i in range(1, 4):
			if sm.is_unlocked(i) and not sm.is_completed(i):
				target = i
				break
			if sm.is_unlocked(i):
				target = i
		gm.load_level(target)


func _build_level_buttons() -> void:
	var grid: HBoxContainer = level_panel.get_node("VBox/Levels")
	for child in grid.get_children():
		child.queue_free()
	for i in range(1, 4):
		var b := Button.new()
		var sm = get_node("/root/SaveManager")
		var gm = get_node("/root/GameManager")
		var lname: String = gm.level_name(i)
		if sm.is_unlocked(i):
			b.text = "%d. %s" % [i, lname]
			if sm.is_completed(i):
				var best: float = sm.get_best_time(i)
				if best > 0.0:
					b.text += "\n★ %s" % _fmt(best)
			b.custom_minimum_size = Vector2(200, 64)
			var idx := i
			b.pressed.connect(func() -> void: gm.load_level(idx))
		else:
			b.text = "%d. 🔒 Locked" % i
			b.disabled = true
			b.custom_minimum_size = Vector2(200, 64)
		grid.add_child(b)


func _fmt(sec: float) -> String:
	return "%02d:%02d.%02d" % [int(sec) / 60, int(sec) % 60, int(sec * 100.0) % 100]


func _on_quit() -> void:
	get_tree().quit()
