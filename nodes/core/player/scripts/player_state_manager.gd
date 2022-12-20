extends StateManager
class_name PlayerStatesManager

var jump_buffer: bool = false
var left_or_right:int
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
