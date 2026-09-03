extends Control

@onready var container: SubViewportContainer = $ViewportContainer
@onready var vp: SubViewport = $ViewportContainer/SubViewport
@onready var center_container: AspectRatioContainer = $AspectRatioContainer
@onready var overlay_container: SubViewportContainer = $OverlayLayer/OverlayViewportContainer
@onready var overlay_vp: SubViewport = $OverlayLayer/OverlayViewportContainer/SubViewport

@onready var keep_aspect: bool = ProjectSettings.get("display/window/stretch/aspect") == "keep" 

signal view_updated

func _ready() -> void:
	resized.connect(_on_window_resized)
	#_update_sound_function()
	_update_view()
	


## Fullscreen toggle
func _unhandled_input(event: InputEvent) -> void:
	if !event is InputEventKey or event.echo or !event.is_pressed(): return
	if event.keycode == KEY_F11:
		SettingsManager.settings.fullscreen = !SettingsManager.settings.fullscreen
		SettingsManager._process_settings()


func _on_window_resized():
	_update_view()


func _update_view() -> void:
	if !vp: return
	
	var window_size := DisplayServer.window_get_size()
	if !keep_aspect:
		@warning_ignore("narrowing_conversion")
		vp.size.x = 480 * (float(window_size.x) / float(window_size.y))
	if overlay_vp:
		overlay_vp.size = vp.size
	
	_apply_view_to_container(container, vp, window_size)
	if overlay_container:
		_apply_view_to_container(overlay_container, overlay_vp, window_size)
	
	_update_sound_function()
	view_updated.emit()


func _apply_view_to_container(cont: SubViewportContainer, sub_vp: SubViewport, window_size: Vector2i) -> void:
	var con_scale := Vector2(
		float(window_size.x) / float(sub_vp.size.x),
		float(window_size.y) / float(sub_vp.size.y),
	)
	cont.scale.x = con_scale.y if con_scale.y < con_scale.x else con_scale.x
	cont.scale.y = cont.scale.x
	if cont.material:
		cont.material.set_shader_parameter(
			&"enable",
			!SettingsManager.settings.filter && cont.scale.y != 1
		)
	cont.texture_filter = TEXTURE_FILTER_NEAREST if ((cont.scale.y == 1 || (int(ceil(cont.scale.y)) % 2 == 0 && cont.scale.y >= 2)) && !SettingsManager.settings.filter) else TEXTURE_FILTER_LINEAR
	if keep_aspect:
		cont.position.x = (window_size.x / 2.0) - (sub_vp.size.x * cont.scale.x / 2)
		cont.position.y = (window_size.y / 2.0) - (sub_vp.size.y * cont.scale.y / 2)


func _update_sound_function() -> void:
	var window_size = DisplayServer.window_get_size()
	Audio._calculate_player_position = func(ref: Node2D) -> Vector2:
		var audio_listener: AudioListener2D = vp.get_audio_listener_2d()
		if audio_listener:
			return (
				ref.global_position -
				audio_listener.global_position +
				Vector2(window_size / 2.0)
			)
		return (
			ref.global_position -
			Thunder._current_camera.global_position +
			Vector2(window_size / 2.0)
		)
