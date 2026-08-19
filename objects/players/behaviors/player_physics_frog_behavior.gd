extends "res://engine/objects/players/behaviors/player_physics_behavior.gd"

const small_jump = preload("res://engine/objects/players/prefabs/sounds/small_jump.wav")
## Fall speed past which an airborne hop is treated as a real fall, not a 1-tile gap.
const HOP_AIR_BREAK_FALL_SPEED := 200.0

var jump_delay: float
var jump_sound_delay: float
var swim_delay: float
var hop_pausing: bool

var small_jump_played: bool = false

func _movement_x(delta: float) -> void:
	# Switch to sliding movement if slided on a slope
	if player.slided:
		var do_slide = true if \
			suit.physics_crouchable else true if player.left_right == 0 else false
		if do_slide:
			if _start_sliding_movement(true):
				return
	_movement_x_recovery(delta)
	if player.is_underwater:
		return
	
	if !player.is_on_floor():
		hop_pausing = false
		# Keep hop cadence while run-hopping over 1-tile gaps (body correction).
		if player._has_jumped || player.speed.y > HOP_AIR_BREAK_FALL_SPEED:
			jump_delay = -0.001
			jump_sound_delay = 0
		elif jump_delay >= 0:
			_advance_hop_cycle(delta)
	else:
		if jump_delay < 0 && !player.is_holding:
			jump_delay += delta
			player.speed.x = 0
			small_jump_played = false
			jump_sound_delay = 0
			return
		hop_pausing = false
		_advance_hop_cycle(delta)
		if abs(player.speed.x) <= 1 && (player.left_right == 0 || player.is_on_wall()) && jump_sound_delay == 0:
			jump_delay = -0.001
			jump_sound_delay = 0
			small_jump_played = false
	
	player.crouch_forced = false
	player.is_skidding = false
	
	# Crouching / Completed Level motion speed
	if player.left_right == 0:
		_decelerate(config.walk_deceleration, delta)
		if player.is_on_floor() && !player.completed && jump_delay >= 0.45 && !player.is_holding:
			player.speed.x = 0
			jump_delay = -0.12
			hop_pausing = true
		return
	
	_movement_x_acceleration(delta)
	
	# Initial speed
	if abs(player.speed.x) < config.walk_initial_speed:
		if (player.left_right > 0 && player.speed.x >= -1) || (player.left_right < 0 && player.speed.x <= 1):
			player.direction = sign(player.left_right)
			player.speed.x = player.direction * config.walk_initial_speed


func _advance_hop_cycle(delta: float) -> void:
	if abs(player.speed.x) > 1:
		jump_delay += delta
	var interrupting := player.sprite.animation in [&"kick", &"attack", &"grab"]
	if player.sprite.animation == &"walk":
		jump_sound_delay += delta
	elif !interrupting:
		jump_sound_delay = 0
	if !small_jump_played && !player.is_holding && player.sprite.animation == &"walk" && jump_delay > 0.2:
		small_jump_played = true
		var _sfx = CharacterManager.get_sound_replace(small_jump, small_jump, "jump_small", true)
		Audio.play_sound(_sfx, player, false, {pitch = suit.sound_pitch})


func _movement_x_acceleration(delta: float) -> void:
	# Acceleration
	var max_speed: float
	var acce_multiplier: float = 1.0
	acce_multiplier = 1.0
	if player.is_on_floor():
		acce_multiplier = 2.25 if player.running else 1.5
		
		if jump_delay >= 0.45 && !player.is_holding:
			player.speed.x = 0
			jump_delay = -0.12
			hop_pausing = true
	
	if sign(player.left_right) == player.direction:
		max_speed = (
			config.walk_max_running_speed if player.running else config.walk_max_walking_speed
		)
		_accelerate(max_speed * abs(player.left_right), config.walk_acceleration * acce_multiplier, delta)
			
	# Deceleration upon changing direction
	elif sign(player.left_right) == -player.direction:
		_decelerate(config.walk_turning_acce, delta)
		if abs(player.speed.x) < 1:
			player.direction *= -1


