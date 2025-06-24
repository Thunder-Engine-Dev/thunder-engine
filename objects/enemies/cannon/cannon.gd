@tool
extends AnimatableBody2D

const CannonBall = preload("./cannon_ball.gd")

@export_category("Cannon")
@export_group("Sprites", "sprite_")
@export var sprite_head: Sprite2D
@export var sprite_handler: Sprite2D
@export_subgroup("Sprite Modification", "sprite_")
@export_range(-180, 180, 0.1, "radians_as_degrees") var sprite_head_rotation: float = 0:
	set(value):
		sprite_head_rotation = value
		if !sprite_head:
			return
		sprite_head.rotation = sprite_head_rotation
		sprite_head.flip_v = true if sprite_head.rotation > PI / 2 || sprite_head.rotation < -PI / 2 else false
@export_range(-180, 180, 0.1, "radians_as_degrees") var sprite_handler_rotation: float = 0:
	set(value):
		sprite_handler_rotation = value
		if !sprite_handler:
			return
		sprite_handler.rotation = sprite_handler_rotation
		sprite_handler.flip_h = true if sprite_handler.rotation > PI / 2 || sprite_handler.rotation < -PI / 2 else false
@export_group("Cannon")
@export_subgroup("Cannon Ball")
@export var cannon_ball: PackedScene = preload("./cannon_ball.tscn")
@export_range(0, 9999, 0.1, "or_greater", "hide_slider", "suffix:px/s") var cannon_ball_speed: float = 200
@export_subgroup("Cannon Shooting")
@export var cannon_explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
@export_range(0, 20, 0.001, "or_greater", "suffix:s") var first_shooting_delay: float = 0.5
@export_range(0, 20, 0.001, "or_greater", "suffix:s") var shooting_delay_min: float = 1.5
@export_range(0, 20, 0.001, "or_greater", "suffix:s") var shooting_delay_max: float = 4.5
@export_group("Sounds", "sound_")
@export var sound_shoot: AudioStream = preload("res://engine/objects/enemies/bullet_bill/bill/sounds/bullet.ogg")

@onready var _pos_cball: Marker2D = $SpriteHead/PosCannonBall
@onready var _cannon_itrvl: Timer = $CannonInterval


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_cannon_itrvl.start(first_shooting_delay)


func _on_cannon_interval_timeout() -> void:
	Audio.play_sound(sound_shoot, self, false)
	if cannon_ball:
		var cball: CannonBall = NodeCreator.prepare_2d(cannon_ball, self) \
			.bind_global_transform(
				_pos_cball.global_position,
				global_rotation,
				global_scale,
				global_skew
			) \
			.create_2d() \
			.get_node()
		if cball:
			cball.velocity = Vector2.RIGHT.rotated(global_rotation + sprite_head_rotation) * cannon_ball_speed
			cball.reset_physics_interpolation()
	if cannon_explosion_effect:
		var eff := NodeCreator.prepare_2d(cannon_explosion_effect, self) \
			.create_2d() \
			.get_node()
		eff.global_transform = global_transform
		eff.global_position = _pos_cball.global_position
		eff.reset_physics_interpolation()
	
	_cannon_itrvl.start(Thunder.rng.get_randf_range(shooting_delay_min, shooting_delay_max))


func _on_screen_entered() -> void:
	_cannon_itrvl.paused = false

func _on_screen_exited() -> void:
	_cannon_itrvl.paused = true
