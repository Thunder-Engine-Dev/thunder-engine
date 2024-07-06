extends Control

@export var hide_bg: bool

func _ready() -> void:
	if hide_bg:
		$Bg.queue_free()
