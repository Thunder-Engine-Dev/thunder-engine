extends AnimatableBody2D

@export_category("BulletBillLauncher")
@export_group("Bullet")
@export var bullet_bill: InstanceNode2D
@export var explosion: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
@export var bullet_speed: float = 162.5
@export var bullet_life_time_sec: float = 30
@export_group("Shooting")
@export var stop_shooting_radius: float = 80
@export var first_shooting_delay: float = 0.5
@export var shooting_delay_min: float = 1.5
@export var shooting_delay_max: float = 4.5
@export_enum("Both:0", "Left:-1", "Right:1") var shooting_force_dir: int = 0
@export var shooting_force_no_shoot_on_wrong_dir: bool = true
@export_group("Sound")
@export var shooting_sound: AudioStream = preload("../bill/sounds/bullet.ogg")
@export var sound_pitch_min: float = 1.0
@export var sound_pitch_max: float = 1.2
@export var sound_volume: float = -4

@onready var launcher: Sprite2D = $Launcher
@onready var pos_bullet: Marker2D = $Launcher/PosBullet
@onready var interval: Timer = $Interval
var dir: int


func _ready() -> void:
	interval.start(first_shooting_delay)


func _on_bullet_launched() -> void:
	var player: Player = Thunder._current_player
	if !player:
		interval.start(0.1)
		return
	
	if player.completed: return
	if Data.values.stopwatch > 0: return
	
	var dir_force_no_shoot: bool
	dir = Thunder.Math.look_at(pos_bullet.global_position, player.global_position, pos_bullet.global_transform)
	if shooting_force_dir != 0:
		if dir != shooting_force_dir && shooting_force_no_shoot_on_wrong_dir:
			dir_force_no_shoot = true
		dir = shooting_force_dir
	
	var legacy_not_shooting: bool = ProjectSettings.get_setting("application/thunder_settings/tweaks/legacy_bullet_launcher_not_shooting_range", false)
	var not_allowed_shooting := (
		absf(global_transform.affine_inverse().basis_xform(player.global_position).x - global_transform.affine_inverse().basis_xform(global_position).x) <= stop_shooting_radius \
		if legacy_not_shooting else \
		player.global_position.distance_squared_to(global_position) <= stop_shooting_radius ** 2
	)
	if not_allowed_shooting || dir_force_no_shoot:
		interval.start(0.1)
		return
	
	Audio.play_sound(
		shooting_sound, pos_bullet, false, {
			"pitch": randf_range(sound_pitch_min, sound_pitch_max),
			"volume": sound_volume,
		}
	)
	_create_bullet()
	NodeCreator.prepare_2d(explosion, pos_bullet).create_2d().bind_global_transform(Vector2.RIGHT * 16 * dir)
	interval.start(Thunder.rng.get_randf_range(shooting_delay_min, shooting_delay_max))

func _create_bullet() -> NodeCreator.NodeCreation:
	return NodeCreator.prepare_ins_2d(bullet_bill, self).create_2d(false).call_method(_node_creation_method)

func _node_creation_method(bul: Node2D) -> void:
	bul.global_transform = pos_bullet.global_transform
	if bul is GeneralMovementBody2D:
		bul.life_time = bullet_life_time_sec
		bul.look_at_player = false
		bul.vel_set(Vector2.RIGHT * bullet_speed * dir)
		if bul.has_method(&"set_self_modulate_back") && is_instance_valid(bul.sprite_node):
			bul.sprite_node.self_modulate.a = 0.0
			bul.set_self_modulate_back()
		var enemy_attacked: Node = bul.get_node_or_null("EnemyAttacked")
		if !enemy_attacked: return
		enemy_attacked.stomping_standard = enemy_attacked.stomping_standard.rotated(-bul.global_rotation)

func _on_screen_entered() -> void:
	interval.paused = false


func _on_screen_exited() -> void:
	interval.paused = true
