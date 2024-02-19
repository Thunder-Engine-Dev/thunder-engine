extends Powerup

const explosion_effect = preload("res://engine/objects/effects/explosion/explosion.tscn")

func collect() -> void:
	if appear_distance: return
	var player = Thunder._current_player
	
	if player.is_invincible(): return
	player.die()
	
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	queue_free()

