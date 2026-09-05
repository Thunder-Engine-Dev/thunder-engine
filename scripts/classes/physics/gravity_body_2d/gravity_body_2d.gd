@icon("./gravity_body_2d.svg")
extends CorrectedCharacterBody2D
class_name GravityBody2D

## Very useful [CorrectedCharacterBody2D] with easy-call [method motion_process] method to achieve
## calculations of gravity and slide collision.

# NOTE
# Gravity acceleration is now located in ProjectSettings.
# See "physics/2d/default_gravity"
# Default value: 2500.0
## DEPRECATED: prefer [method get_gravity_vector] / ProjectSettings [code]physics/2d/default_gravity[/code]
const GRAVITY: float = 2500.0

@export_group("Speed")
## The velocity of the body. [color=gold][b]This is related to the body's[/b][/color] [member Node2D.global_rotation]
@export var speed: Vector2: # Not the scaler "speed", but the vector "velocity" affected by gravity direction
	set(value):
		velocity = value.rotated(get_global_gravity_dir().angle() - PI/2)
	get:
		return velocity.rotated(-get_global_gravity_dir().angle() + PI/2)
@export_group("Gravity")
## If [code]true[/code], rotates project/Area2D gravity by [member Node2D.global_rotation]
## (ceiling-walking without an Area2D). Set [code]false[/code] when Area2D already supplies world gravity.
@export var gravity_dir_rotation: bool = true
## Multiplier for gravity acceleration from [method get_gravity_vector]
@export var gravity_scale: float
## Defines maximum of speed.y affected by gravity
@export_range(0, 100000, 0.1) var max_falling_speed: float
@export_group("Collision")
## Defines if the body enables collision. For those who don't need any collision, it's recommended to set this value to [code]false[/code]
## to acquire more performance
@export var collision: bool = true
@export_group("Up Direction")
## If [code]true[/code], calling [method motion_process] will update [member CharacterBody2D.up_direction].
@export var auto_update_up_direction: bool = true

## [member speed] in previous frame, useful for calculations of delta position
var speed_previous: Vector2
## [member transform] before it gets changed in the current physics frame.
var global_transform_previous: Transform2D

## Optional world-space gravity direction lock (e.g. death effects with collision_layer 0
## that cannot receive Area2D gravity). Assign via [member gravity_dir]. Zero = use physics.
var _gravity_dir_override: Vector2 = Vector2.ZERO
## When true, skip the on-floor [member speed].y stick until the next [method do_movement]
## that actually slides (call [method invalidate_collision_state] after an external teleport).
var _collision_state_invalid: bool = false

## Effective gravity direction. Assigning sets a world-space override (no Area2D needed).
## Reading returns [method get_global_gravity_dir].
var gravity_dir: Vector2:
	set(value):
		_gravity_dir_override = value.normalized() if !value.is_zero_approx() else Vector2.ZERO
	get:
		return get_global_gravity_dir()

## Emitted when any kind of collision happens
signal collided
## Emitted when the body collides with a wall
signal collided_wall
## Emitted when the body collides with the ceiling
signal collided_ceiling
## Emitted when the body collides with the floor
signal collided_floor
## Emitted at the start of [method motion_process], before gravity and [method do_movement].
signal before_motion(delta: float)
## Emitted at the end of [method motion_process], after [method do_movement].
signal after_motion(delta: float)


## Main method to make the body move with both gravity and collision(if [member collision] is [code]true[/code]),
## This will automatically call [method do_movement][br]
## [param delta] should be the one from [method Node._phyiscs_process][br]
## [param slide] makes the body fly from sloping-up[br]
func motion_process(delta: float, slide: bool = false) -> void:
	before_motion.emit(delta)
	
	# Fall along local +Y (speed is gravity-local); magnitude from project/area gravity.
	var gravity_accel: float = gravity_scale * get_gravity_vector().length()
	
	speed_previous = speed
	global_transform_previous = global_transform
	
	speed.y += gravity_accel * delta * 0.5
	
	var is_speed_capped: bool
	if max_falling_speed > 0 && speed.y > max_falling_speed:
		speed.y = max_falling_speed
		is_speed_capped = true
	
	if auto_update_up_direction:
		update_up_direction()
	
	floor_block_on_wall = !slide
	
	do_movement(delta, slide, false)
	
	if !is_speed_capped:
		speed.y += gravity_accel * delta * 0.5
	
	if slide && floor_constant_speed && !is_on_wall():
		speed.x = speed_previous.x
	
	after_motion.emit(delta)
	_collision_signals()


## Direct method to process the body move with both gravity and collision (if [member collision] is [code]true[/code])[br]
## [param delta] should be the one from [method Node._physics_process][br]
## [param slide] makes the body fly from sloping-up[br]
## [param emit_detection_signal] makes the body emit [b]collision*[b] signals if collision happens[br]
func do_movement(delta: float, slide: bool = false, emit_detection_signal: bool = true) -> void:
	if velocity.is_equal_approx(Vector2.ZERO): return
	
	if !collision:
		global_position += velocity * delta
		return
		
	if !_collision_state_invalid && is_on_floor() && speed.y > 0: # fix enemies turning around corners randomly
		speed.y = 1
	
	if correct_collision:
		move_and_slide_corrected()
	else:
		move_and_slide()
	
	_collision_state_invalid = false
	
	if slide:
		velocity = get_real_velocity()
	
	if !emit_detection_signal: return
	_collision_signals()


