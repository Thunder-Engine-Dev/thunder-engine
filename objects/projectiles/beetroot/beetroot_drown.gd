extends Node

func in_water() -> void:
	var beet = $".."
	beet.run_out.emit()
	beet.bounces_left = 0
	beet.collision_mask = 128
	beet.drown = true
	beet.speed.x = 0

func out_of_water() -> void:
	var beet = $".."
	beet.drown = false
