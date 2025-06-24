extends Resource
class_name PlayerSuitProjectile

@export var projectile: InstanceNode2D
@export var speed: Vector2
@export var amount: int = 2
@export var amount_extra: int = -1
@export var sound_attack: AudioStream = preload("res://engine/objects/projectiles/sounds/shoot.wav")


func create_projectile(player: Player) -> Node2D:
	if !player: return
	
	return NodeCreator.prepare_ins_2d(projectile, player).create_2d().call_method(
		func(bull: Node2D) -> void:
			if bull is GravityBody2D:
				bull.vel_set(speed * Vector2(player.direction, 1))
			bull.set_meta(&"uid", resource_path)
	).get_node() as Node2D
