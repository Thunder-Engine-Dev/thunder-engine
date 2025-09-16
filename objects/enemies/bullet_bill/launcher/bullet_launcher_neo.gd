@tool
extends AnimatableBody2D

@export_category("Bullet Launcher Neo")
@export_group("Sprite", "sprite_")
@export var sprite_head: Sprite2D
@export var sprite_handler: Sprite2D
@export_subgroup("Modification")
@export_range(-90, 90, 0.1, "radians_as_degrees") var sprite_head_rotation: float = 0:
	set(value):
		sprite_head_rotation = value
		if sprite_head:
			sprite_head.rotation = sprite_head_rotation
@export_range(-180, 180, 0.1, "radians_as_degrees") var sprite_handler_rotation: float = 0:
	set(value):
		sprite_handler_rotation = value
		if sprite_handler:
			sprite_handler.rotation = sprite_handler_rotation
		sprite_handler.flip_h = true if sprite_handler.rotation > PI / 2 || sprite_handler.rotation < -PI / 2 else false
		_update_handler_length()
@export_subgroup("Height", "height_")
@export_range(0, 256, 0.1, "or_greater", "suffix:px") var height_in_pixels: float = 32:
	set(value):
		height_in_pixels = value
		_update_handler_length()
@export_range(0, 256, 0.1, "or_greater", "hide_slider", "suffix:px") var height_tiles_base: float = 32:
	set(value):
		height_tiles_base = value
		height_in_tiles = height_in_tiles # Triggers its setter to update the data
@export_range(0, 256, 0.1, "or_greater", "suffix:grids") var height_in_tiles: float = 1:
	set(value):
		height_in_pixels = value * height_tiles_base
	get:
		return height_in_pixels / height_tiles_base
@export_group("Collision Shape")
@export var collision_shape: CollisionShape2D:
	set(value):
		collision_shape = value
		if !collision_shape.shape is RectangleShape2D:
			collision_shape.shape = RectangleShape2D.new()
		var width := 32.0 if !sprite_head else float(sprite_head.texture.get_width())
		(collision_shape.shape as RectangleShape2D).size.x = width
		_update_handler_length()
@export_group("Shooting")
@export_subgroup("Bullet")
@export var bullet_bill: InstanceNode2D
@export_range(0, 9999, 0.1, "or_greater", "hide_slider", "suffix:px/s") var bullet_speed: float = 162.5
@export_group("Shooting")
@export var explosion: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
@export var stop_shooting_radius: float = 80
@export_range(0, 20, 0.001, "or_greater", "suffix:s") var first_shooting_delay: float = 0.5
@export_range(0, 20, 0.001, "or_greater", "suffix:s") var shooting_delay_min: float = 1.5
@export_range(0, 20, 0.001, "or_greater", "suffix:s") var shooting_delay_max: float = 4.5
@export_range(-1, 1, 1) var shooting_force_dir: int = 0
@export_group("Sounds", "sound_")
@export var sound_shooting: AudioStream = preload("../bill/sounds/bullet.ogg")
@export var sound_shooting_pitch_min: float = 1.0
@export var sound_shooting_pitch_max: float = 1.2
@export var sound_shooting_volume: float = -4

@export_storage var _individualized_cbox: bool = false

@onready var _pos_bullet_l: Marker2D = $SpriteHead/PosBulletL
@onready var _pos_bullet_r: Marker2D = $SpriteHead/PosBulletR
@onready var _itrvl: Timer = $Interval


func _ready() -> void:
	if Engine.is_editor_hint():
		_init_collision_shape()
		return
	_itrvl.start(first_shooting_delay)


func _init_collision_shape() -> void:
	if _individualized_cbox:
		return
	if !(collision_shape.shape is RectangleShape2D):
		collision_shape.shape = RectangleShape2D.new()
	else:
		collision_shape.shape = collision_shape.shape.duplicate()
	_individualized_cbox = true

func _update_handler_length() -> void:
	if !(collision_shape.shape is RectangleShape2D):
		return
	(collision_shape.shape as RectangleShape2D).size.y = height_in_pixels
	var length := (height_in_pixels - height_tiles_base) / 2
	collision_shape.position = Vector2.DOWN.rotated(sprite_handler_rotation) * length
	if sprite_handler:
		collision_shape.rotation = sprite_handler.rotation
		sprite_handler.region_rect.end.y = height_in_pixels
		sprite_handler.offset.y = length

func _shoot_bullet(pos: Marker2D, dir: int) -> void:
	if !sprite_head:
		return
	if dir == 0:
		return
	var sound_data := {
		"pitch": randf_range(sound_shooting_pitch_min, sound_shooting_pitch_max),
		"volume": sound_shooting_volume,
	}
	Audio.play_sound(sound_shooting, pos, false, sound_data)
	
	var configure_bullet := func(bul: Node2D) -> void:
		bul.global_position = pos.global_position
		bul.global_scale = sprite_head.global_scale.abs()
		bul.global_skew = sprite_head.global_skew
		if bul is GeneralMovementBody2D:
			(func() -> void:
				bul.look_at_player = false
				bul.vel_set(Vector2.RIGHT.rotated(sprite_head.global_rotation) * bullet_speed * dir)
				if bul.has_method(&"set_self_modulate_back") && is_instance_valid(bul.sprite_node):
					bul.sprite_node.self_modulate.a = 0.0
					bul.set_self_modulate_back()
				if bul.sprite_node:
					bul.sprite_node.global_rotation = sprite_head.global_rotation
					bul.sprite_node.global_scale = sprite_head.global_scale
				var enemy_attacked: Node = bul.get_node_or_null(^"EnemyAttacked")
				if !enemy_attacked: return
				enemy_attacked.stomping_standard = enemy_attacked.stomping_standard.rotated(-bul.global_rotation)
			).call_deferred()
	NodeCreator.prepare_ins_2d(bullet_bill, self). \
		create_2d(false). \
		call_method(configure_bullet)
	
	var configure_eff := func(eff: Node2D) -> void:
		eff.global_position = pos.global_position
		eff.global_scale = sprite_head.global_scale.abs()
	NodeCreator.prepare_2d(explosion, self). \
		create_2d(false). \
		call_method(configure_eff)

func _on_interval_timeout() -> void:
	var player: Player = Thunder._current_player
	if !player:
		_itrvl.start(0.1)
		return
	if player.completed: 
		return
	var legacy_not_shooting: bool = ProjectSettings.get_setting("application/thunder_settings/tweaks/legacy_bullet_launcher_not_shooting_range", false)
	var not_allowed_shooting := (
		absf(global_transform.affine_inverse().basis_xform(player.global_position).x - global_transform.affine_inverse().basis_xform(global_position).x) <= stop_shooting_radius \
		if legacy_not_shooting else \
		player.global_position.distance_squared_to(global_position) <= stop_shooting_radius ** 2
	)
	if not_allowed_shooting:
		_itrvl.start(0.1)
		return
	
	var dir := Thunder.Math.look_at(sprite_head.global_position, player.global_position, sprite_head.global_transform) if shooting_force_dir == 0 else shooting_force_dir
	var pos := _pos_bullet_l if dir < 0 else _pos_bullet_r
	_shoot_bullet(pos, dir)
	
	_itrvl.start(Thunder.rng.get_randf_range(shooting_delay_min, shooting_delay_max))

func _on_screen_entered() -> void:
	_itrvl.paused = false

func _on_screen_exited() -> void:
	_itrvl.paused = true
