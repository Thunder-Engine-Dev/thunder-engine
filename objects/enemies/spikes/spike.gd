extends Area2D

@export_category("Spike")
@export_enum("Nothing: 0", "Hurt: 1", "Death: 2") var type: int = 1


func _physics_process(delta: float) -> void:
	for i in get_overlapping_bodies():
		if i == Thunder._current_player:
			match type:
				1: i.hurt()
				2: i.die()
