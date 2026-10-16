extends SceneTree
## Headless validation: instances every scene with autoloads present.
## Run: godot --headless --script res://tests/validate_scenes.gd
## Prints OK/FAIL per scene and quits with code 1 on failure.

const AUTOLOADS := [
	["SaveManager", "res://scripts/save/save_manager.gd"],
	["AudioManager", "res://scripts/managers/audio_manager.gd"],
	["GameManager", "res://scripts/managers/game_manager.gd"],
]

const SCENES := [
	"res://scenes/menus/main_menu.tscn",
	"res://scenes/menus/level_select.tscn",
	"res://scenes/menus/settings_menu.tscn",
	"res://scenes/player/ball_player.tscn",
	"res://scenes/objects/collectible.tscn",
	"res://scenes/objects/checkpoint.tscn",
	"res://scenes/objects/finish_trigger.tscn",
	"res://scenes/objects/moving_platform.tscn",
	"res://scenes/objects/rotating_obstacle.tscn",
	"res://scenes/objects/hazard.tscn",
	"res://scenes/objects/static_platform.tscn",
	"res://scenes/ui/gameplay_hud.tscn",
	"res://scenes/ui/mobile_controls.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/level_complete.tscn",
	"res://scenes/levels/level_01_sky_meadow.tscn",
	"res://scenes/levels/level_02_crystal_bridges.tscn",
	"res://scenes/levels/level_03_skyfall_challenge.tscn",
]

var failures := 0


func _initialize() -> void:
	for pair in AUTOLOADS:
		var scr: Script = load(pair[1])
		if scr == null:
			print("FAIL autoload script: ", pair[1])
			failures += 1
			continue
		var node: Node = scr.new()
		node.name = pair[0]
		root.add_child(node)
		print("OK autoload: ", pair[0])

	for path in SCENES:
		var ps: PackedScene = load(path)
		if ps == null:
			print("FAIL load: ", path)
			failures += 1
			continue
		if not ps.can_instantiate():
			print("FAIL instantiate check: ", path)
			failures += 1
			continue
		var inst: Node = ps.instantiate()
		root.add_child(inst)
		# Spot-check critical wiring per scene type.
		_check(inst, path)
		inst.queue_free()

	if failures == 0:
		print("VALIDATION PASSED: all scenes instantiated cleanly.")
	else:
		print("VALIDATION FAILED: ", failures, " problem(s).")
	quit(failures)


func _check(inst: Node, path: String) -> void:
	if path.contains("level_0"):
		var player: Node = inst.get_node_or_null("BallPlayer")
		var hud: Node = inst.get_node_or_null("HUD")
		var spawn: Node = inst.get_node_or_null("SpawnPoint")
		if player == null or hud == null or spawn == null:
			print("FAIL wiring in ", path, ": missing BallPlayer/HUD/SpawnPoint")
			failures += 1
		else:
			print("OK ", path)
	elif path.contains("main_menu"):
		for n in ["Center/VBox/PlayButton", "LevelPanel", "SettingsPanel", "HelpPanel"]:
			if inst.get_node_or_null(n) == null:
				print("FAIL wiring in ", path, ": missing ", n)
				failures += 1
				return
		print("OK ", path)
	else:
		print("OK ", path)
