@tool
extends Node2D

const CentipedePathpoints := preload("centipede_pathpoints.gd")


func _draw() -> void:
	if !Engine.is_editor_hint() || !is_node_ready():
		return
	
	draw_set_transform(Vector2.ZERO, -global_rotation, Vector2.ONE / global_scale)
	
	var par := get_parent() as Node2D
	if !par:
		return
	
	var index := get_index()
	if index > 0:
		var previous := par.get_child(index - 1) as Node2D
		if previous && previous.scene_file_path == scene_file_path:
			draw_line(Vector2.ZERO, previous.global_position - global_position, par.path_color, par.path_width)
	if index < par.get_child_count() - 1:
		var next := par.get_child(index + 1) as Node2D
		if next && next.scene_file_path == scene_file_path:
			draw_line(Vector2.ZERO, next.global_position - global_position, par.path_color, par.path_width)

func _process(_delta: float) -> void:
	if !Engine.is_editor_hint():
		return
	queue_redraw()
