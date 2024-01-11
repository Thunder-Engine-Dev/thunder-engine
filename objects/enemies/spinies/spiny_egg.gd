extends GeneralMovementBody2D

@export var spiny_creation: InstanceNode2D

func _physics_process(delta: float) -> void:
	super(delta)
	get_node(sprite).rotation_degrees += 22.5 * Thunder.get_delta(delta)
	
	if is_on_floor():
		NodeCreator.prepare_ins_2d(spiny_creation, self).create_2d()
		queue_free()
