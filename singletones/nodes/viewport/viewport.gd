extends Control

@onready var container = $ViewportContainer
@onready var vp = $ViewportContainer/SubViewport

@onready var keep_aspect = ProjectSettings.get("display/window/stretch/aspect") == "keep" 

func _ready() -> void:
	#vp.audio_listener_enable_2d = true
	#vp.audio_listener_enable_3d = true
	resized.connect(_on_window_resized)
	#_update_sound_function()
	_update_view()


## Fullscreen toggle
func _unhandled_input(event: InputEvent) -> void:
	if !event is InputEventKey or event.echo or !event.is_pressed(): return
	if event.keycode == KEY_F11:
		if DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			SettingsManager._window_scale_logic()
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func _on_window_resized():
	_update_view()


func _update_view() -> void:
	if !vp: return
	
	var window_size = DisplayServer.window_get_size()
	var con_scale = Vector2(
		float(window_size.x) / float(vp.size.x),
		float(window_size.y) / float(vp.size.y),
	)
	container.scale.x = con_scale.y if con_scale.y < con_scale.x else con_scale.x
	container.scale.y = container.scale.x
	container.material.set_shader_parameter(
		&"enable",
		!SettingsManager.settings.filter && container.scale.y != 1
	)
	container.texture_filter = TEXTURE_FILTER_NEAREST if ((container.scale.y == 1 || (int(ceil(container.scale.y)) % 2 == 0 && container.scale.y >= 2)) && !SettingsManager.settings.filter) else TEXTURE_FILTER_LINEAR
	if !keep_aspect:
		vp.size.x = 480 * (float(window_size.x) / float(window_size.y))
	else:
		container.position.x = (window_size.x / 2) - (vp.size.x * container.scale.x / 2)
		container.position.y = (window_size.y / 2) - (vp.size.y * container.scale.y / 2)
	
	_update_sound_function()


func _update_sound_function() -> void:
	var window_size = DisplayServer.window_get_size()
	Audio._calculate_player_position = func(ref: Node2D) -> Vector2:
		return (
			ref.global_position -
			Thunder._current_camera.global_position +
			Vector2(window_size / 2)
		)
