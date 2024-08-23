@tool
extends Control

## Enable smooth transition
@export var smooth_transition: bool = false
@export_group("Smooth Options")
@export var smooth_function: Thunder.SmoothFunction = Thunder.SmoothFunction.EASE_OUT
@export var smooth_speed: float = 0.06
@export_group("Music Control")
## Should it automatically change the music index (useful for different level areas)
@export var change_music: bool = false
## Sets the music index
@export var set_music_index: int = 1
## MusicLoader node reference
@export var music_loader_ref: NodePath

signal view_section_changed
signal view_section_changed_with_section(section: Control)

# Switch to prevent transition activating at the beginning
var use_smooth_transition: bool

var transition_camera = preload("res://engine/components/cam_area/transition_camera/transition_camera.tscn")
var is_current: bool

var _det_areas: Array[Control] = []


func _ready() -> void:
	if !child_entered_tree.is_connected(_set_detections):
		child_entered_tree.connect(_set_detections)
	if !child_exiting_tree.is_connected(_remove_detections):
		child_exiting_tree.connect(_remove_detections)
	for i in get_children():
		if i is Control && is_instance_valid(i) && !_det_areas.has(i):
			_det_areas.append(i)
	if Engine.is_editor_hint():
		return
	var player: Player = Thunder._current_player
	if !player: return
	if get_global_rect().abs().has_point(player.global_position) && len(_det_areas) == 0:
		_switch_bounds()


func _draw() -> void:
	if !Engine.is_editor_hint(): return
	draw_set_transform(-global_position, rotation, Vector2.ONE)
	var color = Color.DARK_CYAN if len(_det_areas) > 0 else Color.AQUA
	draw_rect(get_global_rect().abs(), color, false, 4)


func _notification(what):
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		queue_redraw()


func _set_detections(node: Node) -> void:
	if node is Control && !_det_areas.has(node):
		_det_areas.append(node)
		if Engine.is_editor_hint():
			node.set_script(preload("res://engine/components/cam_area/detection_area.gd"))


func _remove_detections(node: Node) -> void:
	if node is Control && _det_areas.has(node):
		_det_areas.erase(node)


func _get_cam_rect(rect: Control) -> Rect2:
	if !is_instance_valid(rect):
		return Rect2()
	return rect.get_global_rect().abs()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	var camera = Thunder._current_camera
	var is_in_bounds: bool
	var has_cam_area: bool = (
		(camera.has_meta(&"cam_area") &&
		camera.get_meta(&"cam_area", null) != self) ||
		!camera.has_meta(&"cam_area")
	)
	var detections: Array = _det_areas if len(_det_areas) > 0 else [self]
	var _int_detections: int = 0
	for i in detections:
		var rect = _get_cam_rect(i)
		
		_int_detections += int(
			has_cam_area &&
			camera.position.x > rect.position.x &&
			camera.position.y > rect.position.y &&
			camera.position.x < rect.end.x &&
			camera.position.y < rect.end.y
		)
	is_in_bounds = bool(_int_detections)
	
	if is_in_bounds:
		if is_current:
			return
		
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, &"#transition_camera", &"_free")
		
		if smooth_transition:
			Thunder.view.cam_border()
			var cams = get_tree().get_nodes_in_group("#transition_camera")
			for i in cams:
				i.queue_free()
			var cam = transition_camera.instantiate() as Camera2D
			cam.limits.position = Vector2i(Thunder.view.border.position.x, Thunder.view.border.position.y)
			cam.limits.end = Vector2i(Thunder.view.border.end.x, Thunder.view.border.end.y)
			cam.function = smooth_function
			cam.speed = smooth_speed
			cam.reset_physics_interpolation()
			add_child(cam)
			Scenes.current_scene.falling_below_y_offset *= 10
		
		_switch_bounds()
	
	if !is_in_bounds && is_current:
		is_current = false


func _switch_bounds() -> void:
	var camera := Thunder._current_camera
	var rect := get_global_rect().abs()
	
	camera.limit_left = round(rect.position.x)
	camera.limit_right = round(rect.end.x)
	camera.limit_top = round(rect.position.y)
	camera.limit_bottom = round(rect.end.y)
	
	if change_music:
		var music_loader = get_node_or_null(music_loader_ref)
		
		if !music_loader:
			printerr("[CamArea] Can't resolve the MusicLoader node")
			return
		
		music_loader.index = set_music_index
	
	view_section_changed.emit()
	view_section_changed_with_section.emit(self)
	
	is_current = true
	
	camera.set_meta(&"cam_area", self)
