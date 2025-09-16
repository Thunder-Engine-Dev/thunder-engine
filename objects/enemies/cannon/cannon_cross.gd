@tool
extends AnimatableBody2D

const CannonBall = preload("./cannon_ball.gd")

@export_category("Cannon")
@export_group("Sprites", "sprite_")
@export var sprite_head: Node2D
@export var sprite_handler: Sprite2D
@export var sprite_pos_markers: Array[Marker2D]
@export_subgroup("Sprite Modification", "sprite_")
@export_range(-90, 90, 0.1, "radians_as_degrees") var sprite_head_rotation: float = 0:
	set(value):
		sprite_head_rotation = value
		if !sprite_head:
			return
		sprite_head.rotation = sprite_head_rotation
@export_range(-180, 180, 0.1, "radians_as_degrees") var sprite_handler_rotation: float = 0:
	set(value):
		sprite_handler_rotation = value
		if !sprite_handler:
			return
		sprite_handler.rotation = sprite_handler_rotation
		sprite_handler.flip_h = true if sprite_handler.rotation > PI / 2 || sprite_handler.rotation < -PI / 2 else false
		if collision_shape:
			collision_shape.rotation = sprite_handler.rotation
			collision_shape.position = Vector2.DOWN.rotated(collision_shape.rotation) * collision_shape_offset_y
@export_group("Collision Shape")
@export var collision_shape: CollisionShape2D
@export_range(-128, 128, 0.01,"or_less", "or_greater", "suffix:px") var collision_shape_offset_y: float = 2
@export_group("Cannon")
@export_subgroup("Cannon Ball")
@export var cannon_ball: PackedScene = preload("./cannon_ball.tscn")
@export_range(0, 9999, 0.1, "or_greater", "hide_slider", "suffix:px/s") var cannon_ball_speed: float = 200
@export_subgroup("Cannon Shooting")
@export var cannon_explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
@export_range(-20, 20, 0.001, "or_greater", "suffix:s") var rotation_duration_dir: float = -0.5
@export_range(0, 20) var rotation_periods: int = 2
@export_range(0, 20, 0.001, "or_greater", "suffix:s") var shooting_waiting_interval: float = 1
@export_group("Sounds", "sound_")
@export var sound_shoot: AudioStream = preload("res://engine/objects/enemies/bullet_bill/bill/sounds/bullet.ogg")

@onready var _itrvl: Timer = $Interval


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_itrvl.start(shooting_waiting_interval)


func _shoot(index: int) -> void:
	if cannon_ball:
		var cball: CannonBall = NodeCreator.prepare_2d(cannon_ball, self) \
			.bind_global_transform(
				Vector2.ZERO,
				global_rotation,
				global_scale,
				global_skew
			) \
			.create_2d() \
			.get_node()
		if cball:
			cball.global_position = sprite_pos_markers[index].global_position
			cball.velocity = Vector2.RIGHT.rotated(global_rotation + sprite_head_rotation - PI / 2 * index) * cannon_ball_speed
			cball.reset_physics_interpolation()
	if cannon_explosion_effect:
		var eff := NodeCreator.prepare_2d(cannon_explosion_effect, self) \
			.create_2d() \
			.get_node()
		eff.global_transform = global_transform
		eff.global_position = sprite_pos_markers[index].global_position
		eff.reset_physics_interpolation()

func _shoot_balls() -> void:
	if sprite_pos_markers.is_empty():
		return
	
	for m: int in sprite_pos_markers.size():
		if !is_instance_valid(sprite_pos_markers[m]):
			continue
		_shoot(m)


func _on_interval_timeout() -> void:
	var next_angle := sprite_head_rotation + ((PI / 2) / rotation_periods) * signf(rotation_duration_dir)
	
	var tw: Tween = create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, ^"sprite_head_rotation", next_angle, absf(rotation_duration_dir))
	await tw.finished
	
	Audio.play_sound(sound_shoot, self, false)
	_shoot_balls.call_deferred()
	sprite_head_rotation = wrapf(sprite_head_rotation, -PI / 2, PI / 2)
	_itrvl.start(shooting_waiting_interval)

func _on_screen_entered() -> void:
	_itrvl.paused = false

func _on_screen_exited() -> void:
	_itrvl.paused = true
