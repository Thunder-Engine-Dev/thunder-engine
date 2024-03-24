extends "res://engine/objects/enemies/_dead/prefabs/do_killed.gd"


func _ready() -> void:
	var body: Node2D = vars.enemy_attacked.owner
	node.body = body.duplicate()
	node.pos = body.global_position
	node.respawn_delay = body.respawn_delay
	node.respawn_offset = body.respawn_offset
	
	super()
