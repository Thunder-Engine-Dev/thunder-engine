extends Node

@export var enable_game_over_continues: bool = true

func _ready() -> void:
	Data.reset_all_values()
	ProfileManager.load_all_profiles()
	ProfileManager.create_new_profile(&"debug")
	Scenes.custom_scenes.game_over.skip_to_save = !enable_game_over_continues
	if Thunder.autosplitter.can_reset_on("save_room"):
		Thunder.autosplitter.reset()
	Data.values.skip_progress_continue = true
	Data.technical_values.remaining_continues = ProjectSettings.get_setting(
		"application/thunder_settings/player/gameover_continues", -1
	)
