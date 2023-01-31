# This class provides helper and utility functions

extends Node

signal stage_changed

var view: View = View.new() # View subsingleton
var gravity_speed: float = 50
var _target_speed: int = 50

var _current_stage: Stage2D: # Reference to the current stage scene
	set(node):
		assert(is_instance_valid(node) || !(node is Stage2D), "Stage2D node is invalid")
		_current_stage = node
		stage_changed.emit()
	get:
		assert(is_instance_valid(_current_stage) || !(_current_stage is Stage2D), "Stage2D node is invalid or not set")
		return _current_stage

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

var _current_player_state: PlayerStateData: # Current state of the player
	set(data):
		_current_player_state = data
		_current_player._on_state_change(data)


func get_or_null(obj: Variant, key: String):
	if !is_instance_valid(obj) || !obj.get(key): return null
	return obj[key]


func get_delta(delta: float) -> float:
	return _target_speed * delta


func _init():
	Engine.physics_ticks_per_second = int(DisplayServer.screen_get_refresh_rate())




class View:
	var border: Rect2i
	var trans: Transform2D
	
	func cam_border(cam: Camera2D) -> void:
		trans = cam.get_viewport_transform()
		border.size = cam.get_viewport_rect().size
		border.position = Vector2i(cam.get_screen_center_position() - border.size/2.0)
	
	func screen_left(pos: Vector2, offset: float) -> bool:
		return (trans * pos).x > -offset
	
	func screen_right(pos: Vector2, offset: float) -> bool:
		return (trans * pos).x < border.size.x + offset
	
	func screen_top(pos: Vector2, offset: float) -> bool:
		return (trans * pos).y > -offset
	
	func screen_bottom(pos: Vector2, offset: float) -> bool:
		return (trans * pos).y > border.size.y + offset
	
	func screen_dir(pos: Vector2, dir: Vector2, offset: float) -> bool:
		var ang: float = dir.angle()
		if ang > 3*PI/4 || ang < -3*PI/4:
			return screen_left(pos, offset)
		elif ang >= -3*PI/4 && ang <= -PI/4:
			return screen_top(pos, offset)
		elif ang > -PI/4 && ang < PI/4:
			return screen_right(pos, offset)
		else:
			return screen_bottom(pos, offset)
