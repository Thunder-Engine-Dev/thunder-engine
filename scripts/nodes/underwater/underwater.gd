extends Node

signal got_into_water
signal got_out_of_water

@export var gravity_scale_override: float
@export var max_falling_speed_override: float
@export var spray_offset: Vector2

var _gravity_scale: float
var _max_falling_speed: float

@onready var par: Node2D = get_parent() as Node2D
@onready var bubble: GPUParticles2D = $"../Sprite/Bubble"


func in_water() -> void:
	_gravity_scale = par.get(&"gravity_scale")
	_max_falling_speed = par.get(&"max_falling_speed")
	par.set(&"gravity_scale", gravity_scale_override)
	par.set(&"max_falling_speed", max_falling_speed_override)
	got_into_water.emit()
	bubble.emitting = true


func out_of_water() -> void:
	par.set(&"gravity_scale", _gravity_scale)
	par.set(&"max_falling_speed", _max_falling_speed)
	_gravity_scale = 0
	_max_falling_speed = 0
	got_out_of_water.emit()
	bubble.emitting = false
