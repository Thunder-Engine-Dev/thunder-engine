extends MenuSelection

var starting: bool = false
@export var wait_time: float = 2.4
@export var transition_sound: AudioStream = preload("res://engine/components/ui/_sounds/fadeout.wav")


func _handle_select(mouse_input: bool = false) -> void:
	if starting: return
	super(mouse_input)
	starting = true
	get_parent().focused = false

	var music: AudioStreamPlayer
	if 0 in Audio._music_channels:
		music = Audio._music_channels[0]
	Audio.fade_music_1d_player(music, -60, 2.8, Tween.TRANS_LINEAR, true)

	await get_tree().create_timer(wait_time, true, false, true).timeout

	if is_instance_valid(music): music.stop()
	var _sfx = CharacterManager.get_sound_replace(transition_sound, transition_sound, "menu_fade_out", false)
	Audio.play_1d_sound(_sfx, true, { "ignore_pause": true, "bus": "1D Sound" })
	var sgr_path = ProjectSettings.get_setting("application/thunder_settings/save_game_room_path")
	Data.technical_values.impulse_progress_continue = true

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
			.with_speeds(0.02, -0.1)
	)

	TransitionManager.transition_middle.connect(func():
		TransitionManager.current_transition.paused = true
		Scenes.goto_scene(sgr_path)
		Scenes.scene_changed.connect(func(_current_scene):
			TransitionManager.current_transition.on(Thunder._current_player, false, true)
			if !Thunder._current_player:
				TransitionManager.current_transition.paused = false
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)
