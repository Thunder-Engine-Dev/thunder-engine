extends GeneralMovementBody2D

func set_self_modulate_back() -> void:
	await get_tree().physics_frame
	if is_instance_valid(sprite_node):
		sprite_node.self_modulate.a = 1.0
