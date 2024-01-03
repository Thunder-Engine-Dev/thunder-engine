extends MenuSelection

var toggle_sound = preload("res://engine/scenes/main_menu/sounds/change.wav")
var is_custom: bool = false

func _physics_process(delta: float) -> void:
	super(delta)
	if (
		(fmod(GlobalViewport.container.scale.x, 0.5) == 0 ||
		fmod(GlobalViewport.container.scale.y, 0.5) == 0)
	):
		$Value.texture.region.position.y = 38 * (-1 + GlobalViewport.container.scale.x * 2)
		is_custom = true
	else:
		$Value.texture.region.position.y = 0
		is_custom = false
		
	if !focused: return
	
	if Input.is_action_just_pressed("ui_right"):
		if SettingsManager.settings.scale == 0:
			SettingsManager.settings.scale = 1
		else:
			SettingsManager.settings.scale = clamp(SettingsManager.settings.scale + 0.5, 1, 4)
		Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true })
		SettingsManager._process_settings()
		
	if Input.is_action_just_pressed("ui_left"):
		if is_custom: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		SettingsManager.settings.scale = clamp(SettingsManager.settings.scale - 0.5, 1, 4)
		Audio.play_1d_sound(toggle_sound, true, { "ignore_pause": true })
		SettingsManager._process_settings()
	
