extends GravityBody2D

@export var wait_time: float = 3.5
@export var check_for_lives: bool = true
@export_file("*.tscn", "*.scn") var jump_to_scene: String = ""

var circle_closing_speed: float = 0.05
var circle_opening_speed: float = 0.1

var movement: bool

@onready var _is_simple_fade: bool = SettingsManager.get_tweak("replace_circle_transitions_with_fades", false)


func _ready() -> void:
	await get_tree().create_timer(0.5, false, true).timeout

	movement = true
	vel_set_y(-550)

	if wait_time > 0.0:
		await get_tree().create_timer(wait_time, false, true).timeout
	elif wait_time <= -1.0:
		return

	# After death
	var has_gameover: bool = _init_game_over()
	if has_gameover:
		return
	_reset_data_values()
	_start_transition()


func _physics_process(delta: float) -> void:
	if !movement:
		return
	
	#if _suit_pause_tweak && Scenes.custom_scenes.pause.opened:
	#	return
	motion_process(delta)


func _init_game_over() -> bool:
	if check_for_lives && Data.values.lives == 0:
		if is_instance_valid(Thunder._current_hud):
			Thunder._current_hud.game_over()
		return true
	return false


func _reset_data_values() -> void:
	Thunder._current_player_state = null
	Thunder._current_player_state_path = ""
	Data.values.lives -= 1
	Data.values.onetime_blocks = false


func _start_transition() -> void:
	# Transition (tweaked, crossfade)
	if _is_simple_fade:
		var _scene = Scenes.current_scene.scene_file_path if jump_to_scene.is_empty() else jump_to_scene
		Audio.stop_all_sounds()
		TransitionManager.accept_transition(
		load("res://engine/components/transitions/crossfade_transition/crossfade_transition.tscn")
			.instantiate()
			.with_scene(_scene)
		)
		return
	_transition_circle()


func _transition_circle() -> void:
	# Transition (default, circle)
	TransitionManager.accept_transition(
	load("res://engine/components/transitions/circle_transition/circle_transition.tscn")
		.instantiate()
		.with_speeds(circle_closing_speed, -circle_opening_speed)
		.with_pause()
		.on_player_after_middle(true)
	)

	var marker = _create_marker()
	TransitionManager.current_transition.on(marker) # Supports a Node2D or a Vector2
	await TransitionManager.transition_middle

	if jump_to_scene.is_empty():
		Scenes.current_scene.restart()
	else:
		Scenes.goto_scene(jump_to_scene)
		get_tree().paused = false


func _create_marker() -> Marker2D:
	var cam: Camera2D = Thunder._current_camera
	var marker: Marker2D
	if cam:
		var cam_pos = cam.get_screen_center_position()
		marker = Marker2D.new()
		marker.position = Vector2(
			global_position.x,
			clamp(global_position.y, cam_pos.y - 248, cam_pos.y + 248)
		)
		marker.reset_physics_interpolation()
		Scenes.current_scene.add_child(marker)
	return marker
