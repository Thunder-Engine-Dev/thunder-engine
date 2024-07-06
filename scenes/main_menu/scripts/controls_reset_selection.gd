extends MenuSelection

func _handle_select() -> void:
	super()
	
	SettingsManager.settings.controls = SettingsManager.default_settings.controls.duplicate(true)
	SettingsManager._load_keys()
