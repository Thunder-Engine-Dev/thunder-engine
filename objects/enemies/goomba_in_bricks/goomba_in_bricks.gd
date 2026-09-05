extends GravityBody2D

@export_category("Goomba in Bricks")
@export_range(0, 20, 0.001, "or_greater", "hide_slider", "suffix:s") var attack_period_interval: float = 0.8
@export_range(0, 20, 0.001, "or_greater", "hide_slider", "suffix:s") var attack_initial_delay: float = 0.25
@export_range(0, 2500, 0.1,"or_greater", "hide_slider", "suffix:px/s") var jumping_speed: float = 500
@export var detection_margin := Vector2(160, 240)
@export_group("Sprite", "sprite_")
@export var sprite_goomba: Sprite2D
@export var sprite_bricks: Sprite2D
@export_group("Effect", "effect_")
@export var effect_debris: PackedScene = preload("res://engine/objects/effects/brick_debris/brick_debris.tscn")
@export_group("Sounds", "sound_")
@export var sound_bump: AudioStream = preload("res://engine/objects/projectiles/sounds/stun.wav")
@export var sound_break: AudioStream = preload("res://engine/objects/bumping_blocks/_sounds/break.wav")

var _vis_enbl_npth_cache: NodePath

@onready var _speed_x: float = speed.x
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _atk_itrvl: Timer = $AttackInterval
@onready var _vis_enbl: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D
var _waiting: bool = true


func _ready() -> void:
	speed.x = 0
	
	if sprite_bricks && !Engine.is_editor_hint():
		sprite_bricks.show_behind_parent = false
	
	#_atk_itrvl.timeout.connect(_on_ready_to_jump)
	_atk_itrvl.start(attack_initial_delay)


func _physics_process(delta: float) -> void:
	motion_process(delta)
	if abs(speed.x) > 0.01:
		sprite_goomba.flip_h = speed.x < 0
	
	var p := Thunder._current_player
	if !p:
		return
	if can_jump() && (
		abs(p.global_position.x - global_position.x) < detection_margin.x &&
		abs(p.global_position.y - global_position.y) < detection_margin.y
	):
		_on_ready_to_jump()


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
	if !_waiting:
		return
	
	_waiting = false
	_vis_enbl_npth_cache = _vis_enbl.enable_node_path
	_vis_enbl.enable_node_path = ^""
	var dir := Thunder.Math.look_at(global_position, p.global_position, global_transform)
	if sprite_goomba:
		sprite_goomba.flip_h = dir < 0
	
	_anim.play(&"ready_to_jump", -1, 1.0)
	
	await _anim.animation_finished
	dir = Thunder.Math.look_at(global_position, p.global_position, global_transform)
	speed.x = absf(_speed_x) * dir
	jump(jumping_speed)
	_anim.play(&"ready_to_jump", -1, 0.7)
	_anim.advance(0.1)
	
	await collided_floor
	_waiting = true
	_anim.stop()
	_vis_enbl.enable_node_path = _vis_enbl_npth_cache
	Audio.play_sound(sound_bump, self)
	_speed_x = speed.x
	speed.x = 0
	_atk_itrvl.start(attack_period_interval)


func can_jump() -> bool:
	return _atk_itrvl.is_stopped() && _waiting
