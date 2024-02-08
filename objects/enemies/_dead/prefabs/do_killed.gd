extends ByNodeScript

var dir: int
var enemy_attacked: Node
var attacker_speed: Vector2

func _ready() -> void:
	enemy_attacked = vars.enemy_attacked as Node
	if enemy_attacked.has_meta(&"attacker_speed"):
		attacker_speed = enemy_attacked.get_meta(&"attacker_speed")
	var death: NodePath = vars.death as NodePath
	var speed: Vector2 = vars.death_speed as Vector2
	
	if !enemy_attacked || death.is_empty(): return
	
	var death_node: Node2D = enemy_attacked.get_node_or_null(death).duplicate()
	if !death_node: return
	
	if !attacker_speed:
		#_wait_for_meta()
		attacker_speed = Vector2.ZERO
	
	death_node.visible = true
	death_node.set(&"speed_scale", 0)
	if &"flip_v" in death_node: death_node.flip_v = true
	if attacker_speed != Vector2.ZERO && node is GravityBody2D:
		fancy_death_effect()
	else:
		if node is GravityBody2D: node.speed = speed
	node.add_child(death_node)
	
#func _wait_for_meta() -> void:
#	await Thunder.get_tree().physics_frame
#	if enemy_attacked.has_meta(&"attacker_speed"):
#		attacker_speed = enemy_attacked.get_meta(&"attacker_speed")
#		fancy_death_effect()

func fancy_death_effect() -> void:
	node.speed = Vector2(125, -300)
	dir = sign(attacker_speed.x)
	node.speed.x *= dir
	node.gravity_scale *= 2.5
	if &"rotating_dir" in node:
		node.rotating_dir = dir
	
