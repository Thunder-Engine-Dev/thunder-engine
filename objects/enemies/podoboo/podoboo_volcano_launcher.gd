extends Node2D

const PODOBOO = preload("res://engine/objects/enemies/podoboo/podoboo.tscn")

@export var SHOOT_SOUND: AudioStream = preload("res://engine/objects/projectiles/sounds/shoot.wav")

@export var launch_delay: float = 6
@export var launch_interval: float = 0.3
@export var launch_amount = 8

@export var podoboo_jumping_height: int = 256
@export var podoboo_min_speed: int = -250
@export var podoboo_max_speed: int = 250

@onready var timer = $Timer
@onready var shoot_timer = $ShootTimer
@onready var podoboo_icon = $Podoboo

var _remaining_amount: int


func _ready() -> void:
	_interval()
	
	podoboo_icon.queue_free()


func _interval() -> void:
	timer.start(launch_delay)
	timer.connect("timeout", _shoot_start, CONNECT_ONE_SHOT)


func _shoot_start() -> void:
	_remaining_amount = launch_amount
	shoot_timer.start(launch_interval)
	shoot_timer.connect("timeout", _shoot)


func _shoot() -> void:
	if _remaining_amount <= 0:
		shoot_timer.stop()
		_interval()
		return
	
	Audio.play_sound(SHOOT_SOUND, self)
	
	var computed_x_speed = randi_range(podoboo_min_speed, podoboo_max_speed)
	
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
