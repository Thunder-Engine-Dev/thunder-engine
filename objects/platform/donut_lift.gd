extends AnimatableBody2D

@export var delay: float = 50
@export var force_fall: bool = false
@export var fall_speed: float = 0.2
@export_enum("X", "Y") var shake_axis: int = 0

var counting: bool = false
var counter: float = 0
var speed_y: float

@onready var sprite: AnimatedSprite2D = $Sprite


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
		return
	
	var prev_count: bool = counting
	if !force_fall:
		counting = false
		if !prev_count:
			counter = 0
			if sprite.sprite_frames.has_animation(&"default"): sprite.animation = &"default"
			sprite.position = Vector2.ZERO
	
	if speed_y != 0: return
	if force_fall && counting: return
	
	var kc: = KinematicCollision2D.new()
	test_move(global_transform, Vector2.UP.rotated(global_rotation), kc)
	if kc:
		var collider: = kc.get_collider()
		if collider is Player && collider.is_on_floor():
			counting = true
	
