extends CorrectedCharacterBody2D
class_name GravityBody2D
@icon("./gravity_body_2d.svg")


const GRAVITY:float = 50.0

@export_group("Velocity")
@export var velocity_local: Vector2
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

var velocity_previous: Vector2
var global_gravity_dir: Vector2

signal collided
signal collided_wall
signal collided_ceiling
signal collided_floor


func gravity_process(delta: float) -> void:
	global_gravity_dir = gravity_dir.rotated(global_rotation) if gravity_dir_rotation else gravity_dir
	
	var gravity: float = gravity_scale * GRAVITY
	if max_falling_speed > 0:
		if velocity_local.y < max_falling_speed:
			accelerate_y(max_falling_speed,gravity)
		elif velocity_local.y > max_falling_speed:
			velocity_local.y = max_falling_speed
	else:
		velocity_local.y += gravity


func motion_process(delta: float, elastic:bool) -> void:
	var gdir: float = global_gravity_dir.orthogonal().angle()
	velocity_previous = velocity_local
	velocity = velocity_local.rotated(gdir)
	
	if !collision:
		global_position += velocity * delta
		return
	
	if correction_enabled:
		move_and_slide_corrected()
	else:
		move_and_slide()
	if elastic:
		velocity = get_real_velocity()
		velocity_local = velocity.rotated(-gdir)
	if is_on_wall():
		if !elastic:
			velocity_local.x = 0
		collided.emit()
		collided_wall.emit()
	if is_on_ceiling():
		collided.emit()
		collided_ceiling.emit()
	if is_on_floor():
		if !elastic:
			velocity_local.y = 0
		collided.emit()
		collided_floor.emit()


# Some useful functions
func accelerate(to: Vector2, a: float) -> void:
	velocity_local = velocity_local.move_toward(to, a)

func accelerate_x(to: float, a: float) -> void:
	velocity_local.x = move_toward(velocity_local.x, to, a)

func accelerate_y(to: float, a: float) -> void:
	velocity_local.y = move_toward(velocity_local.y, to, a)

func turn_x() -> void:
	velocity_local.x = -velocity_previous.x

func turn_y() -> void:
	velocity_local.y = -velocity_previous.y

func jump(speed: float) -> void:
	velocity_local.y = -abs(speed)

func vel_set(vel: Vector2) -> void:
	velocity_local = vel

func vel_set_x(velx: float) -> void:
	velocity_local.x = velx

func vel_set_y(vely: float) -> void:
	velocity_local.y = vely