func _collision_signals() -> void:
	if is_on_wall():
		collided.emit()
		collided_wall.emit()
	if is_on_ceiling():
		collided.emit()
		collided_ceiling.emit()
	if is_on_floor():
		collided.emit()
		collided_floor.emit()


# Some useful functions
## Accelerate [member speed] to a certain [Vector2] with acceleration
func accelerate(to: Vector2, a: float) -> void:
	speed = speed.move_toward(to, a)


## Accelerate [member speed].x to a certain value with acceleration
func accelerate_x(to: float, a: float) -> void:
	speed.x = move_toward(speed.x, to, a)


## Accelerate [member speed].y to a certain value with acceleration
func accelerate_y(to: float, a: float) -> void:
	speed.y = move_toward(speed.y, to, a)


## Reverse [member speed].x
func turn_x() -> void:
	if is_zero_approx(speed_previous.x):
		speed.x *= -1
		return
	speed_previous.x *= -1
	speed.x = speed_previous.x
	#if impulse_move_on_turn_x && !is_zero_approx(speed.x):
	#	do_movement(get_physics_process_delta_time(), false, true)


## Reverse [member speed].y
func turn_y() -> void:
	if is_zero_approx(speed_previous.y):
		speed.y *= -1
		return
	speed_previous.y *= -1
	speed.y = speed_previous.y
	#if impulse_move_on_turn_y && !is_zero_approx(speed.y):
	#	do_movement(get_physics_process_delta_time(), false, true)


## Jump. No matter if [code]jumping_speed[/code] is positive or negative, it will always be negative(upwards)
func jump(jumping_speed: float) -> void:
	speed.y = -abs(jumping_speed)


## Set [member speed] to a new [Vector2]
func vel_set(vel: Vector2) -> void:
	speed = vel


## Set [member speed].x to a new value
func vel_set_x(velx: float) -> void:
	speed.x = velx


## Set [member speed].y to a new value
func vel_set_y(vely: float) -> void:
	speed.y = vely


## Notify the body with certain type(s) of collision and make it stop according to the related notify/notifies)
func stop_notify(wall_notify:bool = true, ceiling_notify:bool = true, floor_notify:bool = true) -> void:
	if wall_notify && is_on_wall() && speed.x != 0: speed.x = 0
	if ceiling_notify && is_on_ceiling() && speed.y < 0 && !slide_on_ceiling: speed.y = 0
	if floor_notify && is_on_floor() && speed.y > 0 && !floor_stop_on_slope: speed.y = 0


# Getters
## World-space gravity vector. Safe when physics state is missing (export init, deferred spawn).
func get_gravity_vector() -> Vector2:
	if is_inside_tree():
		var space := PhysicsServer2D.body_get_space(get_rid())
		if space.is_valid():
			var g := get_gravity()
			if !g.is_zero_approx():
				return g
	var dir: Vector2 = ProjectSettings.get_setting(&"physics/2d/default_gravity_vector", Vector2(0, 1))
	var amount: float = float(ProjectSettings.get_setting(&"physics/2d/default_gravity", GRAVITY))
	if dir.is_zero_approx():
		dir = Vector2.DOWN
	return dir.normalized() * amount


## Gravity direction for [member speed] ↔ velocity.
## Uses [method get_gravity_vector] (project + Area2Ds), optionally rotated by body;
## or [member gravity_dir] override when set.
func get_global_gravity_dir() -> Vector2:
	if !_gravity_dir_override.is_zero_approx():
		return _gravity_dir_override
	var g := get_gravity_vector()
	var dir := Vector2.DOWN if g.is_zero_approx() else g.normalized()
	return dir.rotated(global_rotation) if gravity_dir_rotation else dir


## Clear a [member gravity_dir] override and return to live physics gravity.
func clear_gravity_dir_override() -> void:
	_gravity_dir_override = Vector2.ZERO


## Discard leftover floor/wall/ceiling state after an external teleport.
## Skips the on-floor [member speed].y stick until the next real [method do_movement].
func invalidate_collision_state() -> void:
	_collision_state_invalid = true


## -1 is Left, 1 is Right, 0 is None
func get_which_wall_collided() -> int:
	if !is_on_wall():
		return 0
	var _c: Vector2 = get_wall_normal()
	return -sign(_c.x)


# Updaters
## Update [member up_direction] to suit certain current situation
func update_up_direction() -> void:
	up_direction = -get_global_gravity_dir()


# Is-methods
## To check if the body is standing on a slope
func is_on_slope() -> bool:
	var dot: float = get_floor_normal().dot(get_global_gravity_dir())
	return dot < 0 && !is_equal_approx(dot, -1)


## To check if the body is able to slope down
func is_able_slope_down() -> bool:
	return !floor_stop_on_slope && !is_on_wall() && is_on_slope()
