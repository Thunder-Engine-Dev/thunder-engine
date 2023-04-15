extends ByNodeScript


func _ready() -> void:
	if node is GravityBody2D:
		node.vel_set_y(-640)
