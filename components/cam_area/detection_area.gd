@tool
extends Control

func _draw():
	if !Engine.is_editor_hint(): return
	draw_set_transform(-global_position, rotation, Vector2.ONE)
	draw_rect(get_global_rect().abs(), Color.MAGENTA, false, 4)
