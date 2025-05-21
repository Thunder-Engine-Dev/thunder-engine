extends MenuSelection

@onready var prog: Control = $"../.."
@onready var _is_simple_fade: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)
var _has_started: bool

func _handle_select(mouse_input: bool = false) -> void:
	if _has_started:
		return
	super(mouse_input)
	
	Scenes.custom_scenes.pause.open_blocked = false
	
	Data.values = prog.profile.saved_values.duplicate(true)
	Data.values.skip_progress_continue = true
	
	if "remaining_continues" in prog.profile:
		Data.technical_values["remaining_continues"] = int(prog.profile.remaining_continues)
	if "saved_player_state" in prog.profile:
		Thunder._current_player_state = CharacterManager.get_suit(prog.profile.saved_player_state)
		Thunder._current_player_state_path = ""
	
	ProfileManager.current_profile = ProfileManager.profiles[prog.profile.saved_profile]
	ProfileManager.current_profile.data = prog.profile.saved_profile_data
	
	_start_transition.call_deferred()
	_has_started = true
	get_parent().focused = false


func _start_transition() -> void:
	# Transition (tweaked, crossfade)
	if _is_simple_fade:
		var _scene = prog.scene
		TransitionManager.accept_transition(
		load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
			.instantiate()
			.with_scene(_scene)
		)
		return
	_transition_circle()


func _transition_circle() -> void:
	# Transition (default, circle)
	TransitionManager.accept_transition(
	load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
		.instantiate()
		.with_speeds(0.05, -0.1)
		.with_pause()
		#.on_player_after_middle(true)
	)
	
	TransitionManager.current_transition.on(Vector2(0.5, 0.5), true) # Supports a Node2D or a Vector2
	await TransitionManager.transition_middle
	
	Scenes.goto_scene(prog.scene)
	get_tree().paused = false
