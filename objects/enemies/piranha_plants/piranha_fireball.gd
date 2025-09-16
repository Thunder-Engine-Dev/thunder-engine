extends ByNodeScript

# You need these vars in custom_var of piranha:
#	attack_interval: float,
#	attack_thrower: InstanceNode2D,
#	attack_amount: int,
#	attack_times: int,
#	attack_sound: AudioStream,
#	projectile_collision: bool
#	projectile_speed_min: Vector2
#	projectile_speed_max: Vector2
#	projectile_gravity_scale: float

var attacked_times:int

var timer_fire:Timer


func _ready() -> void:
	node.stretched_out.connect(
		func() -> void:
			if !timer_fire: return
			timer_fire.start(vars.attack_interval)
			attacked_times = vars.attack_times
	)
	
	timer_fire = node.get_node_or_null(^"Fire")
	if !timer_fire: return
	timer_fire.timeout.connect(_shoot)


func _shoot() -> void:
	if attacked_times <= 0: return
	
	attacked_times -= 1
	
	for i in vars.attack_amount:
		NodeCreator.prepare_ins_2d(vars.attack_thrower, node).call_method(func(ball: Node2D) -> void:
			if ball is GravityBody2D:
				var speed_corrected: Vector2 = Vector2.ONE
				if vars.projectile_speed_correction:
					speed_corrected.x = cos(node.rotation) / 2 + 0.5
					speed_corrected.y = cos(node.rotation) / 4 + 0.75
				
				var ball_speed: Vector2
				if vars.get("projectile_integer_speed", false):
					ball_speed = Vector2(
						Thunder.rng.get_randi_range(
							floori(vars.projectile_speed_min.x / 50),
							floori(vars.projectile_speed_max.x / 50),
						),
						Thunder.rng.get_randi_range(
							floori((vars.projectile_speed_min.y * speed_corrected.x) / 50),
							floori((vars.projectile_speed_max.y * speed_corrected.y) / 50)
						),
					) * 50
				else:
					ball_speed = Vector2(
						Thunder.rng.get_randf_range(
							vars.projectile_speed_min.x,
							vars.projectile_speed_max.x
						),
						Thunder.rng.get_randf_range(
							vars.projectile_speed_min.y * speed_corrected.x,
							vars.projectile_speed_max.y * speed_corrected.y
						),
					)
				
				ball.rotation = 0.0
				ball.speed = ball_speed.rotated(node.rotation)
				ball.gravity_scale = vars.projectile_gravity_scale
			
			if &"belongs_to" in ball: ball.belongs_to = Data.PROJECTILE_BELONGS.ENEMY
			
			if !vars.projectile_collision && ball is CollisionObject2D:
				ball.set_collision_mask_value(7, false)
			
			if &"vision" in ball:
				ball.expand_vision(Vector2(8, 8))
			if "projectile_offscreen_time" in vars && "remove_offscreen_after" in ball:
				ball.remove_offscreen_after = vars.projectile_offscreen_time
			if "projectile_remove_from_top" in vars && "remove_top_offscreen" in ball:
				ball.remove_top_offscreen = vars.projectile_remove_from_top
		).create_2d()
	
	Audio.play_sound(vars.attack_sound, node, false)
	
	timer_fire.start(vars.attack_interval)
