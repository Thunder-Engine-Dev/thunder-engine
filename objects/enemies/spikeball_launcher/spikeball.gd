extends GeneralMovementBody2D


func _on_trail() -> void:
	if !sprite_node:
		return
	Trail.trail(self, sprite_node.texture, Vector2.ZERO, sprite_node.flip_h).rotation = sprite_node.rotation
