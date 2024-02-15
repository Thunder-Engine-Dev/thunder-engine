extends GeneralMovementBody2D

var rotating_dir: int

func _physics_process(delta: float) -> void:
	super(delta)
	
	if !sprite_node:
		for i in get_children():
			if i is AnimatedSprite2D or i is Sprite2D:
				sprite_node = i
				break
	
	if sprite_node:
		if rotating_dir:
			sprite_node.rotation_degrees += 12 * 50 * rotating_dir * delta
		else:
			sprite_node.scale.y *= -1
	
	if !Thunder.view.screen_dir(global_position, get_global_gravity_dir(), 512):
		queue_free()
	
	gravity_dir_rotation = false
	gravity_dir = PhysicsServer2D.body_get_direct_state(get_rid()).total_gravity.normalized()
