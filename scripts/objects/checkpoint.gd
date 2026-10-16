extends Area3D
## Checkpoint - activates on touch, stores respawn point, shows green flag.

signal activated(checkpoint: Area3D)

@export var checkpoint_name := "Checkpoint"

var is_active := false

@onready var pole: MeshInstance3D = $Pole
@onready var flag_inactive: MeshInstance3D = $FlagInactive
@onready var flag_active: MeshInstance3D = $FlagActive
@onready var ring: MeshInstance3D = $Base


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_set_visual(false)


func _on_body_entered(body: Node3D) -> void:
	if is_active:
		return
	if not body.is_in_group("player"):
		return
	activate()


func activate(silent := false) -> void:
	is_active = true
	_set_visual(true)
	activated.emit(self)
	get_tree().call_group("level", "on_checkpoint", self)
	if not silent and has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("checkpoint")
	# Deactivate siblings visually so only the latest glows.
	for other in get_tree().get_nodes_in_group("checkpoint"):
		if other != self and other.has_method("set_other_inactive"):
			other.set_other_inactive()


func set_other_inactive() -> void:
	is_active = false
	_set_visual(false)


func _set_visual(active: bool) -> void:
	if flag_active != null:
		flag_active.visible = active
	if flag_inactive != null:
		flag_inactive.visible = not active
	if ring != null:
		var mat := ring.get_surface_override_material(0) as StandardMaterial3D
		if mat != null:
			mat = mat.duplicate()
			mat.emission_enabled = active
			if active:
				mat.emission = Color(0.2, 1.0, 0.5)
				mat.albedo_color = Color(0.2, 0.9, 0.45)
			ring.set_surface_override_material(0, mat)
