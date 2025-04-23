extends Control

@export var hide_bg: bool
@export var main_menu_controls: String

func _ready() -> void:
	reset_physics_interpolation()
	if hide_bg:
		$Bg.queue_free()
