extends MenuSelection

@export var cancel: bool = true

@onready var pause: Control = $"../.."

func _handle_select() -> void:
	super()
	pause.trigger_pipe()
	pause.toggle(false)
	pause.v_box_container.focused = false
