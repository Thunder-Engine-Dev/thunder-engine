extends StaticBody2D

# Forward the method call to the main platform script.
func _player_landed(player: Player) -> void:
	get_parent()._player_landed(player)
