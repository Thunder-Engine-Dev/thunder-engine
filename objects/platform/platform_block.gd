extends StaticBody2D

@onready var _path_follow = $".."

#func _ready() -> void:
	#physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF

# Forward the method call to the main platform script.
func _player_landed(player: Player) -> void:
	get_parent()._player_landed(player)

func _physics_process(_delta: float) -> void:
	global_position = _path_follow.global_position
	
	if "warp_objects_on_end" in _path_follow && !_path_follow.warp_objects_on_end:
		var _edge = _path_follow.warping_edge_ignore_px
		if _path_follow.max_progress < _edge:
			return
		if _path_follow.progress < _edge || _path_follow.progress + _edge > _path_follow.max_progress:
			reset_physics_interpolation()
	
	
