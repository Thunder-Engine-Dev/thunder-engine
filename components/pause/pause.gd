extends Control

var opened: bool = false
var open_blocked: bool = false

const _MusicLoader: Script = preload("res://engine/objects/core/music_loader/music_loader.gd")

const open_sound = preload("./sounds/pause_open.wav")
const close_sound = null

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var v_box_container: MenuItemsController = $VBoxContainer
@onready var options: MenuItemsController = $"../Settings/SubViewportContainer/SubViewport/Options"
@onready var controls_options: MenuItemsController = $"../Controls/Options"


func _ready() -> void:
	Scenes.custom_scenes.pause = self
	animation_player.play(&"init")


func _unhandled_input(event: InputEvent) -> void:
	if &"game_over" in Scenes.custom_scenes && Scenes.custom_scenes.game_over.opened: return
	if event.is_action_pressed(&"pause_toggle") && (
		Scenes.current_scene is Level ||
		Scenes.current_scene is Map2D
	) && !(opened && event.is_action_pressed("ui_cancel")):
		toggle.call_deferred()


func toggle(no_resume: bool = false, no_sound_effect: bool = false) -> void:
	if !v_box_container.focused && opened: return
	
	if !opened && TransitionManager.current_transition:
		return
	
	if open_blocked: return
	
	opened = !opened
	$'..'.offset = Vector2.ZERO
	
	for i in Scenes.current_scene.get_children():
		if !i is _MusicLoader:
			continue
		i = i as _MusicLoader # To get code hints
		if i.channel_id in Audio._music_channels && is_instance_valid(Audio._music_channels[i.channel_id]):
			var vol: float = 0
			if !i.volume_db.is_empty():
				vol = i.volume_db[i.index]
			Audio.fade_music_1d_player(
				Audio._music_channels[i.channel_id],
				-20 + vol if opened || no_resume else vol,
				0.3
			)
			break
	
	if opened:
		v_box_container.move_selector(0, true)
		animation_player.play("open")
		if !no_sound_effect:
			Audio.play_1d_sound(open_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		animation_player.play_backwards("open")
		Audio.play_1d_sound(close_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	get_tree().paused = opened
	
	for i in 2:
		await get_tree().physics_frame
	
	v_box_container.focused = opened
	options.focused = false
	controls_options.focused = false


func _physics_process(delta: float) -> void:
	if !opened: return
	if !get_tree().paused:
		get_tree().paused = true


var autopause_timer: SceneTreeTimer

func _notification(what: int) -> void:
	var method: Callable = func():
		if !opened: toggle.bind(false, true).call_deferred()
	
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if !Scenes.current_scene is Level: return
		if !&"settings" in SettingsManager || !&"autopause" in SettingsManager.settings: return
		if !SettingsManager.settings.autopause: return
		if !&"game_over" in Scenes.custom_scenes: return
		if opened || Scenes.custom_scenes.game_over.opened: return
		if get_tree().paused: return
		if autopause_timer == null:
			autopause_timer = get_tree().create_timer(0.2)
			autopause_timer.timeout.connect(method)
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if is_instance_valid(autopause_timer) && autopause_timer.timeout.is_connected(method):
			autopause_timer.timeout.disconnect(method)
		autopause_timer = null
