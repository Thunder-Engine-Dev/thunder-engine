extends Control

@export_node_path("Area2D") var pipe_out: NodePath

var opened: bool

var profile: Dictionary
var scene: String

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var v_box_container: MenuItemsController = $VBoxContainer
@onready var level_label: Label = $LevelLabel
@onready var state_preview: AnimatedSprite2D = $StatePreview

@onready var _pipe_out: Area2D = get_node_or_null(pipe_out)

signal popped
signal closed

func _ready() -> void:
	animation_player.play(&"init")
	
	var player: Player = Thunder._current_player
	if ProfileManager.profiles.has("suspended") && ProfileManager.profiles.has(ProfileManager.profiles.suspended.data.get("saved_profile")):
		player.no_movement = true
		player.hide()
		
		profile = ProfileManager.profiles.suspended.data
		scene = profile.scene
		var label_text: String = profile.title_prefix.replacen("\\n", "
")
		label_text += profile.title_level
		level_label.text = label_text
		if profile.get("saved_player_state"):
			state_preview.sprite_frames = load(profile.saved_player_state).animation_sprites
			state_preview.play("walk")
		Scenes.custom_scenes.pause.open_blocked = true
		
		toggle()
		await get_tree().physics_frame
		show()
	elif _pipe_out:
		trigger_pipe()


func toggle(no_resume: bool = false, no_sound_effect: bool = false) -> void:
	if !v_box_container.focused && opened: return
	
	opened = !opened
	
	if opened:
		popped.emit()
	else:
		closed.emit()
	
	$'..'.offset = Vector2.ZERO
	
	if opened:
		v_box_container.move_selector(0, true)
		animation_player.play("open")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		animation_player.play_backwards("open")
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		Thunder._current_player.show()
	
	for i in 2:
		await get_tree().physics_frame
	
	v_box_container.focused = opened
	#options.focused = false
	#controls_options.focused = false


func trigger_pipe() -> void:
	var player: Player = Thunder._current_player
	_pipe_out.player = player
	_pipe_out.player_z_index = player.z_index
	player.speed = Vector2.ZERO
	player.no_movement = false
	_pipe_out.pass_player.call_deferred(player)
	await get_tree().physics_frame
	Scenes.custom_scenes.pause.open_blocked = false
