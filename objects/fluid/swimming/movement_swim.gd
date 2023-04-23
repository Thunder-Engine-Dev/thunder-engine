extends Resource

var player = Thunder._current_player

var swim_velocity = 161.5
var swim_velocity_edge = 484.5

var max_run_speed: float
var max_fall_speed: float
var fall_speed: float


func store_config() -> void:
	max_run_speed = player.config.max_run_speed
	max_fall_speed = player.config.max_fall_speed
	fall_speed = player.config.fall_speed

func load_config() -> void:
	player.config.max_run_speed = max_run_speed
	player.config.max_fall_speed = max_fall_speed
	player.config.fall_speed = fall_speed


func _movement_swim(delta: float) -> void:
	player.config.max_run_speed = 175
	player.config.max_fall_speed = 165
	player.config.fall_speed = 5


	# Hold jump
	if !player.is_on_floor() && Input.is_action_pressed(player.config.control_jump) && player.velocity_local.y < 0:
		player.states.set_state("swim")
		#player.velocity_local.y -= player.config.jump_speed_stopped * delta
	
	# Applying initial acceleration
	if abs(player.velocity_local.x) < player.config.initial_accel_trigger && player.states.left_or_right != 0:
		player.velocity_local.x = player.config.initial_acceleration * player.states.left_or_right
	
	# Direction
	if player.velocity_local.x > player.config.initial_acceleration:
		player.states.dir = 1
	elif player.velocity_local.x < player.config.initial_acceleration:
		player.states.dir = -1
	
	if Input.is_action_pressed(player.config.control_down) && Thunder._current_player_state.player_power != Data.PLAYER_POWER.SMALL:
		player.states.set_state("crouch")
	
	if !Input.is_action_pressed(player.config.control_down) && player.states.current_state == "crouch":
		player.states.set_state("swim_default")
	
	if Input.is_action_just_pressed(player.config.control_jump) && player.states.current_state != "crouch":
		player.velocity_local.y = -swim_velocity
		player.states.jump_buffer = false
		Audio.play_sound(player.config.swim_sound, player, true, {pitch = player.config.sound_pitch})
	
	# Generic fall velocity, acceleration and deceleration
	player._movement_generic(delta)
	player._movement_generic_fall(delta)
