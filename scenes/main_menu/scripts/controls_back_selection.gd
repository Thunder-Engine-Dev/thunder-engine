extends MenuSelection

func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)
	var cam = GlobalViewport.vp.get_camera_2d()
	cam.position.x -= 640
	cam.reset_physics_interpolation()
	Scenes.current_scene.get_node("Controls/SubViewportContainer/SubViewport/Options").focused = false
	await get_tree().physics_frame
	get_parent().move_selector(0)
	Scenes.current_scene.get_node("Settings/SubViewportContainer/SubViewport/Options").focused = true
	Scenes.current_scene.get_node("Controls/SubViewportContainer/SubViewport/Options").focused = false
