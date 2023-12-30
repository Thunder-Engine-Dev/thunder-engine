@icon("res://engine/scenes/map/textures/icons/marker.svg")
@tool
class_name MapMarker extends Marker2D

@export
var level: StringName : set = set_level_path, get = get_level_path

## DO NOT USE OUTSIDE THIS SCRIPT
var _level: StringName

var shape: CollisionShape2D

var last_position: Vector2

signal changed

func _enter_tree() -> void:
	if !is_in_group("map_branch"):
		add_to_group("map_branch")
	
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		changed.emit()

func is_level() -> bool:
	return !_level.is_empty()

func is_level_completed() -> bool:
	return false


func set_level_path(value: StringName) -> void:
	changed.emit()
	_level = value

func get_level_path() -> StringName:
	return _level
