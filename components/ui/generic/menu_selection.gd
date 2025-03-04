extends Control
class_name MenuSelection
## This class represents the menu item

## Is this item currently selected?
var focused: bool = false
## Is this item currently hovered under mouse cursor?
var mouse_hovered: bool = false
## Played when player selects this item
@export var selected_sound: AudioStream = preload("res://engine/components/ui/_sounds/select_enter.wav")
## Trigger action name
@export var trigger_action: StringName = "ui_accept"
## Mouse input is passed
@export var trigger_mouse: bool = true

## Focus handler
func _handle_focused(focus: bool) -> void:
	focused = focus

## Called when this item has been selected, extend this
func _handle_select(mouse_input: bool = false) -> void:
	if selected_sound:
		Audio.play_1d_sound(selected_sound, true, { "ignore_pause": true, "bus": "1D Sound" })

## Called when right clicked on this item if mouse trigger is enabled, extend this
func _handle_right_click() -> void:
	pass


func _physics_process(delta: float) -> void:
	if !focused || !get_parent().focused: return
	if !get_window().has_focus(): return

	if Input.is_action_just_pressed(trigger_action):
		_handle_select(false)
