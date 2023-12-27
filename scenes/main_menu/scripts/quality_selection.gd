extends MenuSelection

var toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")

func _physics_process(delta: float) -> void:
	super(delta)
	if !focused: return
	
	if Input.is_action_just_pressed("ui_right"):
		SettingsManager.settings.quality = clamp(SettingsManager.settings.quality + 1, 0, 2)
		Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true })
		SettingsManager._process_settings()
		
	if Input.is_action_just_pressed("ui_left"):
		SettingsManager.settings.quality = clamp(SettingsManager.settings.quality - 1, 0, 2)
		Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true })
		SettingsManager._process_settings()
	
	if SettingsManager.settings.quality == SettingsManager.QUALITY.MIN:
		$Value.texture.region.position.y = 32
	if SettingsManager.settings.quality == SettingsManager.QUALITY.MID:
		$Value.texture.region.position.y = 64
	if SettingsManager.settings.quality == SettingsManager.QUALITY.MAX:
		$Value.texture.region.position.y = 0
