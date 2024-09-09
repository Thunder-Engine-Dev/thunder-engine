extends MenuSelection

@export var cancel: bool = true

@onready var pause: Control = $"../.."

func _handle_select() -> void:
	super()
	if cancel:
		SettingsManager.request_restart = false
	pause.toggle(false)
