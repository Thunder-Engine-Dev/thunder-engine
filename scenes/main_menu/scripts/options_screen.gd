extends Control

@export var hide_bg: bool
@export var main_menu_controls: String

func _ready() -> void:
	if hide_bg:
		$Bg.queue_free()
