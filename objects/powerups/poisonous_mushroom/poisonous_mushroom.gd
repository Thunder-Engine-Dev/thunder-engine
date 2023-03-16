extends Powerup

const explosion_effect = preload("res://engine/objects/effects/explosion/explosion.tscn")

func collect() -> void:
	var player = Thunder._current_player
	
	if player.states.invincible_timer > 0: return
	player.kill()
	
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	queue_free()

