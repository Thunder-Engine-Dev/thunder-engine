extends Control

@onready var music_loader: Node = $MusicLoader

var _original_time_scale: float

func _ready() -> void:
	_original_time_scale = Engine.time_scale
	Engine.time_scale = 1
	
	await get_tree().process_frame
	music_loader.play_buffered.call_deferred()


var is_exiting: bool = false
func scene_exit() -> void:
	if is_exiting: return
	is_exiting = true
	Engine.time_scale = _original_time_scale
	if music_loader.channel_id in Audio._music_channels && is_instance_valid(Audio._music_channels[music_loader.channel_id]):
		Audio.stop_music_channel(music_loader.channel_id, false)
	if Scenes.current_scene == self:
		Scenes.goto_scene(ProjectSettings.get_setting("application/thunder_settings/main_menu_path"))
	else:
		queue_free()

func _input(event: InputEvent) -> void:
	if _are_actions_pressed(event, [&"m_jump", &"ui_cancel", &"ui_accept"]):
		scene_exit()

func _are_actions_pressed(event: InputEvent, actions: Array[StringName]) -> bool:
	var is_pressed: bool
	for i in actions:
		if event.is_action_pressed(i):
			is_pressed = true
	return is_pressed
