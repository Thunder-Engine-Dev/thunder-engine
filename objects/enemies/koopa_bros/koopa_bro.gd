extends GravityBody2D

@export_category("Koopa Bro")
@export_group("Physics")
@export var moving_radius_min: float = 16
@export var moving_radius_max: float = 64
@export var moving_duration_min: float = 0.2
@export var moving_duration_max: float = 2
@export var jumping_frequency: int = 20
@export var jumping_strength_upward: float = 400
@export var jumping_strength_downward: float = 150
@export_group("Attack")
@export var attacking_count_unit: float = 0.06
@export var attacking_chance: float = 0.09
@export var attacking_delay: float = 0.6

var dir: int

var _dir: int
var _step_moving: int
var _step_attacking: int
var _speed: float
var _radius: float
var _duration: float

var _jump: int
var _jump_count: int
var _jump_up: bool
var _jump_down: bool

var _collision_mask: int

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var timer_walk: Timer = $Walk
@onready var timer_attack: Timer = $Attack

@onready var posx: float = global_transform.affine_inverse().basis_xform(global_position).x
@onready var pos_attack: Marker2D = $PosAttack
@onready var pos_attack_x: float = pos_attack.position.x


func _physics_process(delta: float) -> void:
	_direction()
	_bro_movement(delta)
	motion_process(delta)


func _direction() -> void:
	var player: Player = Thunder._current_player
	if !player: return
	dir = Thunder.Math.look_at(global_position, player.global_position, global_transform)
	sprite.flip_h = (dir < 0 && dir != 0)


func _bro_movement(delta: float) -> void:
	var cposx: float = global_transform.affine_inverse().basis_xform(global_position).x
	match _step_moving:
		0:
			_dir = dir
			_radius = moving_radius_max
			_duration = moving_duration_max
			_step_moving = 1
			vel_set_x(speed.x * _dir)
		1:
			if is_on_wall() || (cposx < posx - _radius && _dir < 0) || (cposx > posx + _radius && _dir > 0):
				_speed = absf(speed.x)
				vel_set_x(0)
				_step_moving = 2
				timer_walk.start(_duration)


func _bro_jump() -> void:
	if _collision_mask > 0 && ((_jump == 1 && speed.y >= 0) || (_jump == 2 && speed.y >= jumping_strength_downward + 90)):
		collision_mask = _collision_mask
		_collision_mask = 0
	if _jump in [1, 2]:
		return
	
	_jump_count = randi_range(0, jumping_frequency)
	
	if _jump_count == 1 && _jump_up:
		_jump = 1
	elif _jump_count == 2 && _jump_down:
		_jump = 2
		
	if _jump == 1:
		jump(jumping_strength_upward)
	elif _jump == 2:
		jump(jumping_strength_downward)
	if _jump > 0:
		_collision_mask = collision_mask
		collision_mask = 0
	
	await collided_floor
	_jump = 0


func _on_walk_timeout() -> void:
	_dir *= -1
	_radius = randf_range(moving_radius_min, moving_radius_max)
	_duration = randf_range(moving_duration_min, moving_duration_max)
	_step_moving = 1
	vel_set_x(_speed * _dir)


func _on_attack_timeout() -> void:
	pass


func _on_jump() -> void:
	_bro_jump()
