extends Control

var opened: bool = false

const open_sound = preload("res://engine/components/pause/sounds/pause_open.wav")
const close_sound = null
#const music = preload("res://engine/components/game_over/music/4mat_-_broken_heart.xm")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var v_box_container: VBoxContainer = $VBoxContainer


func _ready() -> void:
	animation_player.play(&"init")
	Scenes.custom_scenes.game_over = self
	Scenes.scene_ready.connect(func():
		if !Thunder._current_hud: return
		Thunder._current_hud.game_over_finished.connect(func(): toggle())
	)


func toggle(no_resume: bool = false) -> void:
	while Scenes.custom_scenes.pause.opened:
		await get_tree().physics_frame
		if !Scenes.custom_scenes.pause._no_unpause:
			break
	opened = !opened
		
	if opened:
		v_box_container.move_selector(0)
		animation_player.play("open")
		#Audio.play_1d_sound(open_sound, true, { "ignore_pause": true })
		#Audio.play_music(music, 99, { "ignore_pause": true })
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		animation_player.play_backwards("open")
		Audio.play_1d_sound(close_sound, true, { "ignore_pause": true })
		Audio.stop_music_channel(99, false)
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		
		Data.reset_all_values()
		Data.values.lives = ProjectSettings.get_setting("application/thunder_settings/player/default_lives", 4)
		if !no_resume:
			Scenes.reload_current_scene()
	
	get_tree().paused = opened
	await get_tree().process_frame
	v_box_container.focused = opened
