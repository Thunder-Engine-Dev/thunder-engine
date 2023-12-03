extends MenuSelection


func _handle_select() -> void:
	TransitionManager.accept_transition(
		load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
			.instantiate()
			.with_speeds(0.015, -1)
	)
	
	TransitionManager.transition_middle.connect(get_tree().quit)

