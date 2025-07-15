extends Sprite2D

var _dead: bool
var _dead_speed: Vector2

func _ready() -> void:
	$"..".health_changed.connect(_on_health_changed)

func _on_health_changed(to: int) -> void:
	if to > 0: return
	fall()
	reparent(Scenes.current_scene)
	reset_physics_interpolation()
	print("Making Bowser's launcher fall")


func fall() -> void:
	_dead = true
	
	var tw = create_tween()
	tw.tween_interval(4.0)
	tw.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	if !_dead: return
	_dead_speed += Vector2.DOWN * delta * 500
	position += _dead_speed * delta
	
