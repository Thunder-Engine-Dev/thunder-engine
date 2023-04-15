extends GeneralMovementBody2D


func _physics_process(delta: float) -> void:
	super(delta)
	if !Thunder.view.screen_dir(global_position, get_global_gravity_dir(), 512):
		queue_free()
