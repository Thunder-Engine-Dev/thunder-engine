extends Node

signal got_into_water
signal got_out_of_water

@export var gravity_scale_override: float
@export var max_falling_speed_override: float
@export var spray_offset: Vector2

var _gravity_scale: float
var _max_falling_speed: float

@onready var par: Node2D = get_parent() as Node2D

func _ready() -> void:
	if par is Player:
		par.suit_changed.connect(_on_suit_changed)


func in_water() -> void:
	_gravity_scale = par.get(&"gravity_scale")
	_max_falling_speed = par.get(&"max_falling_speed")
	var conf_gravity = par.suit.physics_config.get("swim_gravity_scale") if par is Player else gravity_scale_override
	var conf_falling = par.suit.physics_config.get("swim_max_falling_speed") if par is Player else max_falling_speed_override
	par.set(&"gravity_scale", conf_gravity)
	par.set(&"max_falling_speed", conf_falling)
	got_into_water.emit()


func out_of_water() -> void:
	par.set(&"gravity_scale", _gravity_scale)
	par.set(&"max_falling_speed", _max_falling_speed)
	_gravity_scale = 0
	_max_falling_speed = 0
	got_out_of_water.emit()


func _on_suit_changed(_s = null) -> void:
	if par.is_underwater:
		var conf_gravity = par.suit.physics_config.get("swim_gravity_scale")
		var conf_falling = par.suit.physics_config.get("swim_max_falling_speed")
		par.set(&"gravity_scale", conf_gravity)
		par.set(&"max_falling_speed", conf_falling)
