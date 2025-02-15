extends MenuSelection

@onready var pause: Control = $"../.."

func _handle_select(mouse_input: bool = false) -> void:
	if Data.technical_values.remaining_continues == 0:
		return
	super(mouse_input)
	pause.toggle(false)
