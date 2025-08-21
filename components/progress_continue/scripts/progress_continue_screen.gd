extends Control

@export_node_path("Area2D") var pipe_out: NodePath

var opened: bool

var profile: Dictionary
var scene: String

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var v_box_container: MenuItemsController = $VBoxContainer
@onready var v_box_container_2: MenuItemsController = $VBoxContainer2
@onready var level_label: Label = $LevelLabel
@onready var state_preview: AnimatedSprite2D = $StatePreview

@onready var _pipe_out: Area2D = get_node_or_null(pipe_out)

signal popped
signal closed

func _ready() -> void:
	animation_player.play(&"init")

	if (
		Data.technical_values.impulse_progress_continue &&
		ProfileManager.profiles.has("suspended") &&
		ProfileManager.profiles.has(ProfileManager.profiles.suspended.data.get("saved_profile")) &&
		SettingsManager.get_tweak("progress_continue", true)
	):
		suspended_game_logic()
	elif _pipe_out:
		trigger_pipe()
	
	Data.technical_values.impulse_progress_continue = false


func suspended_game_logic() -> void:
	var player: Player = Thunder._current_player
	player.no_movement = true
	player.hide()

	profile = ProfileManager.profiles.suspended.data
	scene = profile.scene
	var label_text: String = profile.title_prefix.replacen("\\n", "
")
	label_text += profile.title_level
	level_label.text = label_text
	if profile.get(&"saved_player_state"):
		state_preview.position.x = get_viewport_rect().size.x / 2
		state_preview.sprite_frames = SkinsManager.apply_player_skin(CharacterManager.get_suit(profile.saved_player_state))
		state_preview.play(&"walk")
	Scenes.custom_scenes.pause.open_blocked = true
	
	animation_player.play(&"init")
	toggle()


func toggle(no_resume: bool = false, no_sound_effect: bool = false) -> void:
	if !v_box_container.focused && !v_box_container_2.focused && opened: return

	opened = !opened

	if opened:
		popped.emit()
	else:
		closed.emit()

	$'..'.offset = Vector2.ZERO

	if opened:
		v_box_container.move_selector(0, true)
		animation_player.play("open")
		SettingsManager.show_mouse()
	else:
		animation_player.play_backwards("open")
		SettingsManager.hide_mouse()
		Thunder._current_player.show()

	for i in 2:
		await get_tree().physics_frame

	v_box_container.focused = opened
	#options.focused = false
	#controls_options.focused = false


func trigger_pipe() -> void:
	var player: Player = Thunder._current_player
	_pipe_out.player = player
	_pipe_out.player_z_index = player.sprite_container.z_index
	player.speed = Vector2.ZERO
	player.no_movement = false
	_pipe_out.pass_player.call_deferred(player)
	await get_tree().physics_frame
	Scenes.custom_scenes.pause.open_blocked = false
