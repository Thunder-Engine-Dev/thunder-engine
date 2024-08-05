extends Node

func _ready() -> void:
	Data.reset_all_values()
	ProfileManager.create_new_profile(&"debug")
