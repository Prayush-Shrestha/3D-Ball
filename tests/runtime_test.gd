extends SceneTree
## Headless runtime test: plays Level 1 with synthetic input through real physics.
## Run: godot --headless --script res://tests/runtime_test.gd
## Verifies movement, collision, jump, collectible, checkpoint, respawn, finish.

var failures := 0
var stage := 0
var stage_frame := 0
var level: Node = null
var player: CharacterBody3D = null
var start_pos := Vector3.ZERO
var jump_y := 0.0


func _initialize() -> void:
	_add_autoload("SaveManager", "res://scripts/save/save_manager.gd")
	_add_autoload("AudioManager", "res://scripts/managers/audio_manager.gd")
	_add_autoload("GameManager", "res://scripts/managers/game_manager.gd")
	var ps: PackedScene = load("res://scenes/levels/level_01_sky_meadow.tscn")
	level = ps.instantiate()
	root.add_child(level)
	player = level.get_node("BallPlayer")
	start_pos = player.global_position
	print("TEST start pos: ", start_pos)


func _add_autoload(node_name: String, path: String) -> void:
	var scr: Script = load(path)
	var node: Node = scr.new()
	node.name = node_name
	root.add_child(node)


func _process(_delta: float) -> bool:
	var f := Engine.get_physics_frames()
	match stage:
		0:
			# Settle on the start platform, then drive forward.
			# NOTE: global_position is only valid after the first tree
			# frames, so capture the start here, not in _initialize.
			if f > 30:
				start_pos = player.global_position
				print("TEST settled pos: ", start_pos)
				_next()
				player.input_vector = Vector2(0, -1)
		1:
			# Drive forward for ~1 second. Must stay on the flat start
			# platform (no gaps involved) so the result is deterministic.
			if _frames_in_stage(f, 60):
				var moved: float = start_pos.z - player.global_position.z
				_check("ball moved forward (dz %.2f)" % moved, moved > 3.0)
				_check("ball did not fall through world", player.global_position.y > -5.0)
				_next()
				_teleport(Vector3(0, 1.2, 4))
		2:
			# Land, then jump.
			if _frames_in_stage(f, 40):
				jump_y = player.global_position.y
				player.external_jump_request = true
				_next()
		3:
			if _frames_in_stage(f, 20):
				_check("jump gained height (y %.2f -> %.2f)" % [jump_y, player.global_position.y], player.global_position.y > jump_y + 0.2)
				_next()
				_teleport(Vector3(0, 1.8, -8))  # Gem1 location
		4:
			if _frames_in_stage(f, 40):
				_check("gem collected exactly once (got %d)" % level.gems_collected, level.gems_collected == 1)
				_next()
				_teleport(Vector3(2.5, 3.5, -30))  # Checkpoint1
		5:
			if _frames_in_stage(f, 40):
				var d: float = level.spawn_position.distance_to(Vector3(2.5, 3.7, -30))
				_check("checkpoint updated spawn (dist %.2f)" % d, d < 2.0)
				_next()
				_teleport(Vector3(0, -20, 0))  # fall out
		6:
			if _frames_in_stage(f, 40):
				_check("fall respawned near checkpoint (y %.2f)" % player.global_position.y, player.global_position.y > -5.0)
				_next()
				level.set_paused(true)
		7:
			if _frames_in_stage(f, 10):
				_check("pause freezes tree", paused)
				level.set_paused(false)
				_check("resume unfreezes tree", not paused)
				_next()
				_teleport(Vector3(0, 4.0, -71))  # Finish pad
		8:
			if _frames_in_stage(f, 40):
				_check("level completed", level.is_complete)
				var sm = root.get_node("SaveManager")
				_check("save recorded completion", sm.completed_levels.has(1))
				_check("save file exists", FileAccess.file_exists("user://rolling_realms_save.json"))
				_finish()
	return false


func _frames_in_stage(f: int, needed: int) -> bool:
	return f - stage_frame >= needed


func _next() -> void:
	stage += 1
	stage_frame = Engine.get_physics_frames()


func _teleport(pos: Vector3) -> void:
	player.input_vector = Vector2.ZERO
	player.velocity = Vector3.ZERO
	player.global_position = pos


func _check(label: String, ok: bool) -> void:
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		print("FAIL: ", label)


func _finish() -> void:
	if failures == 0:
		print("RUNTIME TEST PASSED")
	else:
		print("RUNTIME TEST FAILED: ", failures, " failure(s)")
	quit(failures)
