extends MenuSelection

func _handle_select(mouse_input: bool = false) -> void:
	var scene = Scenes.custom_scenes.pause.get_parent()
	
	super(mouse_input)
	scene.offset.x += 640
	scene.reset_physics_interpolation()
	scene.get_node("Controls/SubViewportContainer/SubViewport/Options").focused = false
	await get_tree().physics_frame
	get_parent().move_selector(0)
	scene.get_node("Settings/SubViewportContainer/SubViewport/Options").focused = true
	scene.get_node("Controls/SubViewportContainer/SubViewport/Options").focused = false
