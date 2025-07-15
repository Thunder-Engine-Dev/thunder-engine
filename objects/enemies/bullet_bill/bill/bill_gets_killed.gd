extends ByNodeScript

var attacker_speed: Vector2

func _ready() -> void:
	var enemy_attacked: Node = vars.enemy_attacked as Node
	var death: NodePath = vars.death as NodePath
	
	if !enemy_attacked || death.is_empty(): return
	
	var death_node: Node2D = enemy_attacked.get_node_or_null(death).duplicate()
	if !death_node: return
	
	if enemy_attacked.has_meta(&"attacker_speed"):
		attacker_speed = enemy_attacked.get_meta(&"attacker_speed")
	
	death_node.visible = true
	if node is GravityBody2D && enemy_attacked.owner is GravityBody2D:
		node.gravity_dir = Vector2.DOWN#.rotated(-enemy_attacked.owner.global_rotation)
		if attacker_speed:
			var dir: int = sign(attacker_speed.x)
			node.speed.x *= dir
			if &"rotating_dir" in node:
				node.rotating_dir = dir
		else:
			node.speed = enemy_attacked.owner.speed
		
		if SettingsManager.settings.quality == SettingsManager.QUALITY.MIN:
			node.gravity_scale *= 2
			node.scale.y = -node.scale.y
		elif !attacker_speed:
			node.speed = enemy_attacked.owner.speed * 0.5
			
	node.add_child(death_node)
