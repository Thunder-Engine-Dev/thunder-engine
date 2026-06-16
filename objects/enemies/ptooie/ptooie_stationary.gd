extends Node2D

@onready var spikeball: GravityBody2D = $Spikeball
@onready var sprite_node: AnimatedSprite2D = $Head

func _ready() -> void:
	spikeball.going_up.connect(func():
		sprite_node.play(&"close")
	)
	spikeball.going_down.connect(func():
		sprite_node.play(&"open")
	)
