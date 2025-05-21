extends MenuSelection

@export var block_if_no_continues: bool = false
@export var use_skinned_hud_pause_close_sfx: bool = false

@onready var pause: Control = $"../.."
@onready var old_selected_sound = selected_sound

func _handle_select(mouse_input: bool = false) -> void:
	if block_if_no_continues && Data.technical_values.remaining_continues == 0:
		return
	super(mouse_input)
	pause.toggle(false)

func _play_sound() -> void:
	if !use_skinned_hud_pause_close_sfx: return super()
	
	var _sfx := CharacterManager.get_sound_replace(selected_sound, old_selected_sound, "hud_pause_close", false)
	Audio.play_1d_sound(_sfx, true, { "ignore_pause": true, "bus": "1D Sound" })
