extends GeneralMovementBody2D

func _physics_process(delta):
	super(delta)
	delta = Thunder.get_delta(delta)
	
