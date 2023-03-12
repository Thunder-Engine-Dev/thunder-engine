extends AnimatedSprite2D

func _ready():
	modulate.v = 1.2
	z_index = 1
	play('default')
	animation_finished.connect(queue_free)
