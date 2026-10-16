extends Area3D
## Hazard - red danger zone (lava / spikes). Respawns player at checkpoint.

@export var respawn_delay := 0.1

var _cooling := false
var _base_scale := Vector3.ONE


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_base_scale = scale


func _process(_delta: float) -> void:
	# Gentle pulse so hazards read as dangerous (preserves editor scale).
	var s := 1.0 + sin(Time.get_ticks_msec() / 300.0) * 0.02
	scale = Vector3(_base_scale.x * s, _base_scale.y, _base_scale.z * s)


func _on_body_entered(body: Node3D) -> void:
	if _cooling:
		return
	if not body.is_in_group("player"):
		return
	_cooling = true
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("hurt")
	get_tree().call_group("level", "on_hazard")
	await get_tree().create_timer(respawn_delay + 0.4).timeout
	_cooling = false
