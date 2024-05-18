extends MenuSelection

@onready var pause: Control = $"../.."


func _handle_select() -> void:
	super()
	get_tree().quit()
