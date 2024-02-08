extends GeneralMovementBody2D

var rotating_dir: int

func _physics_process(delta: float) -> void:
	super(delta)
	if rotating_dir:
		if sprite_node:
			sprite_node.rotation_degrees += 12 * 50 * rotating_dir * delta
		else:
			for i in get_children():
				if i is AnimatedSprite2D or i is Sprite2D:
					sprite_node = i
					break
	if !Thunder.view.screen_dir(global_position, get_global_gravity_dir(), 512):
		queue_free()
