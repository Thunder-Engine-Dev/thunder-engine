extends AnimatedSprite2D

func _ready() -> void:
	_set_frames.call_deferred()
	SettingsManager.settings_updated.connect(_set_frames)
	_blink()


func _blink() -> void:
	get_tree().create_timer(randf_range(1.0, 8.0)).timeout.connect(_blink)
	play(&"default")


func _set_frames() -> void:
	sprite_frames = CharacterManager.get_misc_texture("selector")
