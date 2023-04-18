extends Control
class_name MenuSelection
## This class represents the menu item

## Is this item currently selected?
var focused: bool = false
## Played when player selects this item
@export var selected_sound: AudioStream = preload("res://engine/components/ui/_sounds/select_enter.wav")
## Trigger action name
@export var trigger_action: StringName = "ui_accept"

## Focus handler
func _handle_focused(focus: bool) -> void:
	focused = focus

## Called when this item has been selected, extend this
func _handle_select() -> void:
	if selected_sound:
		Audio.play_1d_sound(selected_sound)


func _input(event: InputEvent) -> void:
	if !focused: return
	if !event.is_pressed(): return
	
	if event.is_action(trigger_action):
		_handle_select()
