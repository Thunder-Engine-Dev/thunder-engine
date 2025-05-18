extends Area2D

@export_category("Spike")
@export_enum("Nothing: 0", "Hurt: 1", "Death: 2") var type: int = 1
@export var ignore_starman: bool = true


func _physics_process(delta: float) -> void:
	var player: Player = Thunder._current_player
	if !player: return
	if player.is_starman() && ignore_starman: return
	if overlaps_body(player):
		match type:
			1 when !player.is_invincible(): player.hurt()
			2: player.die()
