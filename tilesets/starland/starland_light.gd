extends PointLight2D

var rand_pause: float = randf_range(0, 0.1)

func _ready() -> void:
	if rand_pause > 0.05:
		await get_tree().create_timer(rand_pause, false, false, false).timeout
	var tw = create_tween().set_loops()
	tw.tween_property(self, "energy", 0.6, 0.1)
	tw.tween_property(self, "energy", 1.0, 0.15)
