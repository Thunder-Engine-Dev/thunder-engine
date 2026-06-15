@tool
extends "res://engine/objects/enemies/thwomp/scripts/thwomp.gd"

const ICICLE = preload("res://engine/objects/enemies/thwomp/thwomp_icicle.tscn")

@onready var left_icicle: Marker2D = $LeftIcicle
@onready var right_icicle: Marker2D = $RightIcicle


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	match _step:
		# Waiting
		0:
			var player: Player = Thunder._current_player
			if !player:
				return
			var ppos: Vector2 = global_transform.affine_inverse() * player.global_position
			if trigger_area.has_point(ppos):
				_origin = global_position
				_step = 1
				timer_destroy.start()
		# Stunning
		1:
			_vel = velocity.normalized()
			motion_process(delta)
			var ray_cast_target = Vector2(0, 4) + (speed * delta * 2).rotated(-global_rotation)
			left_explosion.target_position = ray_cast_target
			right_explosion.target_position = ray_cast_target
			
			if is_on_floor():
				# Breaks Brick
				var bricks: bool
				for i in get_slide_collision_count():
					var collider: Node = get_slide_collision(i).get_collider()
					if collider is StaticBumpingBlock && collider.has_method(&"got_bumped"):
						collider.got_bumped(false)
						if collider.has_method(&"bricks_break"):
							bricks = true
				# Non-stop for the thwomp who broke the bricks
				if bricks:
					_explosion()
					timer_destroy.start()
					return
				# Stops if stunning on the ground
				_stun()
				return
			else:
				var col: bool = false
				var bricks: bool = true
				if left_explosion.is_colliding():
					var collider = left_explosion.get_collider()
					if is_instance_valid(collider) && collider.has_method(&"got_bumped"):
						collider.got_bumped(false)
						if !collider.has_method(&"bricks_break"):
							bricks = false
						col = true
				if right_explosion.is_colliding():
					var collider2 = right_explosion.get_collider()
					if is_instance_valid(collider2) && collider2.has_method(&"got_bumped"):
						collider2.got_bumped(false)
						if !collider2.has_method(&"bricks_break"):
							bricks = false
						col = true
				if col:
					if bricks:
						motion_process(1)
						_explosion()
						timer_destroy.start()
						return
					_step = 2
					_stun.call_deferred()
		# Rising
		3:
			#velocity = -_vel * rising_speed
			velocity = global_position.direction_to(_origin) * rising_speed
			do_movement(delta)
			if (_origin - global_position).dot(_origin - _stunspot) <= 0 && global_position.distance_squared_to(_origin) <= 50 * delta:
				velocity = Vector2.ZERO
				speed = velocity
				global_position = _origin
				_stunspot = Vector2.ZERO
				_vel = Vector2.ZERO
				_step = 0


func _stun() -> void:
	_step = 2
	stun.emit()
	timer_destroy.stop()
	var _sfx = CharacterManager.get_sound_replace(stunning_sound, stunning_sound, "stun", false)
	Audio.play_sound(_sfx, self)
	motion_process(1)
	_explosion()
	if Thunder._current_camera.has_method(&"shock"):
		Thunder._current_camera.shock(0.2, Vector2.ONE * 4)
	_stunspot = global_position
	timer_waiting.start(waiting_time)


func _explosion() -> void:
	super()
	NodeCreator.prepare_2d(ICICLE, self).bind_global_transform(left_icicle.position).create_2d(true).call_method(
		func(eff: Node2D) -> void:
			eff.dir = -1
	)
	NodeCreator.prepare_2d(ICICLE, self).bind_global_transform(right_icicle.position).create_2d(true).call_method(
		func(eff: Node2D) -> void:
			eff.dir = 1
	)
