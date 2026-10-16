extends Area3D
## FinishTrigger - golden pad that completes the level.

signal finished

var _done := false

@onready var fountain_a: CPUParticles3D = $FountainA
@onready var fountain_b: CPUParticles3D = $FountainB


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	rotate_y(0.6 * delta)


func _on_body_entered(body: Node3D) -> void:
	if _done:
		return
	if not body.is_in_group("player"):
		return
	_done = true
	if fountain_a != null:
		fountain_a.restart()
	if fountain_b != null:
		fountain_b.restart()
	finished.emit()
	get_tree().call_group("level", "on_finish")
