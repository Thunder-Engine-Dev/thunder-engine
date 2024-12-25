extends Sprite2D

var _dead: bool
var _dead_speed: Vector2


func fall() -> void:
	_dead = true
	
	var tw = create_tween()
	tw.tween_interval(4.0)
	tw.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	if !_dead: return
	_dead_speed += Vector2.DOWN.rotated(global_rotation) * delta * 500
	position += _dead_speed.rotated(global_rotation) * delta
	
