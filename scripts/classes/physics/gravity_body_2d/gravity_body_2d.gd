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
@export var correction_enabled: bool = true
@export_group("Floor","floor_")

var speed_previous: Vector2
var snapped:bool

@onready var up_temp: Vector2 = up_direction


signal collided
signal collided_wall
signal collided_ceiling
signal collided_floor


func motion_process(delta: float, deep_snap: bool = true, kinematic: bool = true) -> void:
	var gravity: float = gravity_scale * GRAVITY
	
	speed_previous = speed
	
	speed += gravity * gravity_dir * delta
	if max_falling_speed > 0 && speed.y > max_falling_speed:
		speed.y = max_falling_speed
	
	if is_on_floor() && snapped && deep_snap && speed.y < 0:
		speed.y = 0
	
	update_up_direction()
	
	velocity = speed.rotated(global_rotation)
	
	do_movement(delta,true)
	
	if kinematic && !is_on_wall():
		speed.x = speed_previous.x

func do_movement(delta:float,emit_detection_signal:bool = false) -> void:
	if velocity.is_equal_approx(Vector2.ZERO): return
	
	if !collision:
		global_position += velocity * delta
		return
	
	if correction_enabled:
		move_and_slide_corrected()
	else:
		move_and_slide()
	
	velocity = get_real_velocity()
	speed = velocity.rotated(-global_rotation)
	
	if !emit_detection_signal: return
	_collision_signals()


# Some useful functions
func accelerate(to: Vector2, a: float) -> void:
	speed = speed.move_toward(to, a)
	snapped_off()

func accelerate_x(to: float, a: float) -> void:
	speed.x = move_toward(speed.x, to, a)

func accelerate_y(to: float, a: float) -> void:
	speed.y = move_toward(speed.y, to, a)
	snapped_off()

func turn_x() -> void:
	speed.x = -speed_previous.x

func turn_y() -> void:
	speed.y = -speed_previous.y
	snapped_off()

func jump(jumping_speed: float) -> void:
	speed.y = -abs(jumping_speed)
	snapped_off()

func vel_set(vel: Vector2) -> void:
	speed = vel
	snapped_off()

func vel_set_x(velx: float) -> void:
	speed.x = velx

func vel_set_y(vely: float) -> void:
	speed.y = vely
	snapped_off()


# Status notifiers
func snapped_off() -> void:
	if collision && velocity.dot(get_global_gravity_dir()) < 0:
		snapped = false

func stop_notify(wall_notify:bool = true, ceiling_notify:bool = true, floor_notify:bool = true) -> void:
	if wall_notify && is_on_wall() && speed.x != 0: speed.x = 0
	if ceiling_notify && is_on_ceiling() && speed.y < 0 && !slide_on_ceiling: speed.y = 0
	if floor_notify && is_on_floor() && speed.y > 0 && !floor_stop_on_slope: speed.y = 0


# Getters
func get_global_gravity_dir() -> Vector2:
	return gravity_dir.rotated(global_rotation) if gravity_dir_rotation else gravity_dir


# Updaters
func update_up_direction() -> void:
	up_direction = up_temp
	if is_on_slope():
		up_direction = up_temp.rotated(global_rotation)


# Is-methods
func is_on_slope() -> bool:
	var dot:float = get_floor_normal().dot(get_global_gravity_dir())
	return dot < 0 && !is_equal_approx(dot,-1)

func is_able_slope_down() -> bool:
	return !floor_stop_on_slope && !is_on_wall() && is_on_slope()


# Private methods
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
