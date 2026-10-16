extends SceneTree
## Screenshot tool: runs Level 1 in a real window and saves PNGs to docs/shots/.
## Run WITHOUT --headless so the GPU renders, e.g.:
##   godot --script res://tests/screenshot.gd --resolution 1280x720
## Captures spawn view, bridge view, and finish view, then quits.

var level: Node = null
var player: CharacterBody3D = null
var n := 0
var out_dir := "D:/3D ball/docs/shots"
var want_menu := false


func _initialize() -> void:
	for pair in [["SaveManager", "res://scripts/save/save_manager.gd"], ["AudioManager", "res://scripts/managers/audio_manager.gd"], ["GameManager", "res://scripts/managers/game_manager.gd"]]:
		var s: Script = load(pair[1])
		var nd: Node = s.new()
		nd.name = pair[0]
		root.add_child(nd)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var all_args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for arg in all_args:
		if arg == "--menu" or arg == "menu":
			want_menu = true
	if want_menu:
		var ps: PackedScene = load("res://scenes/menus/main_menu.tscn")
		root.add_child(ps.instantiate())
	else:
		var ps2: PackedScene = load("res://scenes/levels/level_01_sky_meadow.tscn")
		level = ps2.instantiate()
		root.add_child(level)
		player = level.get_node("BallPlayer")


func _process(_delta: float) -> bool:
	n += 1
	if want_menu:
		if n == 90:
			_snap("shot_menu.png")
		if n == 120:
			print("SCREENSHOTS DONE")
			quit(0)
		return false
	if n == 10:
		_snap("shot_spawn.png")
	if n == 20:
		player.input_vector = Vector2(0, -1)
	if n == 100:
		_snap("shot_drive.png")
		_teleport(Vector3(0, 3.5, -38))
	if n == 140:
		_snap("shot_bridge.png")
		_teleport(Vector3(0, 3.5, -60))
	if n == 180:
		_snap("shot_finish.png")
	if n == 220:
		print("SCREENSHOTS DONE")
		quit(0)
	return false


func _teleport(pos: Vector3) -> void:
	player.input_vector = Vector2.ZERO
	player.velocity = Vector3.ZERO
	player.global_position = pos


func _snap(file_name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	var err := img.save_png(out_dir + "/" + file_name)
	print("saved ", file_name, " err=", err)
