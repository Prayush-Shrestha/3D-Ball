extends CanvasLayer
## GameplayHUD - top bar, messages, pause + complete overlays, touch controls.
## Touch controls auto-show on mobile / touch devices, or per user setting.

var level: Node = null

@onready var level_label: Label = $TopBar/LevelLabel
@onready var gem_label: Label = $TopBar/GemLabel
@onready var time_label: Label = $TopBar/TimeLabel
@onready var pause_button: Button = $TopBar/PauseButton
@onready var message_label: Label = $MessageLabel
@onready var touch_layer: Control = $TouchControls
@onready var joystick = $TouchControls/Joystick
@onready var jump_button: Button = $TouchControls/JumpButton
@onready var pause_overlay: Control = $PauseOverlay
@onready var complete_overlay: Control = $CompleteOverlay
@onready var flash_rect: ColorRect = $FlashRect

var _msg_tween: Tween = null
var _flash_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if pause_button != null:
		pause_button.pressed.connect(_on_pause_pressed)
	if jump_button != null:
		jump_button.pressed.connect(_on_jump_pressed)
	if pause_overlay != null:
		pause_overlay.visible = false
		_wire_pause_buttons()
	if complete_overlay != null:
		complete_overlay.visible = false
		_wire_complete_buttons()
	UISound.hookup(self, [jump_button])
	_update_touch_visibility()


func bind_level(lv: Node) -> void:
	level = lv


func set_level_info(lv_name: String, gems: int, total: int) -> void:
	if level_label != null:
		level_label.text = lv_name
	if gem_label != null:
		gem_label.text = "💎 %d / %d" % [gems, total]


func set_time(sec: float) -> void:
	if time_label != null:
		var m := int(sec) / 60
		var s := int(sec) % 60
		time_label.text = "%02d:%02d" % [m, s]


func flash_message(text: String) -> void:
	if message_label == null:
		return
	message_label.text = text
	message_label.modulate.a = 1.0
	if _msg_tween != null and _msg_tween.is_valid():
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.tween_interval(1.2)
	_msg_tween.tween_property(message_label, "modulate:a", 0.0, 0.6)


func flash_screen(c: Color) -> void:
	# Full-screen color blink for respawns, hazards, and victories.
	if flash_rect == null:
		return
	flash_rect.color = c
	flash_rect.modulate.a = 0.32
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(flash_rect, "modulate:a", 0.0, 0.45)


func set_pause_visible(v: bool) -> void:
	if pause_overlay != null:
		pause_overlay.visible = v


func show_complete(gems: int, total: int, time_sec: float, best: float, new_best: bool) -> void:
	if complete_overlay == null:
		return
	complete_overlay.visible = true
	var title: Label = complete_overlay.get_node_or_null("Panel/VBox/TitleLabel")
	var stats: Label = complete_overlay.get_node_or_null("Panel/VBox/StatsLabel")
	var best_l: Label = complete_overlay.get_node_or_null("Panel/VBox/BestLabel")
	if title != null:
		title.text = "LEVEL COMPLETE!"
	var t := _fmt(time_sec)
	if stats != null:
		stats.text = "Gems: %d / %d\nTime: %s" % [gems, total, t]
	if best_l != null:
		if new_best:
			best_l.text = "★ New best time! ★"
		elif best > 0.0:
			best_l.text = "Best: %s" % _fmt(best)
		else:
			best_l.text = ""


func _fmt(sec: float) -> String:
	var m := int(sec) / 60
	var s := int(sec) % 60
	var c := int(sec * 100.0) % 100
	return "%02d:%02d.%02d" % [m, s, c]


func _update_touch_visibility() -> void:
	if touch_layer == null:
		return
	var show := DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	if has_node("/root/SaveManager"):
		var pref: int = get_node("/root/SaveManager").show_touch_controls
		if pref == 1:
			show = true
		elif pref == 2:
			show = false
	touch_layer.visible = show


func _on_pause_pressed() -> void:
	if level != null and level.has_method("toggle_pause"):
		level.toggle_pause()


func _on_jump_pressed() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p = players[0]
	if "external_jump_request" in p:
		p.external_jump_request = true


func _wire_pause_buttons() -> void:
	var resume_btn: Button = pause_overlay.get_node_or_null("Panel/VBox/ResumeButton")
	var cp_btn: Button = pause_overlay.get_node_or_null("Panel/VBox/CheckpointButton")
	var restart_btn: Button = pause_overlay.get_node_or_null("Panel/VBox/RestartButton")
	var menu_btn: Button = pause_overlay.get_node_or_null("Panel/VBox/MenuButton")
	if resume_btn != null:
		resume_btn.pressed.connect(func() -> void: level.set_paused(false))
	if cp_btn != null:
		cp_btn.pressed.connect(func() -> void: level.set_paused(false); level.restart_from_checkpoint())
	if restart_btn != null:
		restart_btn.pressed.connect(func() -> void: level.restart_level())
	if menu_btn != null:
		menu_btn.pressed.connect(func() -> void: level.quit_to_menu())


func _wire_complete_buttons() -> void:
	var replay_btn: Button = complete_overlay.get_node_or_null("Panel/VBox/Buttons/ReplayButton")
	var next_btn: Button = complete_overlay.get_node_or_null("Panel/VBox/Buttons/NextButton")
	var menu_btn: Button = complete_overlay.get_node_or_null("Panel/VBox/Buttons/MenuButton")
	if replay_btn != null:
		replay_btn.pressed.connect(func() -> void: level.restart_level())
	if next_btn != null:
		next_btn.pressed.connect(_on_next_pressed)
	if menu_btn != null:
		menu_btn.pressed.connect(func() -> void: level.quit_to_menu())


func _on_next_pressed() -> void:
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if not gm.next_level():
			gm.load_main_menu()
