extends MenuSelection

@export_node_path("MenuItemsController") var move_to_path: NodePath
@export_node_path("MenuSelector") var menu_selector_path: NodePath
@export var reset_to: int = -1

@onready var text_rect: CanvasItem = $Text
@onready var valu: CanvasItem = get_node_or_null(^"Value")
@onready var camera_2d: Camera2D = $"../../Camera2D"
@onready var move_to: MenuItemsController = get_node(move_to_path)
@onready var selector_to: MenuSelector = get_node(menu_selector_path)


func _process(_delta: float) -> void:
	if valu:
		valu.modulate.a = text_rect.modulate.a if focused else 0.0


func _handle_select(mouse_input: bool = false) -> void:
	super(mouse_input)

	var current_menu := get_parent() as MenuItemsController
	var old_selector: MenuSelector = camera_2d.selector

	current_menu.focused = false
	current_menu.visible = false
	if old_selector:
		old_selector.visible = false

	move_to.visible = true
	selector_to.visible = true
	camera_2d.menu_controller = move_to
	camera_2d.selector = selector_to
	camera_2d.position_smoothing_enabled = false
	camera_2d.reset_physics_interpolation()

	await get_tree().physics_frame

	if reset_to >= 0:
		current_menu.move_selector(reset_to, true)
	move_to.move_selector(move_to.current_item_index, true)
	move_to.focused = true
	current_menu.focused = false
