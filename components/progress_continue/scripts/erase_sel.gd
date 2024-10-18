extends MenuSelection

@onready var game_paused_2: TextureRect = $"../../GamePaused/GamePaused2"
@onready var progress_clearing: TextureRect = $"../../GamePaused/GamePaused2/ProgressClearing"

@onready var progress_continue: Control = $"../.."

func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)
	
	ProfileManager.delete_profile("suspended")
	progress_continue.toggle(false)
	progress_continue.trigger_pipe()
	progress_continue.v_box_container.focused = false
