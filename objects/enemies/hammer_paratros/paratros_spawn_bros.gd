extends ByNodeScript


func _ready() -> void:
	# node => Hammer Bros
	if node.has_node("Body/EnemyAttacked"):
		node.get_node("Body/EnemyAttacked").stomping_delay.call_deferred()
	
	node.set_deferred(&"posx", vars.enemy_attacked.owner.global_transform.affine_inverse().basis_xform(vars.enemy_attacked.owner.global_position).x)
