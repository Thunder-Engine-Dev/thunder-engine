extends MenuSelection

func _handle_select() -> void:
	super()
	if !SettingsManager.request_restart:
		GlobalViewport.vp.get_camera_2d().position.y -= 480
		GlobalViewport.vp.get_camera_2d().reset_physics_interpolation()
	await get_tree().physics_frame
	get_parent().move_selector(0)
	Scenes.current_scene.get_node(get_parent().get_parent().get_parent().get_parent().main_menu_controls).focused = true
	Scenes.current_scene.get_node("Settings/SubViewportContainer/SubViewport/Options").focused = false
	
	SettingsManager.save_settings()
	
	if SettingsManager.request_restart:
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true
		await get_tree().create_timer(0.4, true, false, true).timeout
		SettingsManager.restart_application()
