extends ByNodeScript


func _ready() -> void:
	var enemy_attacked: Node = vars.enemy_attacked as Node
	var death: NodePath = vars.death as NodePath
	
	if !enemy_attacked || death.is_empty(): return
	
	var death_node: Node2D = enemy_attacked.get_node_or_null(death).duplicate()
	if !death_node: return
	
	death_node.visible = true
	if node is GravityBody2D && enemy_attacked.owner is GravityBody2D:
		node.speed = enemy_attacked.owner.speed * 0.5
		node.gravity_dir = Vector2.DOWN.rotated(-enemy_attacked.owner.global_rotation)
	node.add_child(death_node)
