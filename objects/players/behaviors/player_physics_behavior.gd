extends ByNodeScript

var player: Player
var suit: PlayerSuit
var config: PlayerConfig
var can_coyote: bool


func _ready() -> void:
	player = node as Player
	can_coyote = SettingsManager.get_tweak("coyote_time", true)
	
	player.underwater.got_into_water.connect(player.set.bind(&"is_underwater", true), CONNECT_REFERENCE_COUNTED)
	player.underwater.got_out_of_water.connect(player.set.bind(&"is_underwater", false), CONNECT_REFERENCE_COUNTED)


func _physics_process(delta: float) -> void:
	if player.get_tree().paused: return
	suit = node.suit
	config = suit.physics_config

	delta = player.get_physics_process_delta_time()
	# Control
	if !player.completed && !player.ignore_input: player.control_process()
	# Shape
	_shape_process()
	if player.warp != Player.Warp.NONE: return

	# Head
	_head_process()
	# Body
	_body_process()
	# Floor
	_floor_process()
	# Movement
	if player.debug_fly:
		_movement_debug(delta)
	if player.no_movement:
		return
	if player.is_climbing:
		_movement_climbing(delta)
	elif player.is_sliding:
		_movement_sliding(delta)
		_movement_y(delta)
	else:
		_movement_x(delta)
		_movement_y(delta)
	player.motion_process(delta)
	if !player.is_on_floor():
		player.coyote_time = move_toward(player.coyote_time, 0.0, delta)
	elif can_coyote:
		player.coyote_time = config.jump_coyote_time_sec
	if player.is_on_slope() && player.is_on_wall() && (player.get_which_wall_collided() == sign(player.left_right)):
		player.speed.x = 0


func _movement_debug(delta) -> void:
	var speed: float = 8
	var dir: Vector2 = Vector2(
		Input.get_axis(&"m_left", &"m_right"),
		Input.get_axis(&"m_up", &"m_down")
	)
	var extra: float = 4 * int(Input.is_action_pressed(&"m_extra")) + 1
	var run: int = 1 + int(Input.is_action_pressed(&"m_run"))

	var vel: Vector2 = speed * dir * run * extra
	player.position += vel


#= Movement
func _accelerate(to: float, acce: float, delta: float) -> void:
	player.speed.x = move_toward(player.speed.x, to * player.direction, abs(acce) * delta)


func _decelerate(dece: float, delta: float) -> void:
	_accelerate(0, dece, delta)


var _consistent_crouch_speed: bool

func _movement_x(delta: float) -> void:
	# Switch to sliding movement if slided on a slope
	if player.slided:
		#var do_slide = true if \
		#	suit.physics_crouchable else true if player.left_right == 0 else false
		#if do_slide:
			if _start_sliding_movement(true):
				return
	_movement_x_recovery(delta)
	player.is_able_to_skid = false
	
	if player.is_on_floor():
		player.crouch_forced = player.is_crouching && player._crouch_jump_tweak
		if _consistent_crouch_speed:
			_consistent_crouch_speed = false
			if player.crouch_forced && sign(player.left_right) != -player.direction:
				return
	
	# Crouching / Completed Level motion speed
	if (player.is_crouching && player.is_on_floor()) || player.left_right == 0 || player.completed:
		player.is_skidding = false
		if !player.crouch_forced || player.is_on_floor():
			var deceleration: float = (
				config.walk_crouch_deceleration if (
					(player.is_crouching && player.is_on_floor()) && player.left_right != player.direction
				) else config.walk_deceleration
			)
			_decelerate(deceleration, delta)
		return
	
	_movement_x_acceleration(delta)
	
	_consistent_crouch_speed = sign(player.left_right) != -player.direction
	
	# Initial speed
	if abs(player.speed.x) < config.walk_initial_speed:
		if (player.left_right > 0 && player.speed.x >= -1) || (player.left_right < 0 && player.speed.x <= 1):
			player.direction = sign(player.left_right)
			player.speed.x = player.direction * config.walk_initial_speed
			#player.is_skidding = false
	
	if abs(player.speed.x) > 100 || player.is_skidding:
		player.is_able_to_skid = true
	
	player.is_skidding = (
			player._skid_tweak &&
			(sign(player.left_right) == -player.direction) &&
			abs(player.speed.x) > 1 &&
			player.is_on_floor() &&
			!player.is_holding &&
			player.is_able_to_skid
	)


