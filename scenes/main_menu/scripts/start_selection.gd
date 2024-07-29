extends MenuSelection

#const MENU_MOUSE_AREA = preload("res://engine/components/ui/generic/menu_mouse_area.tscn")
#var mouse_inside: bool

var starting: bool = false
@export var wait_time: float = 2.5
@export var transition_sound: AudioStream = preload("res://engine/components/ui/_sounds/fadeout.wav")


#func _ready() -> void:
	#var area = MENU_MOUSE_AREA.instantiate()
	#add_child(area)
	#area.get_child(0).shape.size = size
	#area.mouse_entered.connect(func():
		#mouse_inside = true
	#)
	#area.mouse_exited.connect(func():
		#mouse_inside = false
	#)

func _handle_select() -> void:
	if starting: return
	super()
	starting = true
	get_parent().focused = false

	var music = Audio._music_channels[0]
	Audio.fade_music_1d_player(music, -60, 2.8, Tween.TRANS_LINEAR, true)
	
	await get_tree().create_timer(wait_time).timeout
	
	if is_instance_valid(music): music.stop()
	Audio.play_1d_sound(transition_sound, true, { ignore_pause = true })
	var sgr_path = ProjectSettings.get_setting("application/thunder_settings/save_game_room_path")
	
	if SettingsManager.get_tweak("replace_circle_transitions_with_fades", false):
		TransitionManager.accept_transition(
			load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
				.instantiate()
				.with_scene(sgr_path)
		)
		return
	
	TransitionManager.accept_transition(
		load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
			.instantiate()
			.with_speeds(0.015, -0.1)
	)
	
	TransitionManager.transition_middle.connect(func():
		TransitionManager.current_transition.paused = true
		Scenes.goto_scene(sgr_path)
		Scenes.scene_changed.connect(func(_current_scene):
			TransitionManager.current_transition.on(Thunder._current_player)
			TransitionManager.current_transition.paused = false
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)
