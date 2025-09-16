class_name Map2D extends Node2D

signal player_fast_forwarded
signal next_level_ready(index: int) ## Emitted with the next level index on ready
signal player_entered_level ## Emitted when the player enters a level.

@export var player: NodePath
@export_group("Map Customization")
@export var dot_style: SpriteFrames = preload("res://engine/scenes/map/prefabs/dot_style.tres")
@export var dot_sprite_offset: Vector2 = Vector2.ZERO
@export var transition_sound: AudioStream = preload("res://engine/components/ui/_sounds/fadeout.wav")
@export var jump_button_sound: AudioStream = preload("res://engine/objects/items/coin/coin.wav")

var to_level: String
var is_fading: bool
var enter_on_request_only: bool

@onready var _is_simple_fade: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)

func _ready() -> void:
	Data.values.checkpoint = -1
	Data.values.checked_cps = []
	Data.values.onetime_blocks = true

	var music := _get_music()
	if _is_simple_fade: return
	await get_tree().physics_frame

	TransitionManager.transition_middle.connect(func():
		if is_instance_valid(music): music.stop()
		TransitionManager.current_transition.paused = true
		Scenes.goto_scene(get_node(player).current_marker.level)
		Scenes.scene_ready.connect(func():
			TransitionManager.current_transition.on(Thunder._current_player)
			if !Thunder._current_player:
				TransitionManager.current_transition.paused = false
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT | CONNECT_DEFERRED)


func get_first_marker_space() -> MarkerSpace:
	var children = get_children()
	for child in children:
		if child is MarkerSpace:
			return child

	return null


func _physics_process(delta: float) -> void:
	if !get_node(player): return
	if !get_node(player).reached: return
	if !get_node(player).current_marker: return
	if !get_node(player).current_marker.level: return
	if is_fading: return
	if !Input.is_action_just_pressed(&"m_jump"): return
	player_entered_level.emit()
	is_fading = true
	
	if !enter_on_request_only:
		enter_level_sequence()


func enter_level_sequence() -> void:
	var _sfx2 = CharacterManager.get_sound_replace(jump_button_sound, jump_button_sound, "map_level_enter", false)
	Audio.play_1d_sound(_sfx2, true, { "ignore_pause": true, "bus": "1D Sound" })
	print("[Game] Going to a level.")
	if Thunder.autosplitter.can_start_on("map_start"):
		Thunder.autosplitter.start_timer()
	var music := _get_music()
	if music && is_instance_valid(music):
		Audio.fade_music_1d_player(music, -40, 1.0, Tween.TRANS_LINEAR, true)

	await get_tree().create_timer(0.4, false).timeout
	var _sfx = CharacterManager.get_sound_replace(transition_sound, transition_sound, "menu_fade_out", false)
	Audio.play_1d_sound(_sfx, true, { "ignore_pause": true, "bus": "1D Sound" })
	_start_transition.call_deferred()


func _get_music() -> Node:
	return (
		Audio._music_channels[1] if 1 in Audio._music_channels &&
		is_instance_valid(Audio._music_channels[1]) else null
	)


func _start_transition() -> void:
	SettingsManager.hide_mouse()
	while is_instance_valid(TransitionManager.current_transition):
		await get_tree().physics_frame
	if !_is_simple_fade:
		TransitionManager.accept_transition(
			load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
				.instantiate()
				.with_speeds(0.024, -0.1)
				.with_pause()
				.on_player_after_middle(true)
		)
	else:
		TransitionManager.accept_transition(
			load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
				.instantiate()
				.with_scene(get_node(player).current_marker.level)
		)
		var music = _get_music()
		if is_instance_valid(music): music.stop()
