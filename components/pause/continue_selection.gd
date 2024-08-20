extends MenuSelection

@onready var pause: Control = $"../.."

func _handle_select() -> void:
	super()
	pause.toggle(false)
