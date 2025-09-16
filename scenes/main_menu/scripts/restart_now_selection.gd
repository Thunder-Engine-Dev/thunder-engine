extends MenuSelection

@export var cancel: bool = true

@onready var pause: Control = $"../.."

func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)
	if cancel:
		SettingsManager.request_restart = false
	pause.toggle(false)
