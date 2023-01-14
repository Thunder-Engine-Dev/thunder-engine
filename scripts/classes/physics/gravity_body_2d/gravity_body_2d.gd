extends CorrectedCharacterBody2D
class_name GravityBody2D
@icon("./gravity_body_2d.svg")


const GRAVITY:float = 50.0

@export_group("Speed")
@export var speed: Vector2 # Not the scaler "speed", but the vector "velocity" affected by gravity_dir
@export_group("Gravity")
@export var gravity_dir: Vector2 = Vector2.DOWN
@export var gravity_dir_rotation: bool
@export var gravity_scale: float
@export var max_falling_speed: float:
	set(value):
		max_falling_speed = clamp(value,0,INF)
@export_group("Collision")
@export var collision: bool = true
@export_group("Correction")
@export var correction_enabled:bool = true
@export_group("Floor","floor_")

var prespeed: Vector2
var global_gravity_dir: Vector2

@onready var up: Vector2 = up_direction

signal collided
signal collided_wall
signal collided_ceiling
signal collided_floor


func gravity_process() -> void:
	global_gravity_dir = gravity_dir.rotated(global_rotation) if gravity_dir_rotation else gravity_dir
	
	var gravity: float = gravity_scale * GRAVITY
	if max_falling_speed > 0:
		if speed.y < max_falling_speed:
			accelerate_y(max_falling_speed,gravity)
		elif speed.y > max_falling_speed:
			speed.y = max_falling_speed
	else:
		speed.y += gravity


func motion_process(delta: float, rigid: bool = false, rigid_with_speed_x: bool = true) -> void:
	var gdir: float = global_gravity_dir.orthogonal().angle()
	
	prespeed = speed
	velocity = speed.rotated(gdir)
	
	if !collision:
		global_position += velocity * delta
		return
	
	up_direction = up.rotated(global_rotation)
	
	if correction_enabled:
		move_and_slide_corrected()
	else:
		move_and_slide()
	
	if rigid:
		velocity = get_real_velocity()
	speed = velocity.rotated(-gdir)
	
	var on_wall: bool = is_on_wall()
	var on_ceiling: bool = is_on_ceiling()
	var on_floor: bool = is_on_floor()
	
	if rigid && rigid_with_speed_x && !on_wall:
		speed.x = prespeed.x
	
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
	speed.x = -prespeed.x

func turn_y() -> void:
	speed.y = -prespeed.y

func jump(jumping_speed: float) -> void:
	speed.y = -abs(jumping_speed)

func vel_set(vel: Vector2) -> void:
	speed = vel

func vel_set_x(velx: float) -> void:
	speed.x = velx

func vel_set_y(vely: float) -> void:
	speed.y = vely
