extends MenuSelection

func _handle_select() -> void:
	super()
	GlobalViewport.vp.get_camera_2d().position.y -= 480
	await get_tree().physics_frame
	get_parent().move_selector(0)
	Scenes.current_scene.get_node(get_parent().get_parent().main_menu_controls).focused = true
	Scenes.current_scene.get_node("Settings/Options").focused = false
	
	SettingsManager.save_settings()
