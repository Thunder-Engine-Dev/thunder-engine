extends Area2D

@export_category("Spike")
@export_enum("Nothing: 0", "Hurt: 1", "Death: 2") var type: int = 1


func _physics_process(delta: float) -> void:
	var player: Player = Thunder._current_player
	if !player: return
	if overlaps_body(player) && !player.is_starman() && !player.is_invincible():
		match type:
			1: player.hurt()
			2: player.die()
