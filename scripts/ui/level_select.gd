extends Control
## LevelSelect - standalone level grid (mirrors the popup in the main menu).

@onready var grid: HBoxContainer = $Center/VBox/Levels
@onready var back_button: Button = $Center/VBox/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back)
	refresh()
	UISound.hookup(self)


func refresh() -> void:
	for child in grid.get_children():
		child.queue_free()
	var sm = get_node_or_null("/root/SaveManager")
	var gm = get_node_or_null("/root/GameManager")
	if sm == null or gm == null:
		return
	for i in range(1, 4):
		var b := Button.new()
		if sm.is_unlocked(i):
			b.text = "%d. %s" % [i, gm.level_name(i)]
			b.custom_minimum_size = Vector2(220, 70)
			var idx := i
			b.pressed.connect(func() -> void: gm.load_level(idx))
		else:
			b.text = "%d. Locked" % i
			b.disabled = true
			b.custom_minimum_size = Vector2(220, 70)
		grid.add_child(b)


func _on_back() -> void:
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").load_main_menu()
