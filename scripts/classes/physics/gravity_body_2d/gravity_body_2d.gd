@icon("./gravity_body_2d.svg")
extends CorrectedCharacterBody2D
class_name GravityBody2D

# Note: Due to bugs with gravity direction whose angle is not 90°,180°,270° or 0°, you need to manually change up_direction via inspector
# We are still trying to fix the bug with GDScript :)

const GRAVITY: float = 50.0

@export_group("Speed")
@export var speed: Vector2 # Not the scaler "speed", but the vector "velocity" affected by gravity_dir
@export_group("Gravity")
@export var gravity_dir: Vector2 = Vector2.DOWN
@export var gravity_dir_rotation: bool = true
@export var gravity_scale: float
@export_range(0,100000,0.1) var max_falling_speed: float
@export_group("Collision")
@export var collision: bool = true
@export_group("Correction")
@export var correction_enabled:bool = true
@export_group("Floor","floor_")

var speed_previous: Vector2


signal collided
signal collided_wall
signal collided_ceiling
signal collided_floor


func motion_process(delta: float, kinematic: bool = true) -> void:
	var gravity: float = gravity_scale * GRAVITY
	var gdir: float = Vector2.DOWN.angle_to(get_global_gravity_dir())
	
	speed_previous = speed
	
	if gravity > 0:
		if max_falling_speed > 0:
			if speed.y < max_falling_speed:
				accelerate_y(max_falling_speed,gravity)
			elif speed.y > max_falling_speed:
				speed.y = max_falling_speed
		else:
			speed.y += gravity
	
	velocity = speed.rotated(gdir)
	
	if !collision:
		global_position += velocity * delta
		return
	
	if correction_enabled:
		move_and_slide_corrected()
	else:
		move_and_slide()
	
	velocity = get_real_velocity()
	speed = velocity.rotated(-gdir)
	
	var on_wall: bool = is_on_wall()
	var on_ceiling: bool = is_on_ceiling()
	var on_floor: bool = is_on_floor()
	
	if kinematic && !on_wall:
		speed.x = speed_previous.x
	
	if on_wall:
		collided.emit()
		collided_wall.emit()
	if on_ceiling:
		collided.emit()
		collided_ceiling.emit()
	if on_floor:
		collided.emit()
		collided_floor.emit()


# Some useful functions
func accelerate(to: Vector2, a: float) -> void:
	speed = speed.move_toward(to, a)

func accelerate_x(to: float, a: float) -> void:
	speed.x = move_toward(speed.x, to, a)

func accelerate_y(to: float, a: float) -> void:
	speed.y = move_toward(speed.y, to, a)

func turn_x() -> void:
	speed.x = -speed_previous.x

func turn_y() -> void:
	speed.y = -speed_previous.y

func jump(jumping_speed: float) -> void:
	speed.y = -abs(jumping_speed)

func vel_set(vel: Vector2) -> void:
	speed = vel

func vel_set_x(velx: float) -> void:
	speed.x = velx

func vel_set_y(vely: float) -> void:
	speed.y = vely


# Getters
func get_global_gravity_dir() -> Vector2:
	return gravity_dir.rotated(global_rotation) if gravity_dir_rotation else gravity_dir
