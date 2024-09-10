extends Node

@export var menu_items_controller_path: NodePath

var items: Array[Control]

var _timer: float
var _prev_item: Control

@onready var menu_items_controller: MenuItemsController = get_node(menu_items_controller_path)

func _ready() -> void:
	for i in get_node(menu_items_controller_path).get_children():
		if i is Control:
			items.append(i)


func _physics_process(delta: float) -> void:
	if menu_items_controller.focused:
		_timer += delta * 10
		items[menu_items_controller.current_item_index].modulate.a = min((cos(_timer) / 2.5) + 0.6, 1.0)


func handle_selection(item_index: int, item_node: Control, immediate: bool) -> void:
	if _prev_item: _prev_item.modulate.a = 1
	_timer = 0
	_prev_item = item_node
