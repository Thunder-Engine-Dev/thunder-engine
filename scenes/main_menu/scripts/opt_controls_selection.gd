extends MenuSelection

func _handle_select() -> void:
	var scene = get_parent().get_parent().get_parent()
	
	super()
	GlobalViewport.vp.get_camera_2d().position.x += 640
	await get_tree().physics_frame
	Scenes.current_scene.get_node("Settings/Options").focused = false
	Scenes.current_scene.get_node("Controls/Options").focused = true
