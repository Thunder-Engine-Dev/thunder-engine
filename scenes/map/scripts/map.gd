extends Node2D

@export
var player: NodePath
@export
var level_paths: Dictionary
@export_group("Map Customization")
@export
var dot_style: SpriteFrames
@export
var transition_sound: AudioStream = preload("res://engine/components/ui/_sounds/fadeout.wav")

var to_level: String
var is_fading: bool

func get_first_marker_space() -> MarkerSpace:
	var children = get_children()
	for child in children:
		if child is MarkerSpace:
			return child
	
	return null

func _physics_process(delta: float) -> void:
	if !to_level: return
	if is_fading: return
	if !Input.is_action_just_pressed(&"m_jump"): return
	if !to_level in level_paths.keys():
		printerr(
			&"Unknown level: " + to_level + &". Add it to Level Paths dictionary in root Map."
		)
		return
	
	var music = Audio._music_channels[1] if 1 in Audio._music_channels else null
	if music: Audio.fade_music_1d_player(music, -40, 1.0, Tween.TRANS_LINEAR, true)
	
	TransitionManager.accept_transition(
		load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
			.instantiate()
			.with_speeds(0.015, -0.1)
	)
	
	Audio.play_1d_sound(transition_sound)
	is_fading = true
	
	TransitionManager.transition_middle.connect(func():
		if is_instance_valid(music): music.stop()
		TransitionManager.current_transition.paused = true
		Scenes.goto_scene(level_paths[to_level])
		Scenes.scene_changed.connect(func(_current_scene):
			TransitionManager.current_transition.on(Thunder._current_player)
			TransitionManager.current_transition.paused = false
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)

