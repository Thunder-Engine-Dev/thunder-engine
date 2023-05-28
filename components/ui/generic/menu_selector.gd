@icon("res://engine/components/ui/generic/textures/icon_selector.png")
extends Node2D
class_name MenuSelector
## The selection indicator helper script

enum POSITION_SIDE {
	TOP,
	RIGHT,
	BOTTOM,
	LEFT
}

## Selector's current target position
var target_position: Vector2 = Vector2.ZERO
## Whether to use a smooth transition between positions using interpolation
@export var smooth_transition: bool = true
## Speed of smooth transition
@export var smooth_speed: float = 0.2
## Stick the selector to the specified side of selection
@export var position_side: POSITION_SIDE = POSITION_SIDE.LEFT
## Position side padding
@export var position_padding: int = 0
## Position side padding array (works per item and adds to the global padding value)
@export var position_paddings_array: Array[float] = []

var _current_item_index: int = -1
var _current_item_node: Control = null
var _immediate: bool

## Handles the selection change, used as a signal handler
func handle_selection(item_index: int, item_node: Control, immediate: bool) -> void:
	_current_item_index = item_index
	_current_item_node = item_node
	_immediate = immediate


func _update_pos() -> void:
	match position_side:
		POSITION_SIDE.LEFT:
			target_position = _current_item_node.global_position
			target_position.y += _current_item_node.get_rect().size.y / 2
			target_position.x -= position_padding
			if len(position_paddings_array) > _current_item_index:
				target_position.x -= position_paddings_array[_current_item_index]
		POSITION_SIDE.RIGHT:
			target_position = _current_item_node.global_position
			target_position.y += _current_item_node.get_rect().size.y / 2
			target_position.x += position_padding + _current_item_node.get_rect().size.x
			if len(position_paddings_array) > _current_item_index:
				target_position.x += position_paddings_array[_current_item_index]
		POSITION_SIDE.TOP:
			target_position = _current_item_node.global_position
			target_position.x += _current_item_node.get_rect().size.x / 2
			target_position.y += position_padding
			if len(position_paddings_array) > _current_item_index:
				target_position.y += position_paddings_array[_current_item_index]
		POSITION_SIDE.BOTTOM:
			target_position = _current_item_node.global_position
			target_position.x += _current_item_node.get_rect().size.x / 2
			target_position.y += position_padding + _current_item_node.get_rect().size.y
			if len(position_paddings_array) >= _current_item_index:
				target_position.y += position_paddings_array[_current_item_index]
	
	if _immediate:
		global_position = target_position


func _physics_process(delta: float) -> void:
	if smooth_transition:
		global_position = global_position.lerp(target_position, smooth_speed * Thunder.get_delta(delta))
	else:
		global_position = target_position
	
	if is_instance_valid(_current_item_node):
		_update_pos()
