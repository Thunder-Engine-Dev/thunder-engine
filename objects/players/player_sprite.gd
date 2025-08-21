extends Node2D

func _ready() -> void:
	_set_pos.call_deferred()
	reset_physics_interpolation.call_deferred()

func _physics_process(_delta: float) -> void:
	_set_pos()

func _set_pos() -> void:
	var node = Thunder._current_player
	if !is_instance_valid(node): return
	global_position = node.global_position.round()
	global_rotation = node.global_rotation
	visible = node.visible
	scale = node.scale
