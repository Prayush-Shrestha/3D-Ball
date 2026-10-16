extends Control
## VirtualJoystick - left-thumb movement stick. Writes into the ball's
## joy_input (falls back to input_vector) so keyboard and touch coexist.
##
## PHONE FIXES:
## - Old version used only _gui_input. The Base/Knob Panels (mouse_filter=STOP)
##   ate the touch, so taps on the visible circle never reached the Joystick
##   and the stick felt dead on phones. This version uses _input with a global
##   rect test, so Base/Knob can never block it (tscn also sets them IGNORE).
## - Old version stopped when the finger slid outside the 200x200 box, leaving
##   the stick stuck. This version keeps tracking the active finger anywhere
##   on screen until release.

@export var radius := 90.0
@export var dead_zone := 0.15
@export var touch_slop := 24.0 # extra grab area for fat fingers (px, canvas)

var value := Vector2.ZERO
var _touch_id := -1
var _mouse_held := false
var _center := Vector2.ZERO

@onready var base: Control = $Base
@onready var knob: Control = $Base/Knob


func _ready() -> void:
	# Center of the base circle in Base-local coordinates.
	await get_tree().process_frame
	if is_instance_valid(base):
		_center = base.size * 0.5
	_reset_knob()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if is_instance_valid(base):
			_center = base.size * 0.5
			_reset_knob()


func _gui_input(event: InputEvent) -> void:
	# Keep mouse support for desktop testing. Touch is handled in _input
	# so Panel children can never eat it.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_held = true
			_update_stick(event.position)
		else:
			_mouse_held = false
			_release()
		accept_event()
	elif event is InputEventMouseMotion and _mouse_held and _touch_id == -1:
		_update_stick(event.position)
		accept_event()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# Ignore touches while paused / level complete (ball frozen anyway).
	if get_tree().paused:
		if event is InputEventScreenTouch and not event.pressed and event.index == _touch_id:
			_touch_id = -1
			_release()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_id == -1 and _touches_stick(event.position):
				_touch_id = event.index
				_update_stick(_to_local(event.position))
				get_viewport().set_input_as_handled()
		else:
			if event.index == _touch_id:
				_touch_id = -1
				_release()
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == _touch_id:
			_update_stick(_to_local(event.position))
			get_viewport().set_input_as_handled()


func _touches_stick(global_pos: Vector2) -> bool:
	var r := get_global_rect().grow(touch_slop)
	return r.has_point(global_pos)


func _to_local(global_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * global_pos


func _update_stick(local_pos: Vector2) -> void:
	if not is_instance_valid(base):
		return
	_center = base.size * 0.5
	# Base center in Joystick-local coords = base.position + base.size/2.
	var base_center_local: Vector2 = base.position + base.size * 0.5
	var offset := local_pos - base_center_local
	if offset.length() > radius:
		offset = offset.normalized() * radius
	value = offset / radius
	if value.length() < dead_zone:
		value = Vector2.ZERO
	if is_instance_valid(knob):
		knob.position = _center + offset - knob.size * 0.5
	_push_to_player()


func _release() -> void:
	value = Vector2.ZERO
	_reset_knob()
	_push_to_player()


func _reset_knob() -> void:
	if is_instance_valid(knob) and is_instance_valid(base):
		_center = base.size * 0.5
		knob.position = _center - knob.size * 0.5


func _push_to_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p = players[0]
	# Joystick Y: up on screen = forward (-Z world) = negative y input.
	# Prefer joy_input (merged in ball_controller); fall back to input_vector
	# for scenes/tests without the new variable.
	if "joy_input" in p:
		p.set("joy_input", value)
		# Keep input_vector in sync for any legacy readers, but let the
		# ball controller do the keyboard-vs-stick arbitration.
		if "input_vector" in p and value.length() < 0.01:
			# Only clear if the ball isn't currently driven by keyboard.
			# The controller clears stale stick values via _joy_active.
			pass
	elif "input_vector" in p:
		if value.length() > 0.01:
			p.set("input_vector", value)
		else:
			p.set("input_vector", Vector2.ZERO)
