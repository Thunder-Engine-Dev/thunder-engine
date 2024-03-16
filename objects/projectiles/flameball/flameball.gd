extends Projectile

const explosion_effect = preload("res://engine/objects/effects/explosion/explosion.tscn")

func _physics_process(delta: float) -> void:
	super(delta)
	if !sprite_node: return
	sprite_node.rotation_degrees += 24 * (-1 if speed.x < 0 else 1) * Thunder.get_delta(delta)


func explode():
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	queue_free()
