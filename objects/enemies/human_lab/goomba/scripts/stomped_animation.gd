extends AnimatedSprite2D

func play_anim() -> void:
	create_tween().tween_property(self, "scale:y", 0.22, 0.1)
