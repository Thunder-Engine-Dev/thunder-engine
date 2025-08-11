extends Node

@export var menu_items_controller_path: NodePath
@export var speed: float = 10
@export var modulate_division: float = 2.5
@export var modulate_offset: float = 0.6
@export var modulate_first_child: bool = false

var items: Array[CanvasItem]

var _timer: float
var _prev_item: CanvasItem

@onready var menu_items_controller: MenuItemsController = get_node(menu_items_controller_path)

func _ready() -> void:
	for i in get_node(menu_items_controller_path).get_children():
		if modulate_first_child:
			if i is Control && i.get_child_count() > 0 && i.get_child(0) is CanvasItem:
				items.append(i.get_child(0))
			continue
		if i is Control:
			items.append(i)


func _physics_process(delta: float) -> void:
	if !menu_items_controller.focused: return
	_timer += delta * speed
	items[menu_items_controller.current_item_index].modulate.a = min(
		(cos(_timer) / modulate_division) + modulate_offset, 1.0
	)


func handle_selection(item_index: int, item_node: Control, immediate: bool, mouse_input: bool = false) -> void:
	if _prev_item: _prev_item.modulate.a = 1
	_timer = 0
	if modulate_first_child:
		_prev_item = item_node.get_child(0)
		return
	_prev_item = item_node