func _movement_x_acceleration(delta: float) -> void:
	# Acceleration
	var max_speed: float
	if sign(player.left_right) == player.direction:
		if player.running && !player.crouch_forced:
			max_speed = (
				config.underwater_walk_max_running_speed if player.is_underwater else \
				config.walk_max_running_speed
			)
		else:
			max_speed = (
				config.underwater_walk_max_walking_speed if player.is_underwater else \
				config.walk_max_walking_speed
			)
		
		if (!player.crouch_forced || player.is_on_floor()) || (player.crouch_forced && abs(player.speed.x) < max_speed):
			_accelerate(max_speed * abs(player.left_right), config.walk_acceleration, delta)
			
	# Deceleration upon changing direction
	elif sign(player.left_right) == -player.direction:
		_decelerate(config.walk_turning_acce, delta)
		if abs(player.speed.x) < 1:
			player.direction *= -1
	if abs(player.speed.x) > max_speed && sign(player.left_right) != -player.direction && player.is_underwater:
		_decelerate(config.walk_turning_acce, delta)


func _movement_x_recovery(delta: float) -> void:
	# Recovery if Super Mario has their head stuck in blocks
	if !player.is_crouching && player.has_stuck:
		player.left_right = 0
		#player.jumping = 0
		if player.is_on_floor():
			player.speed.x = -player.direction * config.stuck_recovery_speed
			if player.get_which_wall_collided() == -player.direction:
				player.direction *= -1
	# Smoothly go out from recovery process
	if player.has_stuck_animation:
		var unstuck_dir: int = int(player.stuck_block_left) - int(player.stuck_block_right)
		if unstuck_dir == 0: unstuck_dir = -player.direction
		player.speed.x = unstuck_dir * config.stuck_recovery_speed
		if player.get_which_wall_collided() == unstuck_dir:
			player.direction *= -1
	else:
		player.stuck_block_left = false
		player.stuck_block_right = false


func _movement_y(delta: float) -> void:
	if player.is_crouching && !player.crouch_forced && !ProjectSettings.get_setting("application/thunder_settings/player/jumpable_when_crouching", false):
		return
	if player.completed:
		if player.crouch_forced && !player.is_on_floor():
			player.is_crouching = false
			player.crouch_forced = false
		return

	# Swimming
	if player.is_underwater:
		player.crouch_forced = false
		if player.jumped && (player.up_down <= 0 || player._crouch_jump_tweak):
			player.coyote_time = 0.0
			player.jump(config.swim_out_speed if player.is_underwater_out else config.swim_speed)
			player._has_jumped = true
			player.swam.emit()
			var _sndfx: AudioStream = config.sound_swim[randi_range(0, len(config.sound_swim) - 1)]
			Audio.play_sound(_sndfx, player, false, {pitch = suit.sound_pitch})
		if player.speed.y < -abs(config.swim_max_speed) && !player.is_underwater_out:
			player.speed.y = lerp(player.speed.y, -abs(config.swim_max_speed), 0.125)
	# Jumping
	else:
		if (player.is_on_floor() || player.coyote_time > 0.0) && (player.up_down <= 0 || player._crouch_jump_tweak):
			if player.jumping > 0 && !player._has_jumped:
				_stop_sliding_movement()
				player._has_jumped = true
				player.coyote_time = 0.0
				player.ghost_speed_y = 0.0
				player.jump(config.jump_speed)
				if player.is_crouching && player._crouch_jump_tweak:
					player.crouch_forced = player.up_down > 0
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


func _calculate_jump_acceleration() -> float:
	return config.jump_buff_dynamic if (abs(player.speed.x) > 50 && !player.is_on_wall()) else config.jump_buff_static

#= Climbing
func _movement_climbing(delta: float) -> void:
	if (player.is_crouching && !player.crouch_forced) || player.completed: return
	if player.is_sliding: _stop_sliding_movement()
	player.vel_set(Vector2(player.left_right, player.up_down) * suit.physics_config.climb_speed)
	if player.left_right != 0:
		player.direction = sign(player.left_right)
	# Resist to gravity
	player.speed -= player.gravity_dir * player.gravity_scale * GravityBody2D.GRAVITY * delta * 0.5

	# Jump from climbing
	if player.jumping > 0 && !player._has_jumped && player.up_down == 0:
		player._has_jumped = true
		player.is_climbing = false
		if sign(player.left_right) != 0:
			player.direction = sign(player.left_right)
		player.jump(config.jump_speed)
		var _sndfx: AudioStream = config.sound_jump[randi_range(0, len(config.sound_jump) - 1)]
		Audio.play_sound(_sndfx, player, false, {pitch = suit.sound_pitch})


