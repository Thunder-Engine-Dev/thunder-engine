extends MenuSelection

@onready var pause: Control = $"../.."

func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)
	pause.toggle(false)
