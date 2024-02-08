extends PointLight2D

@export var final_value: float = 1.0
@export var duration: float = 0.2

func _ready() -> void:
	texture_scale = 0.01
	create_tween().tween_property(self, ^"texture_scale", final_value, duration)
