extends MenuSelection

var starting: bool = false

func _handle_select() -> void:
	if starting: return
	super()
	starting = true
	get_parent().focused = false
