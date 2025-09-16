extends ByNodeScript


func _ready() -> void:
	if "life_time" in vars && node is GeneralMovementBody2D:
		node.life_time = vars.life_time
