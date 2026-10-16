extends Area3D
## FinishTrigger - golden pad that completes the level.

signal finished

var _done := false


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
	finished.emit()
	get_tree().call_group("level", "on_finish")
