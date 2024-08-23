extends MenuSelection

func _handle_select() -> void:
	super()
	var scene: Node = Scenes.custom_scenes.pause.get_parent()
	scene.offset.y -= 480
	scene.reset_physics_interpolation()
	await get_tree().physics_frame
	scene.get_node("Pause/VBoxContainer").focused = false
	scene.get_node("Settings/SubViewportContainer/SubViewport/Options").focused = true
