extends Node2D

const PODOBOO = preload("res://engine/objects/enemies/podoboo/podoboo.tscn")

@export var SHOOT_SOUND: AudioStream = preload("res://engine/objects/projectiles/sounds/shoot.wav")

@export var launch_initial_delay: float = 0.5
@export var launch_delay: float = 6
@export var launch_interval: float = 0.3
@export var launch_amount: int = 8

@export var podoboo_jumping_height: int = 256
@export var podoboo_min_speed: int = -5
@export var podoboo_max_speed: int = 5
@export var podoboo_speed_multiplicator: float = 50.0

@export var no_rng_enabled: bool = false
@export var no_rng_starting_pos: int = 1
@export var no_rng_step: int = 1

@onready var timer: Timer = $Timer
@onready var shoot_timer: Timer = $ShootTimer
@onready var podoboo_icon = $Podoboo

var _remaining_amount: int
var _fair_index: int


func _ready() -> void:
	if no_rng_enabled:
		_fair_index = no_rng_starting_pos
	_interval(true)
	podoboo_icon.queue_free()


func _interval(init: bool = false) -> void:
	timer.start(launch_initial_delay if init else launch_delay)
	Thunder._connect(timer.timeout, _shoot_start, CONNECT_ONE_SHOT)


func _shoot_start() -> void:
	_remaining_amount = launch_amount
	shoot_timer.start(launch_interval)
	Thunder._connect(shoot_timer.timeout, _shoot)


func _shoot() -> void:
	if _remaining_amount <= 0:
		shoot_timer.stop()
		_interval(false)
		return
	
	Audio.play_sound(SHOOT_SOUND, self)
	
	var computed_x_speed: int
	if no_rng_enabled:
		computed_x_speed = _fair_index * podoboo_speed_multiplicator
	else:
		computed_x_speed = Thunder.rng.get_randi_range(podoboo_min_speed, podoboo_max_speed) * podoboo_speed_multiplicator
	
	var projectile = PODOBOO.instantiate()
	projectile.global_position = global_position
	projectile.one_shot = true
	projectile.jumping_height = podoboo_jumping_height
	projectile.interval = 0
	projectile.jumping = true
	projectile.vel_set_x(computed_x_speed)
	projectile._on_jump()
	
	Scenes.current_scene.add_child(projectile)
	
	_remaining_amount -= 1
	if no_rng_enabled:
		# Pattern like this: 0 => -1 => 1 => -2 => 2 etc.
		if _fair_index == 0: _fair_index = -no_rng_step
		elif _fair_index < 0: _fair_index = -_fair_index
		else: _fair_index = -_fair_index - no_rng_step
		
		if _fair_index < podoboo_min_speed || _fair_index > podoboo_max_speed:
			_fair_index = 0
