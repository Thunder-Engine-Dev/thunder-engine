extends AnimatableBody2D

@export var respawnable: bool = false
@export var delay: float = 50
@export var force_fall: bool = false
@export var fall_speed: float = 0.2
@export var one_way_collision: bool = true
@export_enum("X", "Y") var shake_axis: int = 0

var counting: bool = false
var counter: float = 0
var speed_y: float

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var first_pos: Vector2 = position

func _ready() -> void:
	for i in get_shape_owners():
		shape_owner_set_one_way_collision.call_deferred(i, one_way_collision)


func _physics_process(delta):
	delta = Thunder.get_delta(delta)
	if counting:
		counter += 1 * delta
		# Trigger sprite
		if sprite.sprite_frames.has_animation(&"trigger"): sprite.play(&"trigger")
		# Shaking animation
		var vect = Vector2(0, cos(counter)) if shake_axis else Vector2(cos(counter), 0)
		sprite.position = vect.rotated(global_rotation)
		
	if speed_y != 0:
		# Return back to default
		sprite.position = Vector2.ZERO
	
	if counter > delay:
		speed_y += fall_speed * delta
		position += Vector2(0, speed_y).rotated(global_rotation) * delta
		if !Thunder.view.screen_dir(
			global_position, Vector2.DOWN.rotated(global_rotation), 256
		):
			if respawnable:
				reset_vars()
				sprite.scale = Vector2.ZERO
				var tw = create_tween()
				tw.tween_property(sprite, ^"scale", Vector2.ONE, 0.4)
			else:
				queue_free()


func reset_vars() -> void:
	counting = false
	sprite.animation = &"default"
	counter = 0
	speed_y = 0
	position = first_pos


func _on_player_enter() -> void:
	counting = true


func _on_player_exit() -> void:
	if counter > delay: return
	if !force_fall:
		counting = false
		counter = 0
		if sprite.sprite_frames.has_animation(&"default"): sprite.animation = &"default"
		sprite.position = Vector2.ZERO
		sprite.reset_physics_interpolation()
	
