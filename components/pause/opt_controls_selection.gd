extends MenuSelection

func _handle_select() -> void:
	var scene = Scenes.custom_scenes.pause.get_parent()
	super()
	scene.offset.x -= 640
	await get_tree().physics_frame
	scene.get_node("Settings/SubViewportContainer/SubViewport/Options").focused = false
	scene.get_node("Controls/Options").focused = true
