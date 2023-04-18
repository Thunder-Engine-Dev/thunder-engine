extends SubViewportContainer

@onready var vp = $SubViewport

func _ready() -> void:
	resized.connect(_on_window_resized)
	_update_sound_function()
	_update_view()


func _on_window_resized():
	_update_view()


func _update_view() -> void:
	if !vp: return
	
	var window_size = DisplayServer.window_get_size()
	scale.x = float(window_size.y) / float(vp.size.y)
	scale.y = float(window_size.y) / float(vp.size.y)
	material.set_shader_parameter(&"enable", scale.y != 1)
	vp.size.x = 480 * (float(window_size.x) / float(window_size.y))
	
	_update_sound_function()


func _update_sound_function() -> void:
	var window_size = DisplayServer.window_get_size()
	Audio._calculate_player_position = func(ref: Node2D) -> Vector2:
		return ref.global_position - Thunder._current_camera.global_position + Vector2(window_size / 2)
