extends Powerup

func collect() -> void:
	var player = Thunder._current_player
	
	if player.states.invincible_timer > 0: return
	player.kill()
	
	ExplosionEffect.new(position)
	queue_free()
