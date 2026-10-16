extends Area3D
## Collectible - spinning golden gem. Counts once, plays sparkle + sound,
## notifies the level through the "collectible_collected" group call.

signal collected(collectible: Area3D)

@export var gem_id := ""
@export var bob_height := 0.25
@export var spin_speed := 2.5

var _taken := false
var _start_y := 0.0
var _time := 0.0

@onready var gem_mesh: MeshInstance3D = $GemMesh
@onready var sparkle: CPUParticles3D = $Sparkle


func _ready() -> void:
	_start_y = position.y
	_time = randf() * TAU
	body_entered.connect(_on_body_entered)
	if gem_id.is_empty():
		gem_id = "%s_%d" % [get_parent().name, get_index()]


func _process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	rotate_y(spin_speed * delta)
	position.y = _start_y + sin(_time * 2.0) * bob_height


func _on_body_entered(body: Node3D) -> void:
	if _taken:
		return
	if not body.is_in_group("player"):
		return
	_taken = true
	collected.emit(self)
	get_tree().call_group("level", "on_collectible", self)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("collect")
	if gem_mesh != null:
		gem_mesh.visible = false
	if sparkle != null:
		sparkle.emitting = true
	set_deferred("monitoring", false)
	await get_tree().create_timer(0.6).timeout
	queue_free()
