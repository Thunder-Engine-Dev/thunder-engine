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


func _ready() -> void:
	if Engine.is_editor_hint(): return
	var player: Player = Thunder._current_player
	if !player: return
	if get_rect().abs().has_point(player.global_position): _switch_bounds()


func _draw() -> void:
	if !Engine.is_editor_hint(): return
	draw_set_transform(-global_position, rotation, Vector2.ONE)
	draw_rect(get_rect().abs(), Color.AQUA, false, 4)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	var camera = Thunder._current_camera
	var rect = get_rect().abs()
	
	var is_in_bounds: bool = (
		(
			(camera.has_meta(&"cam_area") &&
			camera.get_meta(&"cam_area", null) != self) ||
			!camera.has_meta(&"cam_area")
		) &&
		camera.position.x > rect.position.x &&
		camera.position.y > rect.position.y &&
		camera.position.x < rect.end.x &&
		camera.position.y < rect.end.y
	)
	
	if is_in_bounds:
		if is_current:
			return
		
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, &"#transition_camera", &"_free")
		
		if smooth_transition:
			Thunder.view.cam_border()
			var cam = transition_camera.instantiate() as Camera2D
			cam.limits.position = Vector2i(Thunder.view.border.position.x, Thunder.view.border.position.y)
			cam.limits.end = Vector2i(Thunder.view.border.end.x, Thunder.view.border.end.y)
			cam.function = smooth_function
			cam.speed = smooth_speed
			add_child(cam)
			Scenes.current_scene.falling_below_y_offset *= 10
		
		_switch_bounds()
	
	if !is_in_bounds && is_current:
		is_current = false


func _switch_bounds() -> void:
	var camera := Thunder._current_camera
	var rect := get_rect().abs()
	
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