#= Sliding from slopes
func _movement_sliding(delta: float) -> void:
	if player.completed: return
	var floor_normal: float = rad_to_deg(player.get_floor_normal().x)
	var dir: bool = player.direction == 1
	# Acceleration
	var accel: Callable = func(_norm: float) -> void:
		_accelerate(config.slide_max_speed, (config.slide_acceleration / 50) * _norm, delta)
		player.is_sliding_accelerating = true
	# Deceleration
	var decel: Callable = func(_norm: float) -> void:
		_decelerate((config.walk_deceleration / 50) * _norm, delta)
		player.is_sliding_accelerating = false
	
	if player.up_down <= 0:
		player.crouch_forced = player.is_crouching && player._crouch_jump_tweak

	# Sliding towards right
	if floor_normal >= 10.0:
		@warning_ignore("standalone_ternary")
		accel.call(abs(floor_normal)) if dir else decel.call(abs(floor_normal) * 2)
		if player.get_which_wall_collided() > 0:
			_stop_sliding_movement()
			return
		if abs(player.speed.x) < 1: _start_sliding_movement(false)
	# Sliding towards left
	elif floor_normal <= -10.0:
		@warning_ignore("standalone_ternary")
		accel.call(abs(floor_normal)) if !dir else decel.call(abs(floor_normal) * 2)
		if player.get_which_wall_collided() < 0:
			_stop_sliding_movement()
			return
		if abs(player.speed.x) < 1: _start_sliding_movement(false)
	# Momentum on flat surface after sliding
	else:
		decel.call(50)
		if abs(player.speed.x) < 1 || player.left_right != 0:
			_stop_sliding_movement()
	
	if player.up_down > 0:
		return
	if (player.left_right != 0
		&& (
			(sign(player.left_right) != player.direction && player.up_down > 0) || player.up_down == 0
		)
		|| player.up_down < 0
	):
		_stop_sliding_movement()


func _start_sliding_movement(do_initial_push: bool = true) -> bool:
	if player.is_holding: return false
	var floor_norm = rad_to_deg(player.get_floor_normal().x)
	var _initial_push: float = config.walk_initial_speed if do_initial_push else 1.0
	if floor_norm <= -40.0 + (int(!do_initial_push) * 30):
		if abs(player.speed.x) < _initial_push:
			if player.test_move(player.transform, Vector2.LEFT.rotated(player.global_rotation)):
				_stop_sliding_movement()
				return false
			player.direction = -1
			player.speed.x = -_initial_push
	if floor_norm >= 40.0 - (int(!do_initial_push) * 30):
		if abs(player.speed.x) < _initial_push:
			if player.test_move(player.transform, Vector2.RIGHT.rotated(player.global_rotation)):
				_stop_sliding_movement()
				return false
			player.direction = 1
			player.speed.x = _initial_push
	
	player.attack.killing_detection_scale = 2
	player.attack.enabled = true
	player.is_sliding = true
	return true


func _stop_sliding_movement() -> void:
	player.is_sliding = false
	player.is_sliding_accelerating = false
	player.attack.enabled = player.is_starman()
	if !player.is_starman(): player.starman_combo.reset_combo()
	player.attack.killing_detection_scale = 2


