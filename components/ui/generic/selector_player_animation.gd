extends AnimatedSprite2D

func _ready() -> void:
	_set_frames.call_deferred()
	SettingsManager.settings_updated.connect(_set_frames)
	CharacterManager.character_updated.connect(_set_frames)
	_blink()


func _blink() -> void:
	get_tree().create_timer(randf_range(1.0, 8.0)).timeout.connect(_blink)
	play(&"default")


func _set_frames() -> void:
	var _skin = SettingsManager.settings.skin
	if !_skin.is_empty() && _skin in SkinsManager.misc_textures && SkinsManager.misc_textures[_skin].get("selector"):
		sprite_frames = SpriteFrames.new()
		sprite_frames.add_frame(&"default", SkinsManager.misc_textures[_skin].selector)
		return
	sprite_frames = CharacterManager.get_misc_texture("selector", "", false)
