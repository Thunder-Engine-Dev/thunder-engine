@icon("./gravity_body_2d.svg")
extends CorrectedCharacterBody2D
class_name GravityBody2D

## Very useful [CorrectedCharacterBody2D] with easy-call [method motion_process] method to achieve calculations of gravity and slide collsion[br]
## [color=orange][b]Note:[/b][/color] Due to bugs with gravity direction whose angle is not 90°,180°,270° or 0°, you need to manually change up_direction via inspector.
## We are still trying to fix the bug with GDScript :)

## Default gravity acceleration
const GRAVITY: float = 50.0

@export_group("Speed")
## The velocity of the body. [color=gold][b]This is related to the bodie's[/b][/color] [member Node2D.global_rotation]
@export var speed: Vector2 # Not the scaler "speed", but the vector "velocity" affected by gravity_dir
@export_group("Gravity")
## The gravity_direction of the body, with length always [code]1.0[/code][br]
## [color=gold][b]This is related to the bodie's[/b][/color] [member Node2D.global_rotation] if [member gravity_dir_rotation] is [code]true[/code]
@export var gravity_dir: Vector2 = Vector2.DOWN
## Defines whether the returned value of [method get_global_gravity_dir] equals [member gravity_dir] following the bodie's [member Node2D.global_rotation] or not
@export var gravity_dir_rotation: bool = true
## Defines the scale of [member GRAVITY], then the gravity acceleration = [member GRAVITY] * [member gravity_scale]
@export var gravity_scale: float
## Defines maximum of speed.y affected by gravity
@export_range(0,100000,0.1) var max_falling_speed: float
@export_group("Collision")
## Defines if the body enables collision. For those who don't need any collision, it's recommeneded to set this value to [code]false[/code]
## to acquire more performance
@export var collision: bool = true

## [member speed] in previous frame, useful for calculations of delta position
var speed_previous: Vector2
var _snapped:bool

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
## [code]delta[/code] should be the one from [method Node._phyiscs_process][br]
## [code]deep_snap[/code] makes sure the body won't fly from sloping-up[br]
## [code]kinematic[/code] makes sure the body can keep moving up on a slope[br]
func motion_process(delta: float, deep_snap: bool = true, kinematic: bool = true) -> void:
	var gravity: float = gravity_scale * GRAVITY
	
	speed_previous = speed
	
	speed += gravity * gravity_dir * delta
	if max_falling_speed > 0 && speed.y > max_falling_speed:
		speed.y = max_falling_speed
	
	if is_on_floor() && _snapped && deep_snap && speed.y < 0:
		speed.y = 0
	
	update_up_direction()
	
	velocity = speed.rotated(global_rotation)
	
	do_movement(delta, true)
	
	if kinematic && !is_on_wall():
		speed.x = speed_previous.x

## Direct method to process the body move with both gravity and collision(if [member collsion] is [code]true[/code])[br]
## [code]delta[/code] should be the one from [method Node._phyiscs_process][br]
## [code]emit_detection_signal[/code] makes the body emit [b]collision*[b] signals if collision happens[br]
func do_movement(delta:float,emit_detection_signal:bool = false) -> void:
	if velocity.is_equal_approx(Vector2.ZERO): return
	
	if !collision:
		global_position += velocity * delta
		return
	
	if correct_collision:
		move_and_slide_corrected()
	else:
		move_and_slide()
	
	velocity = get_real_velocity()
	speed = velocity.rotated(-global_rotation)
	
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
	_snapped_off()

## Accelerate [member speed].x to a certain value with acceleration
func accelerate_x(to: float, a: float) -> void:
	speed.x = move_toward(speed.x, to, a)

## Accelerate [member speed].y to a certain value with acceleration
func accelerate_y(to: float, a: float) -> void:
	speed.y = move_toward(speed.y, to, a)
	_snapped_off()

## Reverse [member speed].x
func turn_x() -> void:
	speed_previous.x = -speed_previous.x
	speed.x = speed_previous.x

## Reverse [member speed].y
func turn_y() -> void:
	speed.y = -speed_previous.y
	_snapped_off()

## Jump. No matter if [code]jumping_speed[/code] is positive or negative, it will always negative(upwards)
func jump(jumping_speed: float) -> void:
	speed.y = -abs(jumping_speed)
	_snapped_off()

## Set [member speed] to a new [Vector2]
func vel_set(vel: Vector2) -> void:
	speed = vel
	_snapped_off()

## Set [member speed].x to a new value
func vel_set_x(velx: float) -> void:
	speed.x = velx

## Set [member speed].y to a new value
func vel_set_y(vely: float) -> void:
	speed.y = vely
	_snapped_off()


# Status notifiers
func _snapped_off() -> void:
	if collision && velocity.dot(get_global_gravity_dir()) < 0:
		_snapped = false

## Notify the body with certain type(s) of collision and make it stop according to the related notify/notifies)
func stop_notify(wall_notify:bool = true, ceiling_notify:bool = true, floor_notify:bool = true) -> void:
	if wall_notify && is_on_wall() && speed.x != 0: speed.x = 0
	if ceiling_notify && is_on_ceiling() && speed.y < 0 && !slide_on_ceiling: speed.y = 0
	if floor_notify && is_on_floor() && speed.y > 0 && !floor_stop_on_slope: speed.y = 0


# Getters
## Get globalized [member gravity_dir], if [memebr gravity_dir_rotation] is [code]false[/code], the globalized one equals [memeber gravity_dir]
func get_global_gravity_dir() -> Vector2:
	return gravity_dir.rotated(global_rotation) if gravity_dir_rotation else gravity_dir


# Updaters
## Update [memebr up_direction] to suit certain current situation
func update_up_direction() -> void:
	up_direction = _up_temp
	if is_on_slope():
		up_direction = _up_temp.rotated(global_rotation)


# Is-methods
## To check if the body is standing on a slope
func is_on_slope() -> bool:
	var dot:float = get_floor_normal().dot(get_global_gravity_dir())
	return dot < 0 && !is_equal_approx(dot,-1)

## To check if the body is able to slope down
func is_able_slope_down() -> bool:
	return !floor_stop_on_slope && !is_on_wall() && is_on_slope()
