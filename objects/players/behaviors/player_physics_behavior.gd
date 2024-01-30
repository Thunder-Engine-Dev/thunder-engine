extends ByNodeScript

var player: Player
var suit: PlayerSuit
var config: PlayerConfig


func _ready() -> void:
	player = node as Player
	player.underwater.got_into_water.connect(player.set.bind(&"is_underwater", true), CONNECT_REFERENCE_COUNTED)
	player.underwater.got_out_of_water.connect(player.set.bind(&"is_underwater", false), CONNECT_REFERENCE_COUNTED)


func _physics_process(delta: float) -> void:
	if player.get_tree().paused: return
	suit = node.suit
	config = suit.physics_config
	
	delta = player.get_physics_process_delta_time()
	# Control
	if !player.completed: player.control_process()
	# Shape
	_shape_process()
	if player.warp != Player.Warp.NONE: return
	
	# Head
	_head_process()
	# Body
	_body_process()
	# Movement
	if player.is_climbing:
		_movement_climbing(delta)
	elif player.is_sliding:
		_movement_sliding(delta)
		_movement_y(delta)
	else:
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
	if player.slided:
		var do_slide = true if \
			suit.physics_crouchable else true if player.left_right == 0 else false
		if do_slide:
			_start_sliding_movement()
			return
	if player.is_crouching || player.left_right == 0 || player.completed:
		_decelerate(config.walk_deceleration, delta)
		return
	# Initial speed
	if player.left_right != 0 && player.speed.x == 0:
		player.direction = player.left_right
		player.speed.x = player.direction * config.walk_initial_speed
	# Acceleration
	if player.left_right == player.direction:
		var max_speed: float = (
			config.underwater_walk_max_walking_speed if player.is_underwater else (
				config.walk_max_running_speed if player.running else \
				config.walk_max_walking_speed
			)
		)
		_accelerate(max_speed, config.walk_acceleration, delta)
	elif player.left_right == -player.direction:
		_decelerate(config.walk_turning_acce, delta)
		if player.speed.x == 0:
			player.direction *= -1


func _movement_y(delta: float) -> void:
	if player.is_crouching && !ProjectSettings.get_setting("application/thunder_settings/player/jumpable_when_crouching", false):
		return
	if player.completed: return
	
	# Swimming
	if player.is_underwater:
		if player.jumped:
			player.jump(config.swim_out_speed if player.is_underwater_out else config.swim_speed)
			player.swam.emit()
			Audio.play_sound(config.sound_swim, player, false, {pitch = suit.sound_pitch})
		if player.speed.y < -abs(config.swim_max_speed) && !player.is_underwater_out:
			player.speed.y = lerp(player.speed.y, -abs(config.swim_max_speed), 0.125)
	# Jumping
	else:
		if player.is_on_floor():
			if player.jumping > 0 && !player._has_jumped:
				player._has_jumped = true
				player.jump(config.jump_speed)
				Audio.play_sound(config.sound_jump, player, false, {pitch = suit.sound_pitch})
		elif player.jumping > 0 && player.speed.y < 6.25:
			var buff: float = config.jump_buff_dynamic if abs(player.speed.x) > 10 else config.jump_buff_static
			player.speed.y -= abs(buff) * delta
	if !player.jumping && player.speed.y >= 0:
		player._has_jumped = false


#= Climbing
func _movement_climbing(delta: float) -> void:
	if player.is_crouching || player.completed: return
	player.vel_set(Vector2(player.left_right, player.up_down) * suit.physics_config.climb_speed)
	# Resist to gravity
	player.speed -= player.gravity_dir * player.gravity_scale * GravityBody2D.GRAVITY * delta
	
	# Jump from climbing
	if player.jumping > 0 && !player._has_jumped:
		player._has_jumped = true
		player.is_climbing = false
		player.direction = player.left_right
		player.jump(config.jump_speed)
		Audio.play_sound(config.sound_jump, player, false, {pitch = suit.sound_pitch})


