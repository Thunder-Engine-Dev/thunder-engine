extends HBoxContainer

@export var interval: float = 3
@export var initial_interval: float = 1
@export_group("Flameball")
@export var flameball: InstanceNode2D
@export var speed: float = 250
@export var amount: float = 25
@export var flame_interval: float = 0.05
@export_group("Sound")
@export var sound: AudioStream = preload("res://engine/objects/enemies/flameball_launcher/sound/flameball.ogg")

var _amount: int

@onready var timer_interval: Timer = $Interval
@onready var timer_interval_flame: Timer = $IntervalFlame
@onready var timer_interval_sound: Timer = $IntervalSound
@onready var pos_flameball: Marker2D = $PosFlameball


func _ready() -> void:
	timer_interval.start(initial_interval)


func _on_interval_timeout() -> void:
	_amount = amount
	timer_interval_flame.start(flame_interval)


func _on_interval_flame_timeout() -> void:
	_amount -= 1
	NodeCreator.prepare_ins_2d(flameball, pos_flameball).bind_global_transform().create_2d().call_method(
		func(ball: Node2D) -> void:
			if ball is Projectile:
				ball.global_rotation = 0
				ball.vel_set(Vector2.RIGHT.rotated(get_global_transform().get_rotation()) * -speed)
				ball.belongs_to = Data.PROJECTILE_BELONGS.ENEMY
			ball.reparent.call_deferred(get_parent())
			Thunder.reorder_on_top_of.call_deferred(ball, self)
	)
	if _amount <= 0:
		timer_interval.start(interval)
		timer_interval_flame.stop()
		timer_interval_sound.stop()
		return
	if timer_interval_sound.is_stopped():
		timer_interval_sound.start(0.2)


func _on_interval_sound_timeout() -> void:
	Audio.play_sound(sound, pos_flameball)
