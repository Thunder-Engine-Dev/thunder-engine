extends MenuSelection

var starting: bool = false
@export var wait_time: float = 2.5
@export var transition_sound: AudioStream = preload("res://engine/components/ui/_sounds/fadeout.wav")

func _handle_select() -> void:
	if starting: return
	super()
	starting = true
	get_parent().focused = false
	Audio.fade_music_1d_player(Audio._music_channels[0], -1000, 0.15)
	
	await get_tree().create_timer(wait_time).timeout
	
	Audio._music_channels[0].stop()
	
	TransitionManager.accept_transition(
		load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
			.instantiate()
			.with_speeds(0.015, -0.05)
	)
	
	Audio.play_1d_sound(transition_sound)
	
	var sgr_path = ProjectSettings.get_setting("application/thunder_settings/save_game_room_path")
	TransitionManager.transition_middle.connect(func():
		Scenes.goto_scene(sgr_path)
		TransitionManager.current_transition.paused = true
		Scenes.scene_changed.connect(func():
			TransitionManager.current_transition.on(Thunder._current_player)
			TransitionManager.current_transition.paused = false
		, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT
	)
