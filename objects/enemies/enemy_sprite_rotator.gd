extends Node2D

@export_range(-21599.94, 21599.94, 0.001, "suffix:°/s") var rotation_speed: float


func _physics_process(delta: float) -> void:
	rotate(deg_to_rad(rotation_speed) * delta)
