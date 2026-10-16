class_name UISound
extends RefCounted
## UISound - one-line UI click sounds. Call UISound.hookup(self) at the end
## of any menu/HUD _ready() and every Button inside plays the click sound.
## Already-connected buttons are skipped via metadata, so double hookups
## (e.g. embedded + standalone scenes) are harmless.


static func hookup(root: Node, exclude: Array = []) -> void:
	_hook_recursive(root, exclude)


static func _hook_recursive(n: Node, exclude: Array) -> void:
	if n is Button:
		if not exclude.has(n) and not n.has_meta("uisound_hooked"):
			n.set_meta("uisound_hooked", true)
			n.pressed.connect(_play_click.bind(n))
	for c in n.get_children():
		_hook_recursive(c, exclude)


static func _play_click(btn: Button) -> void:
	var am = btn.get_node_or_null("/root/AudioManager")
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("click")
