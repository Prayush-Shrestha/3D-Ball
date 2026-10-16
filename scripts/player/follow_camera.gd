extends Node3D
## FollowCamera - third-person orbit camera rig (child of the ball).
## Mouse moves orbit yaw/pitch on PC. Touch drag on the right half of the
## screen orbits without fighting the left-side movement joystick.

@export var distance := 8.5
@export var lift := 1.6
@export var min_pitch := -0.9
@export var max_pitch := 0.55

var yaw := 0.0
var pitch := -0.38
var _dragging := false
var _last_touch := Vector2.ZERO

@onready var arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	_apply_shape()
	_update_transform(1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := 0.0025 * _sensitivity()
		yaw -= event.relative.x * sens
		pitch = clampf(pitch - event.relative.y * sens, min_pitch, max_pitch)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		var sens2 := 0.004 * _sensitivity()
		yaw -= event.relative.x * sens2
		pitch = clampf(pitch - event.relative.y * sens2, min_pitch, max_pitch)
	elif event is InputEventScreenTouch:
		_dragging = event.pressed
		_last_touch = event.position
	elif event is InputEventScreenDrag and _dragging:
		# Only orbit with drags starting on the right half (joystick is left).
		if _last_touch.x > get_viewport().get_visible_rect().size.x * 0.4:
			var sens3 := 0.006 * _sensitivity()
			yaw -= event.relative.x * sens3
			pitch = clampf(pitch - event.relative.y * sens3, min_pitch, max_pitch)
		_last_touch = event.position


func _process(delta: float) -> void:
	_update_transform(delta)


func _sensitivity() -> float:
	if has_node("/root/SaveManager"):
		return get_node("/root/SaveManager").camera_sensitivity
	return 1.0


func _apply_shape() -> void:
	if arm != null:
		arm.spring_length = distance
		arm.position = Vector3(0, lift, 0)
		arm.margin = 0.3


func _update_transform(_delta: float) -> void:
	# Only rotate the pivot: the SpringArm positions the camera by itself.
	rotation.y = yaw
	rotation.x = pitch


func snap_to_target() -> void:
	_update_transform(1.0)
