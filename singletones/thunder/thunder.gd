# This class provides helper and utility functions

extends Node

var _current_frame: Frame: # Reference to the current frame scene
	set(node):
		assert(is_instance_valid(node) || !(node is Frame), "Frame node is invalid")
		_current_frame = node
	get:
		assert(is_instance_valid(_current_frame) || !(_current_frame is Frame), "Frame node is invalid or not set")
		return _current_frame

var _current_camera: Camera2D: # Reference to the current camera node
	set(node):
		assert(is_instance_valid(node) || !(node is Camera2D), "Camera node is invalid")
		_current_camera = node
	get:
		assert(is_instance_valid(_current_camera) || !(_current_camera is Camera2D), "Camera node is invalid or not set")
		return _current_camera

var _current_player: Player: # Reference to the current player
	set(node):
		assert(is_instance_valid(node) || !(node is Player), "Player node is invalid")
		_current_player = node
	get:
		assert(is_instance_valid(_current_player) || !(_current_player is Player), "Player node is invalid or not set")
		return _current_player


func get_or_null(obj: Variant, key: String):
	if !is_instance_valid(obj) || !obj.get(key): return null
	return obj[key]


func get_delta(delta: float) -> float:
	return 50 * delta
