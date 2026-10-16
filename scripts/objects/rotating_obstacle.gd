extends AnimatableBody3D
## RotatingObstacle - spinning sweeper bar. Tune speed and size in editor.

@export var rotation_speed := 1.6
@export var rotation_axis := Vector3.UP


func _ready() -> void:
	sync_to_physics = true
	if rotation_axis.length() < 0.01:
		rotation_axis = Vector3.UP
	rotation_axis = rotation_axis.normalized()


func _physics_process(delta: float) -> void:
	rotate(rotation_axis, rotation_speed * delta)
