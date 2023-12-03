extends MenuSelection


func _handle_select() -> void:
	GlobalViewport.vp.get_camera_2d().position.y += 480
	Scenes.current_scene.get_node("Menu/MainMenuControls").focused = false
	Scenes.current_scene.get_node("Settings/Options").focused = true
