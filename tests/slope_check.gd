extends SceneTree
## Slope check: raycasts the ramp surfaces to prove they tilt the right way.
## Level 1 ramp must RISE toward -Z (P2 side). Level 3 ramp must FALL toward -Z.

var failures := 0
var n := 0
var level_a: Node = null
var level_b: Node = null


func _initialize() -> void:
	for pair in [["SaveManager", "res://scripts/save/save_manager.gd"], ["AudioManager", "res://scripts/managers/audio_manager.gd"], ["GameManager", "res://scripts/managers/game_manager.gd"]]:
		var s: Script = load(pair[1])
		var nd: Node = s.new()
		nd.name = pair[0]
		root.add_child(nd)
	var ps: PackedScene = load("res://scenes/levels/level_01_sky_meadow.tscn")
	level_a = ps.instantiate()
	root.add_child(level_a)


func _process(_delta: float) -> bool:
	n += 1
	if n == 5:
		_check_ramp(level_a, "res://scenes/levels/level_01_sky_meadow.tscn", Vector3(0, 8, -17), Vector3(0, 8, -25), true)
		level_a.queue_free()
		var ps: PackedScene = load("res://scenes/levels/level_03_skyfall_challenge.tscn")
		level_b = ps.instantiate()
		root.add_child(level_b)
	elif n == 10:
		_check_ramp(level_b, "res://scenes/levels/level_03_skyfall_challenge.tscn", Vector3(-8, 8, -31), Vector3(-8, 8, -39), false)
		level_b.queue_free()
		if failures == 0:
			print("SLOPE CHECK PASSED")
		else:
			print("SLOPE CHECK FAILED")
		quit(failures)
	return false


func _ray_top(level: Node, at: Vector3) -> float:
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(at, at + Vector3(0, -40, 0))
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return -999.0
	return (hit["position"] as Vector3).y


func _check_ramp(level: Node, path: String, near_z: Vector3, far_z: Vector3, must_rise: bool) -> void:
	var y_near := _ray_top(level, near_z)
	var y_far := _ray_top(level, far_z)
	var rises := y_far > y_near + 0.3
	print(path, " near=", snappedf(y_near, 0.01), " far=", snappedf(y_far, 0.01), " rises=", rises)
	if rises == must_rise:
		print("PASS slope in ", path)
	else:
		failures += 1
		print("FAIL slope in ", path)
