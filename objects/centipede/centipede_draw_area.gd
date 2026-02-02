@tool
extends Node2D

func _process(delta: float) -> void:
	if !Engine.is_editor_hint():
		return
	queue_redraw()

func _draw() -> void:
	var par = $".."
	if !Engine.is_editor_hint(): return
	if !par.get(&"trigger_area_draw_enabled") || par.trigger_type != 0: return
	var trigger_area: Rect2 = $"..".trigger_area
	draw_set_transform(-global_position, -global_rotation, Vector2.ONE / global_scale)
	draw_rect(
		Rect2(global_position + trigger_area.position - trigger_area.size / 2, trigger_area.size),
		Color(Color.BLUE, 0.25), false, 2
	)
