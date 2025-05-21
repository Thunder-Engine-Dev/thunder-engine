extends Powerup

func collect() -> void:
	Thunder.add_lives(1)
	var _sfx = CharacterManager.get_sound_replace(Data.LIFE_SOUND, Data.LIFE_SOUND, "1up", false)
	Audio.play_sound(_sfx, self)
	queue_free()
