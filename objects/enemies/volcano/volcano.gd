extends Node2D

@export var initial_fire_delay: float = 1
@export var fire_interval: float = 5
@export var volcano_ball_amount: int = 12
@export var volcano_ball_fire_interval: float = 0.03

const VOLCANO_BALL = preload("res://engine/objects/projectiles/volcano_ball/volcano_ball.tscn")
const VOLCANO_FIRE = preload("res://engine/objects/enemies/volcano/volcano_fire.ogg")

@onready var visible_on_screen_enabler_2d: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D
@onready var timer: Timer = $Timer
@onready var marker_2d: Marker2D = $Marker2D

func _ready() -> void:
	#await get_tree().create_timer(initial_fire_delay, false, true).timeout
	timer.start(initial_fire_delay)
	timer.timeout.connect(_fire)


func _fire() -> void:
	timer.start(fire_interval)
	
	#if !Thunder.view.is_getting_closer(self, 32): return
	
	Audio.play_sound(VOLCANO_FIRE, self)
	
	var _amount = volcano_ball_amount
	while _amount > 0:
		NodeCreator.prepare_2d(VOLCANO_BALL, marker_2d).bind_global_transform().call_method(
			func(ball):
				ball.speed.x = randi_range(-5, 5) * 50
				ball.speed.y = randf_range(14, 16) * -50
				ball.belongs_to = Data.PROJECTILE_BELONGS.ENEMY
		).create_2d()
		await get_tree().create_timer(volcano_ball_fire_interval, false, true).timeout
		_amount -= 1
