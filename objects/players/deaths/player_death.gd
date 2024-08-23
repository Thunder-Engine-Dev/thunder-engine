extends GravityBody2D

@export var wait_time: float = 3.5
@export var check_for_lives: bool = true
@export_file("*.tscn", "*.scn") var jump_to_scene: String = ""

var circle_closing_speed: float = 0.05
var circle_opening_speed: float = 0.1

var movement: bool

@onready var game_over_music: AudioStream = load(ProjectSettings.get_setting("application/thunder_settings/player/gameover_music"))
@onready var _is_simple_fade: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)
@onready var _suit_pause_tweak: bool = SettingsManager.get_tweak("pause_on_suit_change", false)


func _ready() -> void:
	await get_tree().create_timer(0.5, _suit_pause_tweak, true).timeout
	
	movement = true
	vel_set_y(-550)
	
	if wait_time > 0.0:
		await get_tree().create_timer(wait_time, _suit_pause_tweak, true).timeout
	elif wait_time <= -1.0:
		return
	
	if _suit_pause_tweak:
		movement = false
		for sound in GlobalViewport.get_children():
			if !sound is AudioStreamPlayer2D:
				continue
			if sound.process_mode != Node.PROCESS_MODE_ALWAYS && sound.bus != "Music":
				sound.queue_free()
				
		while Scenes.custom_scenes.pause.opened:
			await get_tree().physics_frame
	
	# After death
	if check_for_lives:
		if Data.values.lives == 0:
			if is_instance_valid(Thunder._current_hud):
				Thunder._current_hud.game_over()
				Audio.play_music(game_over_music, 1, { "ignore_pause": true }, false, false)
			return
	Thunder._current_player_state = null
	Data.values.lives -= 1
	Data.values.onetime_blocks = false
	
	# Transition (tweaked, crossfade)
	if _is_simple_fade:
		var _scene = Scenes.current_scene.scene_file_path if jump_to_scene.is_empty() else jump_to_scene
		TransitionManager.accept_transition(
		load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
			.instantiate()
			.with_scene(_scene)
		)
		return
	
	# Transition (default, circle)
	TransitionManager.accept_transition(
	load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
		.instantiate()
		.with_speeds(circle_closing_speed, -circle_opening_speed)
	)
	
	var cam: Camera2D = Thunder._current_camera
	var marker: Marker2D
	if cam:
		var cam_pos = cam.get_screen_center_position()
		marker = Marker2D.new()
		marker.position = Vector2(
			global_position.x,
			clamp(global_position.y, cam_pos.y - 248, cam_pos.y + 248)
		)
		Scenes.current_scene.add_child(marker)
	
	TransitionManager.current_transition.on(marker) # Supports a Node2D or a Vector2
	TransitionManager.transition_middle.connect(func():
		TransitionManager.current_transition.paused = true
		if jump_to_scene.is_empty():
			Scenes.reload_current_scene()
		else:
			Scenes.goto_scene(jump_to_scene)
			Scenes.scene_changed.connect(func(_current_scene):
				TransitionManager.current_transition.paused = false
				get_tree().paused = false
			, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT | CONNECT_DEFERRED)


func _physics_process(delta: float) -> void:
	if !movement:
		return
	motion_process(delta)
