extends StaticBody2D

@onready var _path_follow = $".."

# Forward the method call to the main platform script.
func _player_landed(player: Player) -> void:
	get_parent()._player_landed(player)

func _physics_process(_delta: float) -> void:
	global_position = _path_follow.global_position.round()