var swim_delayed: bool = false

func _movement_y(delta: float) -> void:
	if player.is_crouching && !player.crouch_forced && !ProjectSettings.get_setting("application/thunder_settings/player/jumpable_when_crouching", false):
		return
	if player.completed:
		jump_delay = 0
		jump_sound_delay = 0
		if player.crouch_forced && !player.is_on_floor():
			player.is_crouching = false
			player.crouch_forced = false
		return

	# Swimming
	if player.is_underwater:
		player.crouch_forced = false
		if player.jumped:
			player.coyote_time = 0.0
			player._has_jumped = true
		if player.is_underwater_out && player.jumping && player.up_down < 0:
			player.jump(config.swim_out_speed)
			return
		
		if swim_delay > 0:
			swim_delay += delta * (1.0 + (player.jumping * 0.9))
			if !swim_delayed:
				swim_delayed = true
				player.swam.emit()
				var _sndfx: AudioStream = config.sound_swim[randi_range(0, len(config.sound_swim) - 1)]
				Audio.play_sound(_sndfx, player, false, {pitch = suit.sound_pitch})
			if swim_delay > 1.0:
				swim_delay = 0
				swim_delayed = false
		else:
			swim_delay = int(player.left_right || player.up_down) * 0.01
			swim_delayed = false
		
		if player.speed.y < -abs(config.swim_max_speed) && !player.is_underwater_out:
			player.speed.y = lerp(player.speed.y, -abs(config.swim_max_speed), 0.125)
		
		# Vertical movement
		if player.up_down == 0:
			player.speed.y = move_toward(player.speed.y, 0, 625 * delta)
		else:
			player.speed.y = player.up_down * 125 * (1 + player.jumping * 1.1)
		
		# Horizontal movement
		if player.left_right == 0:
			_decelerate(625, delta)
		else:
			player.speed.x = player.left_right * 125 * (1 + player.jumping * 1.2)
			player.direction = sign(player.left_right)
		
		if player.is_underwater_out && player.up_down == 0:
			player.speed.y = move_toward(player.speed.y, 50, delta * 1000)

	# Jumping
	else:
		if swim_delay > 0.8:
			swim_delay = 0
		if swim_delay > 0:
			swim_delay += delta * (0.9 + player.jumping)
		else:
			swim_delayed = false
		if (player.is_on_floor() || player.coyote_time > 0.0) && (player.up_down <= 0 || player._crouch_jump_tweak):
			if player.jumping > 0 && !player._has_jumped:
				_stop_sliding_movement()
				player._has_jumped = true
				player.coyote_time = 0.0
				player.ghost_speed_y = 0.0
				player.jump(config.jump_speed)
				var _sndfx: AudioStream = config.sound_jump[randi_range(0, len(config.sound_jump) - 1)]
				Audio.play_sound(_sndfx, player, false, {pitch = suit.sound_pitch})
		elif player.jumping > 0:
			var buff: float = _calculate_jump_acceleration()
			if player.speed.y < 0.0:
				player.speed.y -= abs(buff) * delta
		if player._super_jump_tweak && player.jumping > 0 && player.ghost_speed_y < 0.0:
			var buff: float = _calculate_jump_acceleration()
			player.ghost_speed_y -= abs(buff) * delta
	
	if player._super_jump_tweak && player.ghost_speed_y < 0.0 && !player.is_on_floor():
		player.speed.y = player.ghost_speed_y
		player.ghost_speed_y = 0.0
	if !player.jumping && player.speed.y >= 0:
		player._has_jumped = false

func _stop_sliding_movement() -> void:
	super()
	jump_delay = 0
	hop_pausing = false

func _start_sliding_movement(do_initial_push: bool = true) -> bool:
	jump_delay = 0
	jump_sound_delay = 0
	hop_pausing = false
	return super(do_initial_push)
