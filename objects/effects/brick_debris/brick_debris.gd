extends Node2D

@export var velocity: Vector2
@export var fall_speed: float = 0.4
@export var rotation_speed: float = 12


func _ready() -> void:
	var tw: Tween = create_tween()
	tw.tween_interval(6)
	tw.tween_property(self, ^"modulate:a", 0, 0.5)
	await tw.finished
	queue_free()

func _physics_process(_delta: float) -> void:
	var delta = Thunder.get_delta(_delta)
	
	global_position += velocity * delta
	velocity.y += fall_speed * delta
	rotation_degrees += rotation_speed * delta * (1 if velocity.x > 0 else -1)
	
	if get(&"flip_h") is bool:
		set(&"flip_h", velocity.x < 0)
