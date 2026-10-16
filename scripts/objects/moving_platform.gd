extends AnimatableBody3D
## MovingPlatform - ping-pong platform along one axis. Predictable, gentle.

@export var move_axis := Vector3(1, 0, 0)
@export var move_distance := 6.0
@export var speed := 2.0
@export var pause_at_ends := 0.4

var _start := Vector3.ZERO
var _t := 0.0
var _pause := 0.0
var _forward := true


func _ready() -> void:
	_start = position
	if move_axis.length() < 0.01:
		move_axis = Vector3.RIGHT
	move_axis = move_axis.normalized()
	sync_to_physics = true


func _physics_process(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		return
	var step := speed * delta / maxf(move_distance, 0.01)
	_t += step if _forward else -step
	if _t >= 1.0:
		_t = 1.0
		_forward = false
		_pause = pause_at_ends
	elif _t <= 0.0:
		_t = 0.0
		_forward = true
		_pause = pause_at_ends
	# Smooth back-and-forth.
	var eased := 0.5 - 0.5 * cos(_t * PI)
	position = _start + move_axis * (eased * move_distance)
