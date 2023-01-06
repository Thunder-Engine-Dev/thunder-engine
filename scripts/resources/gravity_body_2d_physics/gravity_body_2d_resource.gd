extends Resource
class_name GravityBody2DPhysics
@icon("res://engine/scripts/classes/physics/gravity_body_2d/gravity_body_2d.svg")

@export_category("GravityBody2DPhysics")
@export_group("Velocity")
@export var velocity_local: Vector2
@export var velocity_local_random_max: Vector2
@export_group("Gravity")
@export var gravity_override: bool
@export var gravity_scale: float
@export var max_falling_speed: float

var gravity_body:GravityBody2D


func bind(grav_body:GravityBody2D) -> GravityBody2DPhysics:
	gravity_body = grav_body
	
	return self


func unbind() -> void:
	gravity_body = null


func get_velocity_random() -> Vector2:
	var r: Vector2 = Vector2(
		randf_range(velocity_local.x,velocity_local_random_max.x) if velocity_local_random_max.x > velocity_local.x else velocity_local.x,
		randf_range(velocity_local.y,velocity_local_random_max.y) if velocity_local_random_max.y > velocity_local.y else velocity_local.y
	)
	
	return r


func apply_velocity_local() -> GravityBody2DPhysics:
	if !gravity_body: return self
	
	gravity_body.vel_set(get_velocity_random())
	
	return self


func override_gravity() -> GravityBody2DPhysics:
	if !gravity_body || !gravity_override: return self
	
	gravity_body.gravity_scale = gravity_scale
	gravity_body.max_falling_speed = max_falling_speed
	
	return self