#= Shape
func _shape_process() -> void:
	var crouch_shape: bool = (
		player.is_crouching &&
		player.warp == Player.Warp.NONE
	)
	var shaper: Shaper2D = (
		suit.physics_shaper_crouch if crouch_shape else suit.physics_shaper
	)
	if !shaper: return
	
	var has_previously_stuck: bool = player.has_stuck
	var is_colliding: bool
	var is_colliding_in_advance: bool = _shape_recovery_process(false)
	
	player.has_stuck = is_colliding_in_advance
	if !player.has_stuck && (player.has_stuck_animation || has_previously_stuck):
		if player.is_crouching:
			is_colliding = false
		else:
			is_colliding = _shape_recovery_process(true)
		player.has_stuck_animation = is_colliding
		if !is_colliding:
			player.stuck_block_left = false
			player.stuck_block_right = false
			if !player.is_crouching:
				if (player.left_right >= 0 && player.speed.x < -1) || (player.left_right <= 0 && player.speed.x > 1):
					player.speed.x = 0
		else:
			if player.stuck_block_left && player.left_right < 0: player.left_right = 0
			if player.stuck_block_right && player.left_right > 0: player.left_right = 0
	if player.has_stuck || player.has_stuck_animation:
		shaper = suit.physics_shaper_crouch
	
	shaper.install_shape_for(player.collision_shape)
	shaper.install_shape_for_caster(player.body)
	shaper.install_shape_for_caster(player.attack)
	
	if player.collision_shape.shape is RectangleShape2D:
		player.head.position.y = player.collision_shape.position.y - player.collision_shape.shape.size.y / 2 - 2


func _shape_recovery_process(precise: bool = false) -> bool:
	if player.warp != Player.Warp.NONE || player.completed:
		return false

	var raycast: RayCast2D = player.collision_recovery
	var loop_calls: int = 1 + int(precise)
	raycast.position = suit.physics_shaper.shape_pos
	raycast.target_position.y = (
		-suit.physics_shaper.shape.size.y + 16 - suit.physics_shaper.shape_pos.y
	)
	
	var is_colliding: Array[bool]
	is_colliding.resize(loop_calls)
	is_colliding.fill(false)
	for index in loop_calls:
		if precise:
			if index == 0:
				raycast.position.x = suit.physics_shaper.shape_pos.x - (suit.physics_shaper.shape.size.x / 2)
			else:
				raycast.position.x = suit.physics_shaper.shape_pos.x + (suit.physics_shaper.shape.size.x / 2)
		raycast.force_raycast_update()
		var collider = raycast.get_collider()
		if collider is TileMap:
			var cell: Vector2i = collider.get_coords_for_body_rid(raycast.get_collider_rid())
			var layer = collider.get_layer_for_body_rid(raycast.get_collider_rid())
			var tile_data: TileData = collider.get_cell_tile_data(layer, cell)
			if tile_data:
				var phys_layer = collider.tile_set.get_physics_layers_count()
				for i in phys_layer:
					for j in tile_data.get_collision_polygons_count(i):
						if !tile_data.is_collision_polygon_one_way(i, j):
							is_colliding[index] = true
							break
		elif collider is TileMapLayer:
			var cell: Vector2i = collider.get_coords_for_body_rid(raycast.get_collider_rid())
			var tile_data: TileData = collider.get_cell_tile_data(cell)
			if tile_data:
				var phys_layer = collider.tile_set.get_physics_layers_count()
				for i in phys_layer:
					for j in tile_data.get_collision_polygons_count(i):
						if !tile_data.is_collision_polygon_one_way(i, j):
							is_colliding[index] = true
							break
		elif collider is CollisionObject2D:
			var i = raycast.get_collider_shape()
			if !collider.is_shape_owner_one_way_collision_enabled(i):
				is_colliding[index] = true
		else:
			is_colliding[index] = raycast.is_colliding()
	
	if precise:
		player.stuck_block_left = is_colliding.front()
		player.stuck_block_right = is_colliding.back()
	
	return true in is_colliding

var _head_signal_cooldown: int = 0
#= Head
func _head_process() -> void:
	player.is_underwater_out = true
	var _on_cooldown: bool = _head_signal_cooldown > 0
	_head_signal_cooldown -= 1

	# Hit block
	for i in player.head.get_collision_count():
		var collider: Node2D = player.head.get_collider(i) as Node2D
		if !collider: continue
		# Water
		if collider.is_in_group(&"#water"):
			player.is_underwater_out = false
			if player.bubbler.is_stopped():
				player.bubbler.start()
		elif player.is_on_ceiling() && !(player.is_crouching && player.is_on_floor()) && !_on_cooldown:
			player.head_bumped.emit()
			_head_signal_cooldown = player.HEAD_SIGNAL_COOLDOWN
		
		# Bumpable Block
		if !player._crouch_jump_tweak && player.is_crouching && player.is_on_floor() && \
			collider is StaticBumpingBlock && collider.has_method(&"got_bumped") && !_on_cooldown:
				collider.got_bumped.call_deferred(true)
				_head_signal_cooldown = player.HEAD_SIGNAL_COOLDOWN
	
	player.bubbler.paused = player.is_underwater_out
	
	if !player.is_on_ceiling(): return
	
	_process_collision_deferred(-1, _on_cooldown)

