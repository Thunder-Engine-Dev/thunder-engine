extends GravityBody2D

@export_category("Goomba in Bricks")
@export_range(0, 20, 0.001, "or_greater", "hide_slider", "suffix:s") var attack_period_interval: float = 1
@export_range(0, 2500, 0.1,"or_greater", "hide_slider", "suffix:px/s") var jumping_speed: float = 500
@export_group("Sprite", "sprite_")
@export var sprite_goomba: Sprite2D
@export var sprite_bricks: Sprite2D
@export_group("Effect", "effect_")
@export var effect_debris: PackedScene = preload("res://engine/objects/effects/brick_debris/brick_debris.tscn")
@export_group("Sounds", "sound_")
@export var sound_bump: AudioStream = preload("res://engine/objects/bumping_blocks/_sounds/bump.wav")
@export var sound_break: AudioStream = preload("res://engine/objects/bumping_blocks/_sounds/break.wav")

var _vis_enbl_npth_cache: NodePath

@onready var _speed_x: float = speed.x
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _atk_itrvl: Timer = $AttackInterval
@onready var _vis_enbl: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D


func _ready() -> void:
	speed.x = 0
	
	if sprite_bricks && !Engine.is_editor_hint():
		sprite_bricks.show_behind_parent = false
	
	_atk_itrvl.timeout.connect(_on_ready_to_jump)
	_atk_itrvl.start(attack_period_interval)


func _physics_process(delta: float) -> void:
	motion_process(delta)


func bricks_break() -> void:
	Audio.play_sound(sound_break, self)
	var speeds = [Vector2(2, -8), Vector2(4, -7), Vector2(-2, -8), Vector2(-4, -7)]
	for i in speeds:
		NodeCreator.prepare_2d(effect_debris, self).create_2d(true).call_method(func(eff: Node2D):
			eff.global_transform = global_transform
			eff.velocity = i
		)
	if sprite_bricks:
		sprite_bricks.queue_free()


func _on_ready_to_jump() -> void:
	var p := Thunder._current_player
	if !p:
		return
	if p.is_dying:
		return
	
	_vis_enbl_npth_cache = _vis_enbl.enable_node_path
	_vis_enbl.enable_node_path = ^""
	var dir := Thunder.Math.look_at(global_position, p.global_position, global_transform)
	if sprite_goomba:
		sprite_goomba.flip_h = dir < 0
	
	_anim.play(&"ready_to_jump")
	await _anim.animation_finished
	speed.x = absf(_speed_x) * dir
	jump(jumping_speed)
	
	await collided_floor
	_vis_enbl.enable_node_path = _vis_enbl_npth_cache
	Audio.play_sound(sound_bump, self)
	_speed_x = speed.x
	speed.x = 0
	_atk_itrvl.start(attack_period_interval)
