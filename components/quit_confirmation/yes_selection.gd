extends MenuSelection

func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)
	get_tree().quit()
