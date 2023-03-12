extends Sprite2D

var velocity: Vector2
var fall_speed: float = 0.4
var rotation_speed: float = 12

func _physics_process(_delta: float) -> void:
	var delta = Thunder.get_delta(_delta)
	
	global_position += velocity * delta
	velocity.y += fall_speed * delta
	rotation_degrees += rotation_speed * delta * (1 if velocity.x > 0 else -1)
	flip_h = velocity.x < 0
