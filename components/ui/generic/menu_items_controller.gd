extends BoxContainer
class_name MenuItemsController
## Helps you create vertical and horizontal boxes with selection

## Does this controller currently accept input?
@export var focused: bool = true
## Currently selected item
@export var current_item_index: int = 0
## Control name that triggers the forward selection
@export var control_forward: StringName = "ui_down"
## Control name that triggers the backward selection
@export var control_backward: StringName = "ui_up"
## Sound of selection
@export var control_sound: AudioStream = preload("res://engine/components/ui/_sounds/select_main.wav")
## Whether to fire the selected event once immediately to update the selector's position
@export var trigger_selection_immediately: bool = true
@export_group("Previous Screen", "prev_screen")
## NodePath to a MenuSelection node with Exit selection behaviour
@export var prev_screen_node_path: NodePath
## Control name that triggers the transition to the previous screen
@export var prev_screen_control_cancel: StringName = "ui_cancel"

## Emitted when a selection occurs to update the position of selector
signal selected(item_index: int, item_node: Control, immediate: bool)

var selectors: Array

func _ready() -> void:
	for child in get_children():
		if child is HSeparator || child is VSeparator:
			continue
		selectors.push_back(child)
	
	if trigger_selection_immediately:
		selected.emit(current_item_index, selectors[current_item_index], true)
		selectors[current_item_index]._handle_focused(true)


func _physics_process(delta: float) -> void:
	if !focused: return
	
	var sel = current_item_index
	if Input.is_action_just_pressed(control_forward):
		current_item_index = 0 if sel + 1 > selectors.size() - 1 else current_item_index + 1
		_selection()
		return
	
	if Input.is_action_just_pressed(control_backward):
		current_item_index = selectors.size() - 1 if sel - 1 < 0 else current_item_index - 1
		_selection()
		return
	
	if has_node(prev_screen_node_path) && Input.is_action_just_pressed(prev_screen_control_cancel):
		get_node(prev_screen_node_path)._handle_select()


func move_selector(index: int) -> void:
	current_item_index = index
	_selection_update()


func _selection() -> void:
	if control_sound:
		Audio.play_1d_sound(control_sound)
	_selection_update()


func _selection_update() -> void:
	var item = selectors[current_item_index] as MenuSelection
	selected.emit(current_item_index, item, false)
	item._handle_focused(true)
	
	for selector in selectors:
		if selector != item && selector.focused:
			selector._handle_focused(false)
