extends ByNodeScript


func _ready() -> void:
	var min_speed: Vector2 = vars.get(&"speed_min", Vector2.ZERO)
	var max_speed: Vector2 = vars.get(&"speed_max", Vector2.ZERO)
	if node is GravityBody2D:
		node.vel_set(Vector2(
			Thunder.rng.get_randf_range(min_speed.x, max_speed.x) * vars.bro.dir,
			Thunder.rng.get_randf_range(min_speed.y, max_speed.y)
		))
