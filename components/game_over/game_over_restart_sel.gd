extends MenuSelection

@onready var pause: Control = $"../.."
@onready var _tweak: bool = SettingsManager.get_tweak("load_save_from_world_start", false)
var current_world: String

func setup_button() -> void:
	current_world = ProfileManager.current_profile.data.get("current_world", "")
	if Data.values.get("map_force_selected_marker", ""):
		current_world = ""
	modulate.v = 0.4 if current_world.is_empty() else 1.0

func _handle_select(mouse_input: bool = false) -> void:
	if current_world.is_empty():
		return
	if _tweak:
		ProfileManager.current_profile.data.completed_levels = []
	Data.technical_values.remaining_continues = ProjectSettings.get_setting(
		"application/thunder_settings/player/gameover_continues", -1
	)
	super(mouse_input)
	pause.toggle(true)
	Data.technical_values.impulse_progress_continue = true
	Scenes.goto_scene(current_world)
