extends Camera2D

var _mouse_input: bool
@onready var selector: MenuSelector = $"../Selector"

## Handles the selection change, used as a signal handler
func handle_selection(item_index: int, item_node: Control, immediate: bool, mouse_input: bool = false) -> void:
	_mouse_input = mouse_input


func _physics_process(delta: float) -> void:
	if !_mouse_input:
		global_position = selector.global_position
	
