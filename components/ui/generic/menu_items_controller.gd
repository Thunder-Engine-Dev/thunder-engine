extends BoxContainer
class_name MenuItemsController
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
## Whether to fire the selected event once immediately to update the selector's position
@export var trigger_selection_immediately: bool = true

## Emitted when a selection occurs to update the position of selector
signal selected(item_index: int, item_node: Control, immediate: bool)


func _ready() -> void:
	if trigger_selection_immediately:
		selected.emit(current_item_index, get_child(current_item_index), true)
		get_child(current_item_index)._handle_focused(true)


func _input(event: InputEvent) -> void:
	if !focused: return
	if !event.is_pressed(): return
	
	if event.is_action(control_forward) && current_item_index < get_child_count() - 1:
		current_item_index += 1
		_selection()
		return
	
	if event.is_action(control_backward) && current_item_index > 0:
		current_item_index -= 1
		_selection()
		return


func _selection() -> void:
	if control_sound:
		Audio.play_1d_sound(control_sound)
	var item = get_child(current_item_index) as MenuSelection
	selected.emit(current_item_index, item, false)
	item._handle_focused(true)
	
	for i in get_children():
		if i != item && i.focused:
			i._handle_focused(false)
