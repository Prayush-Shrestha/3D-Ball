extends Control
## PauseMenu - standalone pause panel (also embedded in the HUD).
## Expects the current level in group "level" with set_paused/restart methods.

@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var checkpoint_button: Button = $Panel/VBox/CheckpointButton
@onready var restart_button: Button = $Panel/VBox/RestartButton
@onready var menu_button: Button = $Panel/VBox/MenuButton


func _ready() -> void:
	if resume_button != null:
		resume_button.pressed.connect(_on_resume)
	if checkpoint_button != null:
		checkpoint_button.pressed.connect(_on_checkpoint)
	if restart_button != null:
		restart_button.pressed.connect(_on_restart)
	if menu_button != null:
		menu_button.pressed.connect(_on_menu)
	UISound.hookup(self)


func _level():
	var nodes := get_tree().get_nodes_in_group("level")
	if nodes.is_empty():
		return null
	return nodes[0]


func _on_resume() -> void:
	var lv = _level()
	if lv != null:
		lv.set_paused(false)


func _on_checkpoint() -> void:
	var lv = _level()
	if lv != null:
		lv.set_paused(false)
		lv.restart_from_checkpoint()


func _on_restart() -> void:
	var lv = _level()
	if lv != null:
		lv.restart_level()


func _on_menu() -> void:
	var lv = _level()
	if lv != null:
		lv.quit_to_menu()
	elif has_node("/root/GameManager"):
		get_node("/root/GameManager").load_main_menu()
