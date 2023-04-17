extends BoxContainer
## Helps you create vertical and horizontal boxes with selection

## Does this controller currently accept input?
@export var focused: bool = true
## Currently selected item
@export var current_item_index: int = 0
## Control name that triggers the forward selection
@export var control_forward: StringName = "m_down"
## Control name that triggers the backward selection
@export var control_backward: StringName = "m_up"
## Sound of selection
@export var control_sound: AudioStream = preload("res://engine/components/ui/_sounds/select_main.wav")

## Emitted when a selection occurs to update the position of selector
signal selected(item_index: int, item_node: Node2D)


func _input(event: InputEvent) -> void:
	if !focused: return
	if !event.is_pressed(): return
	
	if event.is_action(control_forward) && current_item_index < get_child_count():
		current_item_index += 1
		if control_sound:
			Audio.play_1d_sound(control_sound)
		selected.emit(current_item_index, get_child(current_item_index))
		return
	
	if event.is_action(control_backward) && current_item_index > 0:
		current_item_index -= 1
		if control_sound:
			Audio.play_1d_sound(control_sound)
		selected.emit(current_item_index, get_child(current_item_index))
		return
