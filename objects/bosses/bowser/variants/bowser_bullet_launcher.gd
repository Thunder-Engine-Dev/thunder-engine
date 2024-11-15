extends "res://engine/objects/bosses/bowser/bowser.gd"

@export var bullet_bill: InstanceNode2D
@export var explosion: PackedScene
@export var bullet_speed: float
@export_group("Sound")
@export var shooting_sound: AudioStream = preload("res://engine/objects/enemies/bullet_bill/bill/sounds/bullet.ogg")
@export var sound_pitch_min: float = 1.0
@export var sound_pitch_max: float = 1.2
@export var sound_volume: float = -4

@onready var launcher: Sprite2D = $Launcher
@onready var pos_bullet: Marker2D = $Launcher/PosBullet
@onready var launcher_x: float = launcher.position.x

func _physics_process(delta: float) -> void:
	launcher.position.x = launcher_x * facing
	super(delta)

func _on_bullet_launched() -> void:
	var dir: int
	dir = Thunder.Math.look_at(pos_bullet.global_position, player.global_position, pos_bullet.global_transform)
	
	Audio.play_sound(
		shooting_sound, pos_bullet, false, {
			"pitch": randf_range(sound_pitch_min, sound_pitch_max),
			"volume": sound_volume,
		}
	)
	NodeCreator.prepare_ins_2d(bullet_bill, self).create_2d(false).call_method(
		func(bul: Node2D) -> void:
			bul.global_transform = pos_bullet.global_transform
			if bul is GeneralMovementBody2D:
				bul.look_at_player = false
				bul.vel_set(Vector2.RIGHT * bullet_speed * dir)
				var enemy_attacked: Node = bul.get_node_or_null("EnemyAttacked")
				if !enemy_attacked: return
				enemy_attacked.stomping_standard = enemy_attacked.stomping_standard.rotated(-bul.global_rotation)
	)
	NodeCreator.prepare_2d(explosion, pos_bullet).create_2d().bind_global_transform(Vector2.RIGHT * 16 * dir)


func attack(state: StringName) -> void:
	super(state)
	if state == "bullet":
		_on_bullet_launched()
