extends Node3D
## LevelBase - shared logic for all levels. Attach to each level root.
## Handles spawn/respawn, falling, gems, timer, pause, completion, HUD hooks.
## Put this node in group "level" (done automatically here).

@export var level_index := 1
@export var level_name := "Sky Meadow"
@export var fall_y := -14.0
@export var total_gems_in_level := 0  # 0 = auto-count at runtime

var spawn_position := Vector3.ZERO
var gems_collected := 0
var gems_total := 0
var elapsed := 0.0
var is_complete := false
var _paused := false

@onready var player: CharacterBody3D = $BallPlayer
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	add_to_group("level")
	if spawn_point != null:
		spawn_position = spawn_point.global_position
	elif player != null:
		spawn_position = player.global_position
	if player != null:
		player.add_to_group("player")
		if player.has_signal("jumped"):
			player.jumped.connect(_on_player_jumped)
	gems_total = total_gems_in_level
	if gems_total <= 0:
		gems_total = get_tree().get_nodes_in_group("collectible").size()
		if gems_total <= 0:
			gems_total = _count_collectibles()
	# Wire HUD buttons if present.
	if hud != null and hud.has_method("bind_level"):
		hud.bind_level(self)
		hud.call("set_level_info", level_name, gems_collected, gems_total)
	_update_hud()


func _count_collectibles() -> int:
	var n := 0
	var stack: Array[Node] = [self]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node != self and node.is_in_group("collectible"):
			n += 1
		for c in node.get_children():
			stack.append(c)
	return n


func _process(delta: float) -> void:
	if is_complete or _paused:
		return
	elapsed += delta
	if player != null and player.global_position.y < fall_y:
		_respawn("You fell! Back to checkpoint.")
	_update_hud_time()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		toggle_pause()
	elif event.is_action_pressed("restart_checkpoint"):
		if not is_complete and not _paused:
			_respawn("Restarted at checkpoint.")


# --- Callbacks from objects (via call_group) ---

func on_collectible(_c: Node) -> void:
	if is_complete:
		return
	gems_collected += 1
	_update_hud()
	if hud != null and hud.has_method("flash_message"):
		if gems_collected >= gems_total:
			hud.call("flash_message", "All gems collected!")


func on_checkpoint(cp: Node) -> void:
	if player == null:
		return
	# Respawn slightly above the checkpoint pad so we never clip into it.
	spawn_position = cp.global_position + Vector3(0, 1.2, 0)
	if hud != null and hud.has_method("flash_message"):
		hud.call("flash_message", "Checkpoint!")


func on_hazard() -> void:
	if is_complete or _paused:
		return
	_respawn("Ouch! Back to checkpoint.")


func on_finish() -> void:
	if is_complete:
		return
	complete_level()


# --- Respawn / restart ---

func _respawn(reason: String) -> void:
	if player == null or is_complete:
		return
	if player.has_method("respawn_at"):
		player.respawn_at(spawn_position + Vector3(0, 0.5, 0))
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("respawn")
	if hud != null and hud.has_method("flash_message") and not reason.is_empty():
		hud.call("flash_message", reason)


func restart_from_checkpoint() -> void:
	get_tree().paused = false
	_paused = false
	_respawn("")


func restart_level() -> void:
	get_tree().paused = false
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").restart_level()
	else:
		get_tree().reload_current_scene()


func quit_to_menu() -> void:
	get_tree().paused = false
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").load_main_menu()


# --- Pause ---

func toggle_pause() -> void:
	if is_complete:
		return
	set_paused(not _paused)


func set_paused(value: bool) -> void:
	_paused = value
	get_tree().paused = value
	if player != null and player.has_method("set_frozen"):
		player.set_frozen(value)
	if hud != null and hud.has_method("set_pause_visible"):
		hud.call("set_pause_visible", value)


func is_paused() -> bool:
	return _paused


# --- Completion ---

func complete_level() -> void:
	is_complete = true
	if player != null and player.has_method("set_frozen"):
		player.set_frozen(true)
	var new_best := false
	if has_node("/root/SaveManager"):
		new_best = get_node("/root/SaveManager").complete_level(level_index, gems_collected, elapsed)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("win")
	var best := -1.0
	if has_node("/root/SaveManager"):
		best = get_node("/root/SaveManager").get_best_time(level_index)
	if hud != null and hud.has_method("show_complete"):
		hud.call("show_complete", gems_collected, gems_total, elapsed, best, new_best)


func _on_player_jumped() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("jump")


# --- HUD helpers ---

func _update_hud() -> void:
	if hud != null and hud.has_method("set_level_info"):
		hud.call("set_level_info", level_name, gems_collected, gems_total)


func _update_hud_time() -> void:
	if hud != null and hud.has_method("set_time"):
		hud.call("set_time", elapsed)


static func format_time(sec: float) -> String:
	var m := int(sec) / 60
	var s := int(sec) % 60
	var c := int(sec * 100.0) % 100
	return "%02d:%02d.%02d" % [m, s, c]
