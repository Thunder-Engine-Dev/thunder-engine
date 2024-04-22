extends Node

@export_file("*.tscn", "*.scn") var goto_path: String
@export var fade_out_time: float = 0.04
@export_group("Cutscene Options")
@export var intro_music: AudioStream = preload("res://engine/scenes/main_menu/sounds/lets.wav")

@onready var player_state = Thunder._current_player_state
@onready var player: Player = Thunder._current_player
#@onready var player_sprite: AnimatedSprite2D = $Player/Sprite

var skippable: bool = false
var has_skipped: bool = false

func _ready() -> void:
	Audio.play_1d_sound(intro_music, false)
	
	await get_tree().create_timer(1.0, true, false, true).timeout
	skippable = true
	

#func _physics_process(delta: float) -> void:
#	if skippable: _cutscene_skip_logic()
	

func _cutscene_skip_logic() -> void:
	if Input.is_action_just_pressed("m_jump") || Input.is_action_just_pressed("ui_accept"):
		skippable = false
		_start_transition()
	

#func sound_play() -> void:
#	cutscenka_pokonany___.play()

#func babah() -> void:
#	Audio.play_1d_sound(preload("res://smb2/sounds/babah.wav"))
#	for i in 50:
#		var brick = WORLD_1_CASTLE_DEBRIS.instantiate()
#		brick.position = Vector2(240 + randi_range(-96, 96), 320 + randi_range(-48, 32))
#		brick.velocity = Vector2(randf_range(-7, 7), randf_range(-6, -12))
#		add_child(brick)

func end() -> void:
	if has_skipped: return
	Audio.play_1d_sound(preload("res://engine/components/ui/_sounds/fadeout.wav"))
	_start_transition()


func _start_transition() -> void:
	if has_skipped: return
	has_skipped = true
	TransitionManager.accept_transition(
		load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
			.instantiate()
			.with_speeds(fade_out_time, -0.1)
	)
	
	var scene_path = goto_path
	TransitionManager.transition_middle.connect(func():
		TransitionManager.current_transition.paused = true
		Scenes.goto_scene(scene_path)
		Scenes.scene_changed.connect(func(_current_scene):
			TransitionManager.current_transition.paused = false
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)
