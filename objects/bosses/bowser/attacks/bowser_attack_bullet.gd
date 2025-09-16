extends BowserAttack

@export var bullet_bill: InstanceNode2D
@export var explosion: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
@export var bullet_speed: float = 162.5
@export_group("Sound")
@export var shooting_sound: AudioStream = preload("res://engine/objects/enemies/bullet_bill/bill/sounds/bullet.ogg")
@export var sound_pitch_min: float = 1.0
@export var sound_pitch_max: float = 1.2
@export var sound_volume: float = -4

var launcher: Sprite2D
var pos_bullet: Marker2D
var launcher_x: float
var _old_facing: int


func _ready() -> void:
	if !bowser:
		bowser = get_parent()
	launcher = bowser.get_node("Launcher")
	pos_bullet = bowser.get_node("Launcher/PosBullet")
	launcher_x = launcher.position.x


#func _notification(what: int) -> void:
#	if !is_inside_tree(): return
#	if what == NOTIFICATION_PREDELETE && launcher && is_instance_valid(Scenes.current_scene):
#		launcher.cancel_free()
#		launcher.reparent(Scenes.current_scene)
#		launcher.reset_physics_interpolation()
#		launcher.fall()


func _physics_process(delta: float) -> void:
	if !launcher:
		return
		
	launcher.position.x = launcher_x * bowser.facing
	if bowser.facing != _old_facing:
		launcher.reset_physics_interpolation()
		_old_facing = bowser.facing


func start_attack() -> void:
	super()
	middle_attack()


func middle_attack() -> void:
	super()
	if !bullet_bill: return
	
	Audio.play_sound(
		shooting_sound, pos_bullet, false, {
			"pitch": randf_range(sound_pitch_min, sound_pitch_max),
			"volume": sound_volume,
		}
	)
	NodeCreator.prepare_ins_2d(bullet_bill, bowser).create_2d(false).call_method(
		func(bul: Node2D) -> void:
			bul.global_transform = pos_bullet.global_transform
			if bul is GeneralMovementBody2D:
				bul.look_at_player = false
				bul.vel_set(Vector2.RIGHT * bullet_speed * bowser.facing)
				if bul.has_method(&"set_self_modulate_back") && is_instance_valid(bul.sprite_node):
					bul.sprite_node.self_modulate.a = 0.0
					bul.set_self_modulate_back()
				var enemy_attacked: Node = bul.get_node_or_null("Body/EnemyAttacked")
				if enemy_attacked:
					enemy_attacked.stomping_standard = enemy_attacked.stomping_standard.rotated(-bul.global_rotation)
	)
	NodeCreator.prepare_2d(explosion, pos_bullet).create_2d().bind_global_transform(Vector2.RIGHT * 16 * bowser.facing)
	end_attack()


func end_attack() -> void:
	super()
