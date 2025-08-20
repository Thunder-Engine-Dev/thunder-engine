extends Node2D

func _physics_process(_delta: float) -> void:
	var node = Thunder._current_player
	if !is_instance_valid(node): return
	global_position = node.global_position.round()
