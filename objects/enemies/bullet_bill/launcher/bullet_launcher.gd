extends AnimatableBody2D

@export_category("BulletBillLauncher")
@export_group("Bullet")
@export var bullet_bill: InstanceNode2D
@export var explosion: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
@export var bullet_speed: float = 195
@export_group("Shooting")
@export var stop_shooting_radius: float = 80
@export var first_shooting: float = 0.42
@export var shooting_delay_min: float = 1.25
@export var shooting_delay_max: float = 2.5
@export_group("Sound")
@export var shooting_sound: AudioStream = preload("../bill/sounds/bullet.ogg")

@onready var launcher: Sprite2D = $Launcher
@onready var pos_bullet: Marker2D = $Launcher/PosBullet
@onready var interval: Timer = $Interval


func _ready() -> void:
	interval.start(first_shooting)


func _on_bullet_launched() -> void:
	var player: Player = Thunder._current_player
	if !player:
		interval.start(0.1)
		return
	
	if player.global_position.distance_squared_to(global_position) <= stop_shooting_radius ** 2:
		interval.start(0.1)
		return
	
	var dir: int = Thunder.Math.look_at(pos_bullet.global_position, player.global_position, pos_bullet.global_transform)
	Audio.play_sound(shooting_sound, pos_bullet, false)
	NodeCreator.prepare_ins_2d(bullet_bill, pos_bullet).create_2d().bind_global_transform().call_method(
		func(bul: Node2D) -> void:
			if bul is GeneralMovementBody2D:
				bul.look_at_player = false
				bul.vel_set(Vector2.RIGHT * bullet_speed * dir)
				bul.z_index -= 1
	)
	NodeCreator.prepare_2d(explosion, pos_bullet).create_2d().bind_global_transform(Vector2.RIGHT * 16 * dir)
	interval.start(randf_range(shooting_delay_min, shooting_delay_max))


func _on_screen_entered() -> void:
	interval.paused = false


func _on_screen_exited() -> void:
	interval.paused = true
