@warning_ignore("missing_tool")
class_name LevelCutscene extends Stage2D

const LETS = preload("res://engine/scenes/main_menu/sounds/lets.wav")
const FADEOUT = preload("res://engine/components/ui/_sounds/fadeout.wav")

## Which scene to go to after the cutscene ends. Not required for cutscenes with warps in them,
## but recommended to set anyway.
@export_file("*.tscn", "*.scn") var goto_path: String
@export var fade_out_time: float = 0.04
@export var fade_out_focus_on_player: bool = true
@export_group("Skipping")
## If [code]true[/code], after [param skip_delay_sec] seconds passes, the cutscene can be skipped with
## jump or Enter keys.[br]Requires [param goto_path] to be set.
@export var can_be_skipped: bool = false
@export var skip_delay_sec: float = 0.5
@export_group("Cutscene Options")
## Music that will start playing when cutscene starts. Set to an empty WAV stream for no music.
@export var intro_music: AudioStream = LETS
@export var transition_sound: AudioStream = FADEOUT

@onready var player_state = Thunder._current_player_state
@onready var player: Player = Thunder._current_player

var skippable: bool = false
var has_skipped: bool = false
var _unpause_skip_block: bool

@onready var _crossfade: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)

func _ready() -> void:
	super()
	Scenes.custom_scenes.pause.unpaused.connect(_on_pause_unpaused)
	var _trans = TransitionManager.current_transition
	if _crossfade && is_instance_valid(_trans) && _trans.name == "crossfade_transition":
		await _trans.end
	var _sfx = CharacterManager.get_sound_replace(intro_music, LETS, "level_cutscene_song", false)
	Audio.play_1d_sound(_sfx, false, { "bus": "Music" })
	
	Console.executed.connect(func(command_name, args):
		if command_name == "finish" && !TransitionManager.current_transition && goto_path:
			end()
	)
	
	await get_tree().create_timer(skip_delay_sec, false, true).timeout
	skippable = true
	

func _physics_process(delta: float) -> void:
	if can_be_skipped && skippable && goto_path:
		_cutscene_skip_logic()


func _cutscene_skip_logic() -> void:
	if _unpause_skip_block:
		if Input.is_action_just_pressed("m_jump") || Input.is_action_just_pressed("ui_accept"):
			return
		_unpause_skip_block = false
	if Scenes._pending_scenes.size() > 0:
		return
	if Input.is_action_just_pressed("m_jump") || Input.is_action_just_pressed("ui_accept"):
		skippable = false
		_start_transition()


func _on_pause_unpaused() -> void:
	_unpause_skip_block = true


func end() -> void:
	if has_skipped: return
	var _sfx = CharacterManager.get_sound_replace(transition_sound, transition_sound, "menu_fade_out", false)
	Audio.play_1d_sound(_sfx, true, { "ignore_pause": true, "bus": "1D Sound" })
	_start_transition.call_deferred()


func _start_transition() -> void:
	if has_skipped: return
	has_skipped = true
	await Scenes.goto_scene_with_transition(goto_path, func(t):
		t.with_speeds(fade_out_time, -0.1).with_pause().on_player_after_middle(fade_out_focus_on_player)
	)
