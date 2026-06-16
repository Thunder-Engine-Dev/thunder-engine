extends "res://engine/scripts/nodes/general_movement/circle_movement.gd"

func _ready() -> void:
	$AnimatedSprite2D.play(str(randi_range(0, 2)))
