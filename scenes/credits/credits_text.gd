extends Node2D

@export var speed: float = 25

@onready var first_pos: float = position.y
@onready var label_size: Vector2 = get_child(0).size

func _physics_process(delta: float) -> void:
	position.y -= speed * delta
	if position.y < -label_size.y:
		position.y = first_pos
