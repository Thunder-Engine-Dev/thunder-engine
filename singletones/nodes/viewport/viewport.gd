extends Control

@onready var container = $ViewportContainer
@onready var vp = $ViewportContainer/SubViewport

@onready var keep_aspect = ProjectSettings.get("display/window/stretch/aspect") == "keep" 

func _ready() -> void:
	resized.connect(_on_window_resized)
	_update_sound_function()
	_update_view()


func _on_window_resized():
	_update_view()


func _update_view() -> void:
	if !vp: return
	
	var window_size = DisplayServer.window_get_size()
	container.scale.x = float(window_size.y) / float(vp.size.y)
	container.scale.y = float(window_size.y) / float(vp.size.y)
	container.material.set_shader_parameter(&"enable", container.scale.y != 1)
	if !keep_aspect:
		vp.size.x = 480 * (float(window_size.x) / float(window_size.y))
	else:
		container.position.x = (window_size.x / 2) - (vp.size.x * container.scale.x / 2)
	
	_update_sound_function()


func _update_sound_function() -> void:
	var window_size = DisplayServer.window_get_size()
	Audio._calculate_player_position = func(ref: Node2D) -> Vector2:
		return ref.global_position - Thunder._current_camera.global_position + Vector2(window_size / 2)
