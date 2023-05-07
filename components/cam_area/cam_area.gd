@tool
extends Control

## Enable smooth transition
@export var smooth_transition: bool = false
@export_group("Music Control")
## Should it automatically change the music index (useful for different level areas)
@export var change_music: bool = false
## Sets the music index
@export var set_music_index: int = 1
## MusicLoader node reference
@export var music_loader_ref: NodePath


var transition_camera = preload("res://engine/components/cam_area/transition_camera/transition_camera.tscn")
var is_current: bool = false

func _draw() -> void:
	if !Engine.is_editor_hint(): return
	draw_set_transform(-global_position, rotation, Vector2.ONE)
	draw_rect(get_rect(), Color.AQUA, false, 4)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	var camera = Thunder._current_camera
	var rect = get_rect()
	
	var is_in_bounds: bool = (
		camera.position.x > rect.position.x &&
		camera.position.y > rect.position.y &&
		camera.position.x < rect.end.x &&
		camera.position.y < rect.end.y
	)
	
	if is_in_bounds:
		if is_current: return
		is_current = true
		
		if smooth_transition:
			var cam = transition_camera.instantiate() as Camera2D
			cam.global_position = Thunder._current_camera.global_position
			cam.limit_top = camera.limit_top
			cam.limit_left = camera.limit_left
			cam.limit_right = camera.limit_right
			cam.limit_bottom = camera.limit_bottom
			add_child(cam)
		
		camera.limit_top = rect.position.y
		camera.limit_left = rect.position.x
		camera.limit_right = rect.end.x
		camera.limit_bottom = rect.end.y
		
		
		if change_music:
			var music_loader = get_node_or_null(music_loader_ref)
			
			if !music_loader:
				printerr("[CamArea] Can't resolve the MusicLoader node")
				return
			
			music_loader.index = set_music_index
	
	if !is_in_bounds && is_current:
		is_current = false
