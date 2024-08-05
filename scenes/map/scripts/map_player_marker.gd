@icon("../textures/icons/branch.svg")
@tool
class_name MapPlayerMarker extends Marker2D

@export_file("*.tscn", "*.scn") var level: String: 
	set = set_level_path, get = get_level_path
@export_file("*.tscn", "*.scn") var level_override_save: String = "":
	set = set_level_save_path

@export var music_loader_ref: NodePath
@export var change_music_index: int = 0

# DO NOT USE OUTSIDE THIS SCRIPT
var _level: String
var _level_save: String = ""

@onready var marker_space: MarkerSpace = get_parent()
var player

signal changed
signal current_active

func _enter_tree() -> void:
	if !is_in_group("map_marker"):
		add_to_group("map_marker")
	
	if !Engine.is_editor_hint(): return
	set_notify_transform(true)


func _ready() -> void:
	if Engine.is_editor_hint(): return
	player = Scenes.current_scene.get_node(Scenes.current_scene.player)
	
	if (
		is_level_completed() && !Data.values.get('map_force_selected_marker') ||
		Data.values.get('map_force_selected_marker') == _level_save
	):
		#await get_tree().process_frame
		(func():
			#Data.values.erase('map_force_selected_marker')
			player.current_marker = get_next_marker()
			#print(marker_space.get_next_marker_id())
			player.global_position = global_position
			
			current_active.emit()
			
			var loader = get_node_or_null(music_loader_ref)
			if is_instance_valid(loader):
				loader.set_index.call_deferred(change_music_index)
			
			if is_instance_valid(player.camera):
				player.camera.reset_smoothing.call_deferred()
			
			marker_space.make_dots_visible_before(self)
			marker_space.add_uncompleted_levels_after(_level_save)
			Scenes.current_scene.next_level_ready.emit(
				marker_space.total_levels.size() - marker_space.uncompleted_levels.size()
			)
		).call_deferred()
	elif is_level():
		#await get_tree().process_frame
		(func():
			if marker_space.uncompleted_levels.is_empty():
				marker_space.add_all_uncompleted_levels()
		).call_deferred()


func get_next_marker() -> MapPlayerMarker:
	if marker_space.get_last_marker().get_index() != get_index():
		return marker_space.get_child(get_index() + 1)
	else:
		return Scenes.current_scene.get_child(marker_space.get_index() + 1).get_first_marker()


func _notification(what: int) -> void:
	if !Engine.is_editor_hint(): return
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		changed.emit()

func is_level() -> bool:
	return !_level.is_empty()

func is_level_completed() -> bool:
	return (
		ProfileManager.current_profile.data.has(&"completed_levels") &&
		ProfileManager.current_profile.data[&"completed_levels"].has(_level_save)
	)

func set_level_path(value: String) -> void:
	changed.emit()
	_level = value
	_level_save = value
	level = value

func get_level_path() -> String:
	return _level

func set_level_save_path(value: String) -> void:
	_level_save = value
	level_override_save = value

