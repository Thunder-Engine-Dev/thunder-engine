extends MenuSelection

@onready var restart_popup: Control = $"../../../../RestartPopup/Control"

func _handle_select(mouse_input: bool = false) -> void:
	if Data.technical_values.get("credits_cooldown", 0.0) > Time.get_ticks_msec():
		return
	super(mouse_input)
	Scenes.current_scene.get_node("Settings/SubViewportContainer/SubViewport/Options").focused = false
	await get_tree().physics_frame
	if !SettingsManager.request_restart:
		_screen_back()
	Scenes.current_scene.get_node("Settings/SubViewportContainer/SubViewport/Options").focused = false
	
	SettingsManager.save_settings()
	
	if SettingsManager.request_restart:
		restart_popup.toggle()
		await restart_popup.closed
		if SettingsManager.request_restart:
			await get_tree().physics_frame
			SettingsManager.restart_application()
		else:
			_screen_back()

func _screen_back() -> void:
	GlobalViewport.vp.get_camera_2d().position.y -= 480
	GlobalViewport.vp.get_camera_2d().reset_physics_interpolation()
	Scenes.current_scene.get_node(get_parent().get_parent().get_parent().get_parent().main_menu_controls).focused = true
	get_parent().move_selector(0)
