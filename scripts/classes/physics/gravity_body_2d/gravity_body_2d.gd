@icon("./gravity_body_2d.svg")
extends CorrectedCharacterBody2D
class_name GravityBody2D

## Very useful [CorrectedCharacterBody2D] with easy-call [method motion_process] method to achieve calculations of gravity and slide collsion.
##
##

## Default gravity acceleration
const GRAVITY: float = 2500.0

@export_group("Speed")
## The velocity of the body. [color=gold][b]This is related to the bodie's[/b][/color] [member Node2D.global_rotation]
@export var speed: Vector2: # Not the scaler "speed", but the vector "velocity" affected by gravity_dir
	set(value):
		velocity = value.rotated(gravity_dir.angle() - PI/2)
	get:
		return velocity.rotated(-gravity_dir.angle() + PI/2)
@export_group("Gravity")
## The gravity_direction of the body, with length always [code]1.0[/code][br]
## [color=gold][b]This is related to the bodie's[/b][/color] [member Node2D.global_rotation] if [member gravity_dir_rotation] is [code]true[/code]
@export var gravity_dir: Vector2 = Vector2.DOWN
## Defines whether the returned value of [method get_global_gravity_dir] equals [member gravity_dir] following the bodie's [member Node2D.global_rotation] or not
@export var gravity_dir_rotation: bool = true
## Defines the scale of [member GRAVITY], then the gravity acceleration = [member GRAVITY] * [member gravity_scale]
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
@export_group("Turning")
@export var impulse_move_on_turn_x: bool = true
@export var impulse_move_on_turn_y: bool = false

## [member speed] in previous frame, useful for calculations of delta position
var speed_previous: Vector2

@onready var _up_temp: Vector2 = up_direction

## Emitted when any kind of collision happens
signal collided
## Emitted when the body collides with a wall
signal collided_wall
## Emitted when the body collides with the ceiling
signal collided_ceiling
## Emitted when the body collides with the floor
signal collided_floor


## Main method to make the body move with both gravity and collision(if [member collsion] is [code]true[/code]),
## This will automatically call [method do_movement][br]
## [param delta] should be the one from [method Node._phyiscs_process][br]
## [param slide] makes the body fly from sloping-up[br]
func motion_process(delta: float, slide: bool = false) -> void:
	var gravity: float = gravity_scale * GRAVITY
	
	speed_previous = speed
	
	speed += gravity * gravity_dir * delta * 0.5
	#speed += gravity * gravity_dir * delta
	var is_speed_capped: bool
	if max_falling_speed > 0 && speed.y > max_falling_speed:
		speed.y = max_falling_speed
		is_speed_capped = true
	
	if auto_update_up_direction:
		update_up_direction()
	
	do_movement(delta, slide, false)
	
	if !is_speed_capped:
		speed += gravity * gravity_dir * delta * 0.5
	
	if slide && floor_constant_speed && !is_on_wall():
		speed.x = speed_previous.x
	
	_collision_signals()


## Direct method to process the body move with both gravity and collision(if [member collsion] is [code]true[/code])[br]
## [param delta] should be the one from [method Node._phyiscs_process][br]
## [param slide] makes the body fly from sloping-up[br]
## [param emit_detection_signal] makes the body emit [b]collision*[b] signals if collision happens[br]
func do_movement(delta: float, slide: bool = false, emit_detection_signal: bool = true) -> void:
	if velocity.is_equal_approx(Vector2.ZERO): return
	
	if !collision:
		global_position += velocity * delta
		return
		
	if is_on_floor() && velocity.y > 0: # fix enemies turning around corners randomly
		velocity.y = 1
	
	if correct_collision:
		move_and_slide_corrected()
	else:
		move_and_slide()
	
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
	if speed_previous.x == 0:
		speed.x *= -1
		return
	speed_previous.x *= -1
	speed.x = speed_previous.x
	if impulse_move_on_turn_x:
		do_movement(get_physics_process_delta_time(), false, false)


## Reverse [member speed].y
func turn_y() -> void:
	if speed_previous.y == 0:
		speed.y *= -1
		return
	speed_previous.y *= -1
	speed.y = speed_previous.y
	if impulse_move_on_turn_y:
		do_movement(get_physics_process_delta_time(), false, false)


## Jump. No matter if [code]jumping_speed[/code] is positive or negative, it will always negative(upwards)
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
## Get globalized [member gravity_dir], if [member gravity_dir_rotation] is [code]false[/code], the globalized one equals [member gravity_dir]
func get_global_gravity_dir() -> Vector2:
	return gravity_dir.rotated(global_rotation) if gravity_dir_rotation else gravity_dir


# Updaters
## Update [member up_direction] to suit certain current situation
func update_up_direction() -> void:
	up_direction = _up_temp.rotated(global_rotation)


# Is-methods
## To check if the body is standing on a slope
func is_on_slope() -> bool:
	var dot:float = get_floor_normal().dot(get_global_gravity_dir())
	return dot < 0 && !is_equal_approx(dot,-1)


## To check if the body is able to slope down
func is_able_slope_down() -> bool:
	return !floor_stop_on_slope && !is_on_wall() && is_on_slope()
