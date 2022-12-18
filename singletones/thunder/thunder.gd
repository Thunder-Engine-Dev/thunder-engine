# This class provides helper and utility functions

extends Node

const DEFAULT_DELTA:float = 0.0001 # Default delta

var _current_frame: Frame: # Reference to the current frame scene
	set(frame):
		assert(is_instance_valid(node) || !(node is Frame), "Frame node is invalid")
		_current_frame = frame
	get:
		assert(is_instance_valid(_current_frame) || !(_current_frame is Frame), "Frame node is invalid or not set")
		return _current_frame
var _current_camera: Camera2D # Reference to the current camera node
var _current_player: Player # Reference to the current player


func get_or_null(obj: Variant, key: String):
	if !is_instance_valid(obj) || !obj.get(key): return null
	return obj[key]


func get_delta(delta: float) -> float:
	return 50 * (delta if delta != 0 else DEFAULT_DELTA)


#func set_current_frame(node: Frame) -> void:
#	assert(is_instance_valid(node) || !(node is Frame), "Frame node is invalid")
#	_current_frame = node


#func get_current_frame() -> Frame:
#	assert(is_instance_valid(_current_frame) || !(_current_frame is Frame), "Frame node is invalid or not set")
#	return _current_frame
