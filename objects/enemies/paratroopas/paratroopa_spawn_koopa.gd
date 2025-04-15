extends ByNodeScript


func _ready() -> void:
	# node => Koopa
	if node.has_node("Body/EnemyAttacked"):
		node.get_node("Body/EnemyAttacked").stomping_delay.call_deferred()
	
	if node is GeneralMovementBody2D:
		node.look_at_player = false
		node.dir = (vars.enemy_attacked.owner.get(&"dir"))
		node.speed_to_dir()
	var vision = Thunder.get_child_by_class_name(node, "VisibleOnScreenEnabler2D")
	if vision:
		vision.scale = Vector2.ONE * 8
