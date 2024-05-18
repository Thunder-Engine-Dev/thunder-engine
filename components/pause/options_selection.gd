extends MenuSelection

func _handle_select() -> void:
	var scene = get_parent().get_parent().get_parent()
	
	super()
	scene.offset.y -= 480
	await get_tree().physics_frame
	scene.get_node("Pause/VBoxContainer").focused = false
	scene.get_node("Settings/Options").focused = true
