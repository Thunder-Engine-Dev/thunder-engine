extends MenuSelection

func _handle_select() -> void:
	super()
	Scenes.custom_scenes.pause.get_parent().offset.y += 480
	await get_tree().physics_frame
	get_parent().move_selector(0)
	Scenes.custom_scenes.pause.get_node("VBoxContainer").focused = true
	Scenes.custom_scenes.pause.get_node("../Settings/SubViewportContainer/SubViewport/Options").focused = false
	
	SettingsManager.save_settings()
