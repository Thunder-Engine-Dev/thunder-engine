@tool
extends Node2D

const Lakitu := preload("res://engine/objects/enemies/spike_ceiling/spike_ceiling.gd")


func _draw() -> void:
	if !Engine.is_editor_hint():
		return
	var parent: Lakitu = get_parent()
	draw_set_transform(-global_position, -global_rotation, Vector2.ONE / global_scale)
	if parent.activated_area && parent.draw_area_rect:
		draw_rect(parent.activated_area, Color(Color.STEEL_BLUE, 0.25), false, 8)


func _process(delta: float) -> void:
	queue_redraw()
