extends SubViewportContainer

func _ready():
	set_process_unhandled_input(true)
func _input(event):
	# fix by ArdaE https://github.com/godotengine/godot/issues/17326#issuecomment-431186323
	for child in get_children():
		if event is InputEventMouse:
			var mouseEvent = event.duplicate()
			mouseEvent.position = get_global_transform_with_canvas().affine_inverse() * event.position
			child.push_input(mouseEvent)
		else:
			child.push_input(event)
