extends Projectile

const explosion_effect = preload("res://engine/objects/effects/explosion/explosion.tscn")

@export var jumping_speed: float = -250.0


func _physics_process(delta: float) -> void:
	super(delta)
	if !sprite_node: return
	sprite_node.rotation_degrees += 12 * (-1 if speed.x < 0 else 1) * Thunder.get_delta(delta)
	if speed.x == 0: explode()


func jump(jspeed:float = jumping_speed) -> void:
	super(jspeed)


func explode():
	#var effect: Callable = func(eff: Node2D) -> void:
	#	eff.global_transform = global_transform
	
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	queue_free()
