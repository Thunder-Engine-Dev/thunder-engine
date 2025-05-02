extends Control
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
## Can this controller accept input from the mouse cursor?
@export var mouse_input: bool = true
## Whether to fire the selected event once immediately to update the selector's position
@export var trigger_selection_immediately: bool = true
@export_group("Previous Screen", "prev_screen")
## NodePath to a MenuSelection node with Exit selection behaviour
@export var prev_screen_node_path: NodePath
## Control name that triggers the transition to the previous screen
@export var prev_screen_control_cancel: StringName = "ui_cancel"

## Emitted when a selection occurs to update the position of selector
signal selected(item_index: int, item_node: Control, immediate: bool, mouse_input: bool)

var selectors: Array
var selector_repeat_timer: float

func _ready() -> void:
	_update_selectors()
	SettingsManager.mouse_pressed.connect(_on_mouse_pressed)
	SettingsManager.mouse_moved.connect(_on_mouse_moved)
	#SettingsManager.mouse_released.connect(_on_mouse_released)

	if trigger_selection_immediately:
		selected.emit(current_item_index, selectors[current_item_index], true, false)
		selectors[current_item_index]._handle_focused(true)


var _mouse_can_process: bool
func _physics_process(delta: float) -> void:
	_mouse_can_process = false
	if !focused: return
	if selector_repeat_timer > 0: selector_repeat_timer -= delta

	if has_node(prev_screen_node_path) && Input.is_action_just_pressed(prev_screen_control_cancel):
		get_node(prev_screen_node_path)._handle_select(false)
	
	_mouse_can_process = true

func _input(event: InputEvent) -> void:
	if !focused: return
	if event.is_echo():
		if selector_repeat_timer > 0:
			return
		else:
			selector_repeat_timer = 0.06
	
	var sel = current_item_index
	if event.is_action_pressed(control_forward, true):
		current_item_index = 0 if sel + 1 > selectors.size() - 1 else current_item_index + 1
		_selection(false, event.is_echo())
		return

	if event.is_action_pressed(control_backward, true):
		current_item_index = selectors.size() - 1 if sel - 1 < 0 else current_item_index - 1
		_selection(false, event.is_echo())
		return


func move_selector(index: int, immediate: bool = false) -> void:
	current_item_index = index
	_selection_update(immediate)


func _update_selectors() -> void:
	selectors = []
	for child in get_children():
		if child is HSeparator || child is VSeparator:
			continue
		if child.is_queued_for_deletion():
			continue
		selectors.push_back(child)


func _selection(_mouse_input: bool = false, is_echo: bool = false) -> void:
	var _tw = SettingsManager.get_tweak("mouse_select_sound", true)
	if control_sound && ((!_tw && !_mouse_input) || _tw):
		Audio.play_1d_sound(control_sound, true,
			{
				"ignore_pause": true,
				"bus": "1D Sound",
				"volume": -6.0 if is_echo else 0.0
			}
		)
	_selection_update(false, _mouse_input)


func _selection_update(immediate: bool = false, _mouse_input: bool = false) -> void:
	if selectors.size() <= current_item_index: return
	if !is_instance_valid(selectors[current_item_index]): return

	var item = selectors[current_item_index] as MenuSelection

	selected.emit(current_item_index, item, immediate, _mouse_input)
	item._handle_focused(true)

	for selector in selectors:
		if selector != item && selector.focused:
			selector._handle_focused(false)


func _on_mouse_pressed(index: MouseButton) -> void:
	if !_can_mouse_process(): return
	if !_mouse_can_process: return
	
	for item in selectors:
		if !is_instance_valid(item): continue
		if !item is Control: continue
		if item.mouse_hovered && item.trigger_mouse:
			if index == MOUSE_BUTTON_LEFT:
				item._handle_select(true)
			elif index == MOUSE_BUTTON_RIGHT:
				item._handle_right_click()


func _on_mouse_moved() -> void:
	if !_can_mouse_process(): return
	
	for item in selectors:
		if !is_instance_valid(item): continue
		if !item is Control: continue
		if item.get_global_rect().has_point(item.get_global_mouse_position()):
			if item.mouse_hovered == false:
				item.mouse_hovered = true
				current_item_index = selectors.find(item)
				_selection(true)
		else:
			item.mouse_hovered = false
	
	_mouse_can_process = true


func _can_mouse_process() -> bool:
	if !focused: return false
	if !SettingsManager.get_tweak("mouse_in_menus", true): return false
	if get_tree().paused && !can_process(): return false
	if !get_tree().root.get_visible_rect().has_point(SettingsManager._current_mouse_pos): return false
	return true

#func _on_mouse_released(index: MouseButton) -> void:
#	pass
