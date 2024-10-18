extends MenuSelection


func _handle_select() -> void:
	TransitionManager.accept_transition(
		load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
			.instantiate()
			.with_speeds(0.015, -1)
	)

	get_parent().focused = false
	var music = Audio._music_channels[0]
	Audio.fade_music_1d_player(music, -40, 2.4, Tween.TRANS_LINEAR, true)
	TransitionManager.transition_middle.connect(get_tree().quit)
