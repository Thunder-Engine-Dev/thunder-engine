@tool
extends Control

@export_group("Music Control")
## Should it automatically change the music index (useful for different level areas)
@export var change_music: bool = false
## Sets the music index
@export var set_music_index: int = 1
## MusicLoader node reference
@export var music_loader_ref: NodePath


func _draw() -> void:
	if !Engine.is_editor_hint(): return
	draw_set_transform(-global_position, rotation, Vector2.ONE)
	draw_rect(get_rect(), Color.AQUA, false, 4)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	var camera = Thunder._current_camera
	var rect = get_rect()
	
	if camera.position > rect.position && camera.position < rect.end:
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
