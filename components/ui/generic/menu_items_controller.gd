extends BoxContainer

@export var current_item_index: int = 0
@export var control_forward: InputEventAction
@export var control_backward: InputEventAction
@export var control_sound: AudioStream = preload("res://engine/components/ui/_sounds/select_main.wav")

signal selected


func _input(event: InputEvent) -> void:
	if event.is_action(control_forward.as_text()) && current_item_index < get_child_count():
		current_item_index += 1
		Audio.play_1d_sound(control_sound)
		selected.emit(current_item_index, get_child(current_item_index))
		return
	
	if event.is_action(control_backward.as_text()) && current_item_index > 0:
		current_item_index -= 1
		Audio.play_1d_sound(control_sound)
		selected.emit(current_item_index, get_child(current_item_index))
		return
