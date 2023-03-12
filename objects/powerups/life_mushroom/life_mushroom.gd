extends Powerup

func collect() -> void:
	Thunder.add_lives(1)
	Audio.play_sound(preload("res://engine/objects/mario/sounds/1up.wav"), self)
	queue_free()
