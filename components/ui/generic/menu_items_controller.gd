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

func _ready() -> void:
	_update_selectors()

	if trigger_selection_immediately:
		selected.emit(current_item_index, selectors[current_item_index], true, false)
		selectors[current_item_index]._handle_focused(true)


func _physics_process(delta: float) -> void:
	if !focused: return

	var sel = current_item_index
	if Input.is_action_just_pressed(control_forward):
		current_item_index = 0 if sel + 1 > selectors.size() - 1 else current_item_index + 1
		_selection(false)
		return

	if Input.is_action_just_pressed(control_backward):
		current_item_index = selectors.size() - 1 if sel - 1 < 0 else current_item_index - 1
		_selection(false)
		return

	if has_node(prev_screen_node_path) && Input.is_action_just_pressed(prev_screen_control_cancel):
		get_node(prev_screen_node_path)._handle_select()


func move_selector(index: int, immediate: bool = false) -> void:
	current_item_index = index
	_selection_update(immediate)


func _update_selectors() -> void:
	selectors = []
	for child in get_children():
		if child is HSeparator || child is VSeparator:
			continue
		selectors.push_back(child)
		var area := Area2D.new()
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = child.size
		col.shape = shape
		child.add_child(area)
		area.global_position = child.global_position + (child.size / 2)
		area.add_child(col)
		area.mouse_entered.connect(_on_mouse_entered.bind(child))
		area.mouse_exited.connect(_on_mouse_exited.bind(child))
		area.input_event.connect(_on_area_2d_input_event.bind(child))


func _selection(mouse_input: bool = false) -> void:
	if control_sound:
		Audio.play_1d_sound(control_sound, true, { "ignore_pause": true, "bus": "1D Sound" })
	_selection_update(false, mouse_input)


func _selection_update(immediate: bool = false, mouse_input: bool = false) -> void:
	if selectors.size() <= current_item_index: return
	if !is_instance_valid(selectors[current_item_index]): return

	var item = selectors[current_item_index] as MenuSelection

	selected.emit(current_item_index, item, immediate, mouse_input)
	item._handle_focused(true)

	for selector in selectors:
		if selector != item && selector.focused:
			selector._handle_focused(false)


func _on_mouse_entered(item: Control) -> void:
	if !focused: return
	item.mouse_hovered = true
	current_item_index = selectors.find(item)
	_selection(true)


func _on_mouse_exited(item: Control) -> void:
	item.mouse_hovered = false


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int, item: Control) -> void:
	if !item.mouse_hovered: return
	if !focused: return

	if event is InputEventMouseButton && event.button_index == 1 && event.is_pressed():
		item._handle_select()
