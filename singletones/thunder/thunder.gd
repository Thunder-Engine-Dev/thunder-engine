# This class provides helper and utility functions

extends Node

var _current_frame: Frame # Reference to the current frame scene
var _current_camera: Camera2D # Reference to the current camera node
var _current_player: Player # Reference to the current player


func get_or_null(obj: Variant, key: String):
	if !is_instance_valid(obj) || !obj.get(key): return null
	return obj[key]


func get_delta(delta: float) -> float:
	return 50 / (1 / (delta if not delta == 0 else 0.0001))


func set_current_frame(node: Frame) -> void:
	assert(is_instance_valid(node) || !(node is Frame), "Frame node is invalid")
	_current_frame = node


func get_current_frame() -> Frame:
	assert(is_instance_valid(_current_frame) || !(_current_frame is Frame), "Frame node is invalid or not set")
	return _current_frame
