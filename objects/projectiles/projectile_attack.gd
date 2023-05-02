extends ShapeCast2D

@export var killer_type: StringName = Data.ATTACKERS.fireball
@export var killing_detection_scale: float = 1.0
@export var special_tags: Array[StringName]

var velocity: Vector2
var belongs_to: Data.PROJECTILE_BELONGS

@onready var par:Node2D = get_parent()

signal killed(what: Node, result: Dictionary)
signal killed_notify
signal killed_succeeded
signal killed_failed
signal damaged_player


func _process(delta: float) -> void:
	if par is GravityBody2D:
		velocity = par.velocity
		target_position = (velocity * get_physics_process_delta_time() * killing_detection_scale).rotated(-global_rotation)
	
	if &"belongs_to" in par: belongs_to = par.belongs_to
	
	match belongs_to:
		Data.PROJECTILE_BELONGS.PLAYER: _kill_enemy()
		Data.PROJECTILE_BELONGS.ENEMY: _hurt_player()



func _kill_enemy() -> void:
	var result:Dictionary 
	for i in get_collision_count():
		var ins:Area2D = get_collider(i) as Area2D
		if !ins || ins.get_parent() == get_parent(): continue
		
		var enemy_attacked:Node = ins.get_node_or_null(^"EnemyAttacked")
		if !enemy_attacked: continue
		
		result = enemy_attacked.got_killed(killer_type, special_tags)
	if result.is_empty(): return
	var attackee: Node = result.attackee if &"attackee" in result else null
	if result.result:
		killed_notify.emit()
		killed.emit(attackee, result)
		killed_succeeded.emit()
		return
	else:
		killed_notify.emit()
		killed.emit(attackee, result)
		killed_failed.emit()
		return

func _hurt_player() -> void:
	for i in get_collision_count():
		var ins:PhysicsBody2D = get_collider(i) as PhysicsBody2D
		if !ins: continue
		elif ins is Player:
			damaged_player.emit()
			ins.hurt()
			break
