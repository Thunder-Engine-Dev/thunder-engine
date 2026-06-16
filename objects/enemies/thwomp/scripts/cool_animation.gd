extends Sprite2D


func _physics_process(delta: float) -> void:
	position.y -= 5 * delta * 50
	if position.y < -160:
		position.y = 160
		reset_physics_interpolation()
