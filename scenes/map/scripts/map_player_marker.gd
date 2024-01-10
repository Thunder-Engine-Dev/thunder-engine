@tool
class_name MapPlayerMarker extends Marker2D

@export
var level: StringName : set = set_level_path, get = get_level_path

## DO NOT USE OUTSIDE THIS SCRIPT
var _level: StringName

var shape: CollisionShape2D

var last_position: Vector2

@onready var marker_space: MarkerSpace = get_parent()
var player

signal changed

func _enter_tree() -> void:
	if !is_in_group("map_marker"):
		add_to_group("map_marker")
	
	set_notify_transform(true)


func _ready() -> void:
	if Engine.is_editor_hint(): return
	player = Scenes.current_scene.get_node(Scenes.current_scene.player)
	if is_level_completed():
		player.current_marker = self
		player.global_position = global_position


func get_next_marker() -> MapPlayerMarker:
	if marker_space.get_last_marker().get_index() != get_index():
		return marker_space.get_child(get_index() + 1)
	else:
		return Scenes.current_scene.get_child(marker_space.get_index() + 1).get_first_marker()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		changed.emit()

func is_level() -> bool:
	return !_level.is_empty()

func is_level_completed() -> bool:
	return ProfileManager.current_profile.data.has(&"completed_levels") && ProfileManager.current_profile.data[&"completed_levels"].has(level)

func set_level_path(value: StringName) -> void:
	changed.emit()
	_level = value

func get_level_path() -> StringName:
	return _level
