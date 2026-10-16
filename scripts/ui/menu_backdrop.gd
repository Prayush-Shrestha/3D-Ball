extends Node3D
## MenuBackdrop - live 3D diorama behind the main menu (shown in a SubViewport).
## A demo ball orbits a floating island while the camera slowly revolves.
## Pure decoration: plain MeshInstances, no physics, no gameplay code.

var _angle := 0.0
var _time := 0.0

@onready var cam_rig: Node3D = $CamRig
@onready var demo_ball: Node3D = $DemoBall
@onready var demo_mesh: MeshInstance3D = $DemoBall/BallMesh
@onready var gems: Node3D = $Gems


func _process(delta: float) -> void:
	_time += delta
	_angle += delta * 0.25
	if cam_rig != null:
		cam_rig.rotation.y = _angle
	if demo_ball != null:
		var a := _time * 0.5
		demo_ball.position = Vector3(cos(a) * 5.5, 1.6 + sin(_time * 1.7) * 0.35, sin(a) * 5.5)
	if demo_mesh != null:
		demo_mesh.rotate_x(delta * 3.0)
	if gems != null:
		for g in gems.get_children():
			g.rotate_y(delta * 1.5)
