extends Control
class_name MenuSelection
## This class represents the menu item

const LETS = preload("res://engine/scenes/main_menu/sounds/lets.wav")
const SELECT_ENTER = preload("res://engine/components/ui/_sounds/select_enter.wav")

## Is this item currently selected?
var focused: bool = false
## Is this item currently hovered under mouse cursor?
var mouse_hovered: bool = false
## Played when player selects this item
@export var selected_sound: AudioStream = SELECT_ENTER
## Trigger action name
@export var trigger_action: StringName = "ui_accept"
## Mouse input is passed
@export var trigger_mouse: bool = true

## Focus handler
func _handle_focused(focus: bool) -> void:
	focused = focus

## Called when this item has been selected, extend this
func _handle_select(mouse_input: bool = false) -> void:
	_play_sound()

## Called when right clicked on this item if mouse trigger is enabled, extend this
func _handle_right_click() -> void:
	pass


func _play_sound() -> void:
	if selected_sound:
		var _sfx = selected_sound
		if _sfx == LETS:
			_sfx = CharacterManager.get_sound_replace(LETS, LETS, "menu_start_song", false)
		else:
			_sfx = CharacterManager.get_sound_replace(selected_sound, SELECT_ENTER, "menu_enter", false)
		Audio.play_1d_sound(_sfx, true, { "ignore_pause": true, "bus": "1D Sound" })

func _physics_process(delta: float) -> void:
	if !focused || !get_parent().focused: return
	if !get_window().has_focus(): return

	if Input.is_action_just_pressed(trigger_action):
		_handle_select(false)
