extends MenuSelection

@onready var pause: Control = $"../.."


func _handle_select() -> void:
	super()
	Scenes.custom_scenes.pause._no_unpause = false
	pause.toggle(true)
	#await get_tree().create_timer(0.4).timeout
	Scenes.goto_scene(ProjectSettings.get("application/thunder_settings/save_game_room_path"))
