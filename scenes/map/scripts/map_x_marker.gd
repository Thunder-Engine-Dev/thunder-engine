extends Sprite2D

@onready var posY = position.y
var timer: float = 0

func _physics_process(delta):
	position.y = posY + sin(timer) * 2
	timer = wrapf(timer + 0.25 * Thunder.get_delta(delta), 0, PI * 2)