func _process_collision_deferred(_dir: int, _on_cooldown: bool) -> void:
	# Patch for doubled detections, which happens if you hold against a wall and try to bump a brick
	if _on_cooldown: return
	var max_multiple_breaking_blocks: int = 4
	
	var rot: = player.get_global_gravity_dir().angle()
	var vel = Vector2(0, _dir).rotated(rot - PI/2)
	if is_zero_approx(vel.x):
		vel.x = 0
	
	# WARNING: Only the first collision shape will be considered!
	var query := PhysicsShapeQueryParameters2D.new()
	query.collision_mask = player.collision_mask
	query.motion = vel
	
	var _already_processed: Array[int]
	
	for i in player.get_shape_owners():
		query.transform = (player.shape_owner_get_owner(i) as Node2D).global_transform
		for j in player.shape_owner_get_shape_count(i):
			query.shape = player.shape_owner_get_shape(i, j)
			
			var cldata: Array[Dictionary] = player.get_world_2d().direct_space_state.intersect_shape(query, max_multiple_breaking_blocks)
			
			for k in cldata:
				var l: Object = k.get(&"collider", null)
				var id: int = k.get(&"collider_id", 0)
				
				if !(id in _already_processed):
					_already_processed.append(id)
					if l is StaticBumpingBlock && l.has_method(&"got_bumped"):
						l.got_bumped.call_deferred(true)
						_head_signal_cooldown = player.HEAD_SIGNAL_COOLDOWN


#= Body
func _body_process() -> void:
	if !player.body.shape: return

	var player_velocity = player.velocity.normalized()

	for i in player.body.get_collision_count():
		var collider: Node2D = player.body.get_collider(i) as Node2D
		if !is_instance_valid(collider):
			continue
		if !collider.has_node("EnemyAttacked"): continue

		var enemy_attacked: Node = collider.get_node("EnemyAttacked")
		var result: Dictionary = enemy_attacked.got_stomped(player, player_velocity)
		if result.is_empty(): return
		if result.result == true:
			var _final_speed_y: float
			if player.jumping > 0:
				_final_speed_y = -result.jumping_max * config.jump_stomp_multiplicator
			else:
				_final_speed_y = -result.jumping_min * config.jump_stomp_multiplicator
			
			if player._super_jump_tweak && player.is_on_floor():
				if player.ghost_speed_y < 0.0:
					return
				player.ghost_speed_y = _final_speed_y
			else:
				player.coyote_time = 0.0
				player.speed.y = _final_speed_y

		else:
			player.hurt(enemy_attacked.get_meta(&"stomp_tags", {}))

#= Floor
func _floor_process() -> void:
	# We process landing on things here
	# If we land on something and function "_player_landed" exists there, we call it.

	if !is_instance_valid(player): return
	if !player.is_on_floor(): return
	
	for i in player.get_slide_collision_count():
		var collision: KinematicCollision2D = player.get_slide_collision(i)
		if !collision: continue
		
		var collider = collision.get_collider()
		if !is_instance_valid(collider): continue
		
		#if collider is TileMapLayer && collider.tile_set:
			#_process_custom_tile_data(collider, collision)
		
		if collider.has_method('_player_landed'):
			collider._player_landed(player)
		

#func _process_custom_tile_data(tile: TileMapLayer, kc: KinematicCollision2D) -> void:
	#var custom_data_arr: PackedStringArray = [
		#"slippery"
	#]
	#var has_data: bool
	#for i in tile.tile_set.get_custom_data_layers_count():
		#if custom_data_arr.has(tile.tile_set.get_custom_data_layer_name(i)):
			#has_data = true
	#if !has_data: return
	#
	#var coord: Vector2i = tile.get_coords_for_body_rid(kc.get_collider_rid())
	#var tile_data: TileData = tile.get_cell_tile_data(coord)
	#if !tile_data: return
	#
	#for data_name in custom_data_arr:
		#var _custom_data = tile_data.get_custom_data(data_name)
		#if data_name == custom_data_arr[0]:
			#if _custom_data:
				#player.slippery_strength = _custom_data
		#else:
			#return
