extends MenuSelection

func _handle_select() -> void:
	var scene = Scenes.custom_scenes.pause.get_parent()
	
	super()
	scene.offset.x += 640
	await get_tree().physics_frame
	get_parent().move_selector(0)
	scene.get_node("Settings/SubViewportContainer/SubViewport/Options").focused = true
	scene.get_node("Controls/Options").focused = false
