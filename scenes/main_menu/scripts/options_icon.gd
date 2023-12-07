extends TextureRect

var posY = position.y
var timer: float = 0

func _physics_process(delta):
	position.y = posY + sin(timer) * 10
	timer += 0.2 * Thunder.get_delta(delta)
