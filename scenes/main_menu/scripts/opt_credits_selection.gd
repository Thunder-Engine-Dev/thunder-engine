extends MenuSelection

func _handle_select() -> void:
	super()
	SettingsManager.save_settings()
	Scenes.goto_scene(ProjectSettings.get_setting("application/thunder_settings/credits_path"))
