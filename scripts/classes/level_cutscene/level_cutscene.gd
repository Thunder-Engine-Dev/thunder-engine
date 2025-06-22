@warning_ignore("missing_tool")
class_name LevelCutscene extends Stage2D

const LETS = preload("res://engine/scenes/main_menu/sounds/lets.wav")
const FADEOUT = preload("res://engine/components/ui/_sounds/fadeout.wav")

@export_file("*.tscn", "*.scn") var goto_path: String
@export var fade_out_time: float = 0.04
@export var fade_out_focus_on_player: bool = true
@export_group("Cutscene Options")
@export var intro_music: AudioStream = LETS
@export var transition_sound: AudioStream = FADEOUT

@onready var player_state = Thunder._current_player_state
@onready var player: Player = Thunder._current_player

var skippable: bool = false
var has_skipped: bool = false

@onready var _crossfade: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)

func _ready() -> void:
	super()
	var _trans = TransitionManager.current_transition
	if _crossfade && is_instance_valid(_trans) && _trans.name == "crossfade_transition":
		await _trans.end
	var _sfx = CharacterManager.get_sound_replace(intro_music, LETS, "level_cutscene_song", false)
	Audio.play_1d_sound(_sfx, false, { "bus": "Music" })
	
	await get_tree().create_timer(1.0, true, false, true).timeout
	skippable = true
	
	Console.executed.connect(func(command_name, args):
		if command_name == "finish" && !TransitionManager.current_transition && goto_path:
			end()
	)

#func _physics_process(delta: float) -> void:
#	if skippable: _cutscene_skip_logic()
	

func _cutscene_skip_logic() -> void:
	if Input.is_action_just_pressed("m_jump") || Input.is_action_just_pressed("ui_accept"):
		skippable = false
		_start_transition()


func end() -> void:
	if has_skipped: return
	var _sfx = CharacterManager.get_sound_replace(transition_sound, transition_sound, "menu_fade_out", false)
	Audio.play_1d_sound(_sfx, true, { "ignore_pause": true, "bus": "1D Sound" })
	_start_transition.call_deferred()


func _start_transition() -> void:
	if has_skipped: return
	has_skipped = true
	if _crossfade:
		TransitionManager.accept_transition(
			load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
				.instantiate()
				.with_scene(goto_path)
		)
		return
	
	TransitionManager.accept_transition(
		load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
			.instantiate()
			.with_speeds(fade_out_time, -0.1)
			.with_pause()
			.on_player_after_middle(fade_out_focus_on_player)
	)
	
	await TransitionManager.transition_middle
	Scenes.goto_scene(goto_path)
