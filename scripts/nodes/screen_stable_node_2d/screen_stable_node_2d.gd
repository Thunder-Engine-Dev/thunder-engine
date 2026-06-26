extends Node2D
class_name ScreenStableNode2D

const SCREEN_MOVE_THRESHOLD := 1.0
const AXIS_MOVE_EPSILON := 0.01

var _prev_pos: Vector2
var _next_pos: Vector2
var _physics_source: Node2D
var _local_offset: Vector2
var _last_screen_pos: Vector2
var _prev_target_screen: Vector2


func _ready() -> void:
	physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF
	_local_offset = position
	_physics_source = _resolve_physics_source()
	if _physics_source != self:
		top_level = true
	_sync_positions()
	_sync_screen_tracking()


func _resolve_physics_source() -> Node2D:
	var parent := get_parent()
	if parent is Node2D:
		return parent as Node2D
	return self


func _sample_physics_position() -> Vector2:
	var pos := _physics_source.global_position
	if _physics_source != self:
		pos += _physics_source.global_transform.basis_xform(_local_offset)
	return pos


func _sync_positions() -> void:
	var pos := _sample_physics_position()
	_prev_pos = pos
	_next_pos = pos


func _physics_process(_delta: float) -> void:
	_prev_pos = _next_pos
	_next_pos = _sample_physics_position()


func _process(_delta: float) -> void:
	var target_screen := _world_to_screen(_get_target_world_position())
	var screen_pos := _apply_screen_movement_threshold(target_screen)
	_commit_screen_position(screen_pos)
	_prev_target_screen = target_screen


func _get_target_world_position() -> Vector2:
	var frac := Engine.get_physics_interpolation_fraction()
	return _prev_pos.lerp(_next_pos, frac)


func _apply_screen_movement_threshold(target_screen: Vector2) -> Vector2:
	var frame_delta := target_screen - _prev_target_screen
	var moves_x := _axis_has_physics_movement(0)
	var moves_y := _axis_has_physics_movement(1)
	var result := _last_screen_pos
	result.x = _resolve_screen_axis(target_screen.x, result.x, frame_delta.x, moves_x)
	result.y = _resolve_screen_axis(target_screen.y, result.y, frame_delta.y, moves_y)
	return result


func _axis_has_physics_movement(axis: int) -> bool:
	return abs(_next_pos[axis] - _prev_pos[axis]) > AXIS_MOVE_EPSILON


func _resolve_screen_axis(target: float, last: float, frame_delta: float, axis_moves: bool) -> float:
	if !axis_moves:
		return roundf(target)
	if _should_update_screen_axis(target, last, frame_delta):
		return roundf(target)
	return last


func _should_update_screen_axis(target: float, last: float, frame_delta: float) -> bool:
	if abs(target - last) > SCREEN_MOVE_THRESHOLD:
		return true
	return abs(frame_delta) > SCREEN_MOVE_THRESHOLD


func _commit_screen_position(screen_pos: Vector2) -> void:
	_last_screen_pos = screen_pos
	global_position = _screen_to_world(screen_pos)


func _sync_screen_tracking() -> void:
	var target_screen := _world_to_screen(_get_target_world_position())
	_prev_target_screen = target_screen
	_commit_screen_position(target_screen)


func _get_camera() -> Camera2D:
	if is_instance_valid(Thunder._current_camera):
		return Thunder._current_camera
	return get_viewport().get_camera_2d()


func _world_to_screen(world_pos: Vector2) -> Vector2:
	var camera := _get_camera()
	if !is_instance_valid(camera):
		return world_pos
	var half_size := get_viewport().get_visible_rect().size * 0.5
	return (world_pos - camera.get_screen_center_position()) * camera.zoom + half_size


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var camera := _get_camera()
	if !is_instance_valid(camera):
		return screen_pos
	var half_size := get_viewport().get_visible_rect().size * 0.5
	return (screen_pos - half_size) / camera.zoom + camera.get_screen_center_position()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESET_PHYSICS_INTERPOLATION:
		if !_physics_source: return
		_sync_positions()
		_sync_screen_tracking()
