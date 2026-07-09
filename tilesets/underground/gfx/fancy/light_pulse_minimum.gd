extends AnimatedSprite2D

func _ready() -> void:
	await get_tree().create_timer(randf_range(0.1, 1.0), false).timeout
	var tw = create_tween().set_loops()
	tw.tween_property(self, "modulate:a", 0.392, 2.0)
	tw.tween_property(self, "modulate:a", 0.78, 2.0)
