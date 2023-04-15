extends ByNodeScript


func _ready() -> void:
	var body: Node2D = vars.enemy_attacked.owner
	node.body = body.duplicate()
	node.pos = body.global_position
	node.respawn_delay = body.respawn_delay
	
	if vars.get(&"dead_sprite", ^"") != ^"":
		var dspr: Node2D = vars.enemy_attacked.get_node_or_null(vars.dead_sprite).duplicate()
		if !dspr:
			return
		if &"flip_v" in dspr:
			dspr.flip_v = true
		node.add_child(dspr)
