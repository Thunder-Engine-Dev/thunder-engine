extends StateManager
class_name PlayerStateManager

var jump_buffer: bool = false
var dir: int = 1

func _init() -> void:
	add_states([
		"duck",
		"stuck",
		"dead",
		"static"
	])


func update_states() -> void:
	pass
