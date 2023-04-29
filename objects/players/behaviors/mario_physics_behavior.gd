extends ByNodeScript

var player: PlayerMario
var suit: MarioSuit
var config: MarioConfig

var _has_jumped: bool


func _ready() -> void:
	player = node as PlayerMario
	suit = node.suit
	config = suit.physics_config
	player.underwater.got_into_water.connect(player.set.bind(&"is_underwater", true))
	player.underwater.got_out_of_water.connect(player.set.bind(&"is_underwater", false))


func _physics_process(delta: float) -> void:
	delta = player.get_physics_process_delta_time()
	# Control
	player.control_process()
	# Shape
	_shape_process()
	# Movement
	_movement_x(delta)
	_movement_y(delta)
	player.motion_process(delta)
	if player.is_on_wall():
		player.speed.x = 0


#= Movement
func _accelerate(to: float, acce: float, delta: float) -> void:
	player.speed.x = move_toward(player.speed.x, to * player.direction, abs(acce) * delta)


func _decelerate(dece: float, delta: float) -> void:
	_accelerate(0, dece, delta)


func _movement_x(delta: float) -> void:
	if player.is_crouching || player.left_right == 0:
		_decelerate(config.walk_deceleration, delta)
		return
	# Initial speed
	if player.left_right != 0 && player.speed.x == 0:
		player.direction = player.left_right
		player.speed.x = player.direction * config.walk_initial_speed
	# Acceleration
	if player.left_right == player.direction:
		var max_speed: float = config.underwater_walk_max_walking_speed if player.is_underwater else (config.walk_max_running_speed if player.running else config.walk_max_walking_speed)
		_accelerate(max_speed, config.walk_acceleration, delta)
	elif player.left_right == -player.direction:
		_decelerate(config.walk_turning_acce, delta)
		if player.speed.x == 0:
			player.direction *= -1 


func _movement_y(delta: float) -> void:
	if player.is_crouching && !ProjectSettings.get_setting("application/thunder_settings/player/jumpable_when_crouching", false):
		return
	
	# Swimming
	if player.is_underwater:
		if player.jumped:
			player.jump(config.swim_out_speed if player.is_underwater_out else config.swim_speed)
		if player.speed.y < -abs(config.swim_max_speed):
			player.speed.y = abs(config.swim_max_speed)
		Audio.play_sound(config.sound_swim, player, false, {pitch = suit.sound_pitch})
	# Jumping
	else:
		if player.is_on_floor():
			if player.jumping > 0 && !_has_jumped:
				_has_jumped = true
				player.jump(config.jump_speed)
				Audio.play_sound(config.sound_jump, player, false, {pitch = suit.sound_pitch})
		elif player.jumping > 0 && player.speed.y < 0:
			var buff: float = config.jump_buff_dynamic if abs(player.speed.x) > 10 else config.jump_buff_static
			player.speed.y -= abs(buff) * delta
	if !player.jumping:
		_has_jumped = false


#= Shape
func _shape_process() -> void:
	var shaper: Shaper2D = suit.physics_shaper_crouch if player.is_crouching else suit.physics_shaper
	shaper.install_shape_for(player.collision_shape)
	shaper.install_shape_for_caster(player.body)
	
	if player.collision_shape.shape is RectangleShape2D:
		player.head.position.y = player.collision_shape.position.y - player.collision_shape.shape.size.y / 2
