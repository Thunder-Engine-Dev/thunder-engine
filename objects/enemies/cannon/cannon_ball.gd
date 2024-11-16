extends Node2D

@export_category("Cannon Ball")
@export_custom(PROPERTY_HINT_NONE, "suffix:px/s") var velocity: Vector2


func _physics_process(delta: float) -> void:
	global_position += velocity * delta
