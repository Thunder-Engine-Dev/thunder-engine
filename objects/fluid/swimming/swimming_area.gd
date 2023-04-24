extends Area2D


func _ready() -> void:
	# Player in/out of water
	body_entered.connect(
		func(body: Node2D) -> void:
			if body is Player:
				body.in_water()
				body.states.set_state("swim")
	)
	
	body_exited.connect(
		func(body: Node2D) -> void:
			if body is Player:
				body.out_of_water()
				body.states.set_state("default")
	)
	# Player's head in/out of water
	area_entered.connect(
		func(area: Area2D) -> void:
			if area.get_parent() is Player:
				area.get_parent()._out_of_water = false
	)
	area_exited.connect(
		func(area: Area2D) -> void:
			if area.get_parent() is Player:
				area.get_parent()._out_of_water = true
	)


func _physics_process(delta: float) -> void:
	var player: Player = Thunder._current_player
	if !is_instance_valid(player): return
	if overlaps_body(player):
		player.states.set_state("swim")
