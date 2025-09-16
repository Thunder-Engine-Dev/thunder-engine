extends Control

@export var hide_bg: bool

func _ready() -> void:
	reset_physics_interpolation()
	if hide_bg:
		$Bg.queue_free()
