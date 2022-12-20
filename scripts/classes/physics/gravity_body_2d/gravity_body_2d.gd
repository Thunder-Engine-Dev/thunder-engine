extends CorrectedCharacterBody2D
class_name GravityBody2D
@icon("./gravity_body_2d.svg")


@export_group("Basic Physics")
@export var velocity_local: Vector2
@export var gravity_scale: float
@export var max_falling_speed: float:
	set(value):
		max_falling_speed = clamp(value,0,INF)
@export var real_velocity: bool = true
@export_group("Correction")
@export var correction_enabled:bool = true

var velocity_temp: Vector2

signal collided_wall
signal collided_ceiling
signal collided_floor


func motion_process(delta: float) -> void:
	var gspeed: float = gravity_scale * Thunder.gravity_speed
	if !is_on_floor():
		if max_falling_speed > 0:
			accelerate_y(max_falling_speed, gspeed)
		else:
			velocity_local.y += gspeed
	elif !real_velocity && velocity_local.y > 0:
		velocity_local.y = 0
	
	up_direction = Vector2.UP.rotated(global_rotation)
	velocity = velocity_local.rotated(global_rotation) * delta
	if correction_enabled:
		move_and_slide_corrected()
	else:
		move_and_slide()
	if real_velocity:
		velocity_local = get_real_velocity().rotated(-global_rotation) / delta
		print(velocity_local)
		# Problematic! get_real_velocity() will return a unaccurate result when collision happenes!

func collision_process() -> void:
	if is_on_wall():
		collided_wall.emit()
	if is_on_ceiling():
		collided_ceiling.emit()
	if is_on_floor():
		collided_floor.emit()


# Some useful functions
func accelerate(to: Vector2, a: float) -> void:
	velocity_local = velocity_local.move_toward(to, a)

func accelerate_x(to: float, a: float) -> void:
	velocity_local.x = move_toward(velocity_local.x, to, a)

func accelerate_y(to: float, a: float) -> void:
	velocity_local.y = move_toward(velocity_local.y, to, a)

func turn_x() -> void:
	velocity_local.x = -velocity_temp.x

func turn_y() -> void:
	velocity_local.y = -velocity_temp.y

func jump(speed: float) -> void:
	velocity_local.y = -abs(speed)

func velcall(vel: Vector2) -> void:
	velocity_local = vel

func velcallx(velx: float) -> void:
	velocity_local.x = velx

func velcally(vely: float) -> void:
	velocity_local.y = vely
