extends Sprite2D

@onready var velocity: float = randf_range(140, 450)

func _physics_process(delta: float) -> void:
	rotation_degrees -= delta * 650
	
	position = position.move_toward(
		position + (Vector2.from_angle(deg_to_rad(randi_range(112.5, 146.25))) * velocity),
		velocity * delta
	)
