extends Projectile


func _physics_process(delta: float) -> void:
	super(delta)
	if !sprite_node: return
	sprite_node.rotation_degrees += 24 * (-1 if speed.x < 0 else 1) * Thunder.get_delta(delta)
