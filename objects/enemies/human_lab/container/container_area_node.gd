extends Node

const BUBBLES = preload("res://engine/objects/enemies/human_lab/container/sfx/bubbles.ogg")
@onready var area: Area2D = $".."
var delay: float = 1.9

func _physics_process(delta: float) -> void:
	delay += delta / max(0.01, Engine.time_scale)
	
	if area.player != null && delay > 2.0:
		Audio.play_1d_sound(BUBBLES)
		delay = 0
	
