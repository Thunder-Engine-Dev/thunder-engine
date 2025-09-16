extends Node2D

var rotation_speed = 0
var y_modifier = 0
var y_modify_over_time: float = 0
var apply_force_below_y: float = 0

@onready var sprite_2d = $Sprite2D
var _y_mod_init_time: float

func _ready():
	var tw = create_tween()
	tw.tween_property(sprite_2d, "scale", Vector2.ZERO, 0.6)
	tw.tween_callback(queue_free)
	_y_mod_init_time = y_modify_over_time

func _physics_process(delta):
	if apply_force_below_y != 0 && global_position.y > apply_force_below_y:
		y_modify_over_time -= _y_mod_init_time * delta * 50
	else:
		y_modify_over_time += _y_mod_init_time * delta * 50
	position.y += y_modify_over_time * delta * 50
	position.y -= delta * (150 + y_modifier)
	
	rotation_degrees += rotation_speed * delta
