extends ByNodeScript



func _physics_process(delta: float) -> void:
	var player = Thunder._current_player
	if !player.is_on_floor() && Input.is_action_pressed(player.config.control_jump) && player.velocity_local.y < 0:
		if abs(player.velocity_local.x) < 1:
			player.velocity_local.y -= 10 * Thunder.get_delta(delta)
		else:
			player.velocity_local.y -= 5 * Thunder.get_delta(delta)
	pass
