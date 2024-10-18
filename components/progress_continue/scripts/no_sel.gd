extends MenuSelection

@export var cancel: bool = true

@onready var pause: Control = $"../.."

func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)
	pause.trigger_pipe()
	pause.toggle(false)
	pause.v_box_container.focused = false