#= Sliding from slopes
func _movement_sliding(delta: float) -> void:
	if player.completed: return
	if !player.is_on_floor():
		_stop_sliding_movement()
		return
	var floor_normal = rad_to_deg(player.get_floor_normal().x)
	var dir: bool = player.direction == 1
	# Acceleration
	var accel: Callable = func() -> void:
		_accelerate(config.slide_max_speed, config.slide_acceleration, delta)
	# Deceleration
	var decel: Callable = func() -> void:
		_decelerate(config.walk_deceleration, delta)
	
	# Sliding towards right
	if floor_normal >= 40.0:
		accel.call() if dir else decel.call()
		if player.speed.x == 0: _start_sliding_movement()
	# Sliding towards left
	elif floor_normal <= -40.0:
		accel.call() if !dir else decel.call()
		if player.speed.x == 0: _start_sliding_movement()
	# Momentum on flat surface after sliding
	else:
		decel.call()
		if player.speed.x == 0 || player.left_right != 0:
			_stop_sliding_movement()
	
	if player.left_right != 0 && player.left_right != player.direction && !player.slided:
		_stop_sliding_movement()


func _start_sliding_movement() -> void:
	player.attack.killing_detection_scale = 8
	player.attack.enabled = true
	var floor_norm = rad_to_deg(player.get_floor_normal().x)
	if floor_norm <= -40.0:
		player.speed.x = 1
		player.direction = -1
	if floor_norm >= 40.0:
		player.speed.x = -1
		player.direction = 1
	player.is_sliding = true


func _stop_sliding_movement() -> void:
	player.is_sliding = false
	player.attack.enabled = player.is_starman()
	if !player.is_starman(): player.starman_combo.reset_combo()
	player.attack.killing_detection_scale = 2


#= Shape
func _shape_process() -> void:
	var shaper: Shaper2D = (
		suit.physics_shaper_crouch if player.is_crouching && player.warp == Player.Warp.NONE else suit.physics_shaper
	)
	if !shaper: return
	shaper.install_shape_for(player.collision_shape)
	shaper.install_shape_for_caster(player.body)
	shaper.install_shape_for_caster(player.attack)
	
	if player.collision_shape.shape is RectangleShape2D:
		player.head.position.y = player.collision_shape.position.y - player.collision_shape.shape.size.y / 2 - 2


#= Head
func _head_process() -> void:
	player.is_underwater_out = true
	
	# Hit block
	for i in player.head.get_collision_count():
		var collider: Node2D = player.head.get_collider(i) as Node2D
		if !collider: continue
		# Water
		if collider.is_in_group(&"#water"): player.is_underwater_out = false
		# Bumpable Block
		if collider is StaticBumpingBlock && \
		collider.has_method(&"got_bumped") && \
		collider.global_position.direction_to(player.head.global_position + 8 * Vector2.DOWN.rotated(player.global_rotation)).dot(Vector2.DOWN.rotated(collider.global_rotation)) > cos(PI/4) && \
		((player.speed_previous.y < 0 && !collider.initially_visible_and_solid) || \
		(player.is_on_ceiling() && collider.initially_visible_and_solid)):
			collider.got_bumped.call_deferred(player)

#= Body
func _body_process() -> void:
	if !player.body.shape: return
	
	for i in player.body.get_collision_count():
		var collider: Node2D = player.body.get_collider(i) as Node2D
		if !is_instance_valid(collider):
			continue
		if !collider.has_node("EnemyAttacked"): return
		
		var enemy_attacked: Node = collider.get_node("EnemyAttacked")
		var result: Dictionary = enemy_attacked.got_stomped(player, player.velocity.normalized())
		if result.is_empty(): return
		if result.result == true:
			if player.jumping > 0:
				player.speed.y = -result.jumping_max * config.jump_stomp_multiplicator
			else:
				player.speed.y = -result.jumping_min * config.jump_stomp_multiplicator
		else:
			player.hurt(enemy_attacked.get_meta(&"stomp_tags", {}))
