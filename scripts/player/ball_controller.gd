extends CharacterBody3D
## BallController - predictable CharacterBody3D rolling ball.
## World-aligned + camera-relative movement, coyote time, jump buffering,
## visual rolling (mesh only, body stays upright so child camera is stable).

signal jumped
signal landed

@export var move_speed := 9.0
@export var acceleration := 40.0
@export var air_control := 0.55
@export var friction := 32.0
@export var jump_velocity := 8.5
@export var gravity_scale := 1.0
@export var coyote_time := 0.12
@export var jump_buffer := 0.15
@export var max_fall_speed := 30.0
@export var ball_radius := 0.5

var input_vector := Vector2.ZERO   # set by keyboard OR virtual joystick
var jump_held := false
var external_jump_request := false # set by touch jump button
var frozen := false                # true while paused / level complete
var was_on_floor := true

var _coyote := 0.0
var _buffer := 0.0
var _base_gravity: float
var _squash_tween: Tween = null
var _audio = null

@onready var mesh: MeshInstance3D = $BallMesh
@onready var cam_pivot: Node3D = $CamPivot
@onready var trail: CPUParticles3D = $Trail
@onready var dust: CPUParticles3D = $LandDust


func _ready() -> void:
	_base_gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 20.0)
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(50.0)
	floor_block_on_wall = true
	_audio = get_node_or_null("/root/AudioManager")
	landed.connect(_on_landed)


func _physics_process(delta: float) -> void:
	if frozen:
		if _audio != null:
			_audio.set_rolling(0.0)
		if trail != null:
			trail.emitting = false
		return
	_read_keyboard()
	var wish_dir := _wish_direction()

	if is_on_floor():
		if not was_on_floor:
			landed.emit()
		_coyote = coyote_time
	else:
		_coyote -= delta
	was_on_floor = is_on_floor()

	_buffer -= delta
	if Input.is_action_just_pressed("jump") or external_jump_request:
		_buffer = jump_buffer
	external_jump_request = false

	# Horizontal movement.
	var control := 1.0 if is_on_floor() else air_control
	var target := wish_dir * move_speed
	var rate := (acceleration if wish_dir.length() > 0.05 else friction) * control
	velocity.x = move_toward(velocity.x, target.x, rate * delta)
	velocity.z = move_toward(velocity.z, target.z, rate * delta)

	# Gravity + jump.
	var gravity := _base_gravity * gravity_scale
	if not is_on_floor():
		velocity.y = maxf(velocity.y - gravity * delta, -max_fall_speed)
	elif velocity.y < 0.0:
		velocity.y = -0.5  # stick to ground, avoids bouncing on slopes

	if _buffer > 0.0 and _coyote > 0.0:
		_do_jump()

	move_and_slide()
	_roll_mesh(delta)
	_update_feel()


func _update_feel() -> void:
	# Trail puffs + rolling sound follow ground speed (mesh-only effects).
	var planar := Vector2(velocity.x, velocity.z).length()
	var grounded := is_on_floor()
	if trail != null:
		trail.emitting = grounded and planar > 1.5
	if _audio != null:
		if grounded:
			_audio.set_rolling(clampf(planar / maxf(move_speed, 0.1), 0.0, 1.0))
		else:
			_audio.set_rolling(0.0)


func _on_landed() -> void:
	if dust != null:
		dust.restart()
	_pop_mesh(Vector3(1.25, 0.7, 1.25))


func _pop_mesh(squash: Vector3) -> void:
	if mesh == null:
		return
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	mesh.scale = squash
	_squash_tween = create_tween()
	_squash_tween.tween_property(mesh, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _read_keyboard() -> void:
	# Keyboard merges with joystick: joystick writes input_vector every frame,
	# keyboard adds on top so both can coexist.
	var kb := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if kb.length() > 0.05:
		input_vector = kb


func _wish_direction() -> Vector3:
	if input_vector.length() < 0.05:
		return Vector3.ZERO
	# Camera-relative: forward follows camera yaw.
	var yaw := 0.0
	if is_instance_valid(cam_pivot):
		yaw = cam_pivot.rotation.y
	var dir := Vector3(input_vector.x, 0.0, input_vector.y)
	dir = dir.rotated(Vector3.UP, yaw)
	# input_vector.y is +1 when pressing back; forward (-Z) needs -Y mapping.
	# Input.get_vector already returns y negative for forward, so use directly.
	if dir.length() > 1.0:
		dir = dir.normalized()
	return dir


func _do_jump() -> void:
	_buffer = 0.0
	_coyote = 0.0
	velocity.y = jump_velocity
	_pop_mesh(Vector3(0.85, 1.2, 0.85))
	jumped.emit()


func _roll_mesh(delta: float) -> void:
	if mesh == null:
		return
	var planar := Vector3(velocity.x, 0.0, velocity.z)
	var speed := planar.length()
	if speed > 0.1 and ball_radius > 0.01:
		var axis := Vector3.UP.cross(planar).normalized()
		var angle := speed * delta / ball_radius
		mesh.rotate(axis.normalized(), angle)


func respawn_at(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_coyote = 0.0
	_buffer = 0.0
	was_on_floor = false
	if is_instance_valid(cam_pivot) and cam_pivot.has_method("snap_to_target"):
		cam_pivot.snap_to_target()


func set_frozen(value: bool) -> void:
	frozen = value
	if frozen:
		velocity = Vector3.ZERO
