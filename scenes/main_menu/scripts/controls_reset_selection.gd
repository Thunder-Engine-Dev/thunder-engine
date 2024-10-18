extends MenuSelection


func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)

	if SettingsManager.device_keyboard:
		SettingsManager.settings.controls = SettingsManager.default_settings.controls.duplicate(true)
	else:
		SettingsManager.settings.controls_joypad = SettingsManager.default_settings.controls_joypad.duplicate(true)
	SettingsManager._load_keys()
