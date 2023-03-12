extends ByNodeScript


func _ready() -> void:
	var enemy_attacked: Node = vars.enemy_attacked as Node
	var death: NodePath = vars.death as NodePath
	var speed: Vector2 = vars.death_speed as Vector2
	
	if !enemy_attacked || death.is_empty(): return
	
	var death_node: Node2D = enemy_attacked.get_node_or_null(death).duplicate()
	if !death_node: return
	
	death_node.visible = true
	if &"flip_v" in death_node: death_node.flip_v = true
	if node is GravityBody2D: node.speed = speed
	node.add_child(death_node)
