extends Control
## VirtualJoystick - left-thumb movement stick. Writes directly into the
## ball's input_vector so keyboard and touch can coexist.

@export var radius := 90.0
@export var dead_zone := 0.15

var value := Vector2.ZERO
var _touch_id := -1
var _center := Vector2.ZERO

@onready var base: Control = $Base
@onready var knob: Control = $Base/Knob


func _ready() -> void:
	# Center of the base circle in local coordinates.
	await get_tree().process_frame
	_center = base.size * 0.5


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_update_stick(event.position)
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_update_stick(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_id = -2
			_update_stick(event.position)
		else:
			_touch_id = -1
			_release()
	elif event is InputEventMouseMotion and _touch_id == -2 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_stick(event.position)


func _update_stick(local_pos: Vector2) -> void:
	_center = base.size * 0.5
	var offset := local_pos - base.position - _center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	value = offset / radius
	if value.length() < dead_zone:
		value = Vector2.ZERO
	if knob != null:
		knob.position = _center + offset - knob.size * 0.5
	_push_to_player()


func _release() -> void:
	value = Vector2.ZERO
	if knob != null and base != null:
		knob.position = _center - knob.size * 0.5
	_push_to_player()


func _push_to_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p = players[0]
	# Joystick Y: up on screen = forward (-Z world) = negative y input.
	if "input_vector" in p:
		# Only override when joystick is active; keyboard merges in controller.
		if value.length() > 0.01:
			p.input_vector = value
		else:
			p.input_vector = Vector2.ZERO
