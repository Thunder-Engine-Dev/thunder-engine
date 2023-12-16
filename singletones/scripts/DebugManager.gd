extends Node

func _input(event: InputEvent) -> void:
	if !event is InputEventKey: return
	if event.echo: return
	if !event.is_pressed(): return
	if event.keycode == KEY_SHIFT:
		pass
