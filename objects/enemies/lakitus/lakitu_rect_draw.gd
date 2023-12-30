@tool
extends Node2D

const Lakitu := preload("res://engine/objects/enemies/lakitus/lakitu.gd")


func _draw() -> void:
	var parent: Lakitu = get_parent()
	if !parent.area_in_local_pos:
		draw_set_transform(-global_position, -global_rotation, Vector2.ONE / global_scale)
	if parent.movement_area && parent.draw_area_rect:
		draw_rect(parent.movement_area, Color(Color.CHOCOLATE, 0.25))


func _process(delta: float) -> void:
	queue_redraw()
