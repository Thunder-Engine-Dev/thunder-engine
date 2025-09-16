extends Camera2D

@export var menu_controller_path: NodePath = ^"../Options"

var _mouse_input: bool
@onready var selector: MenuSelector = $"../Selector"
@onready var menu_controller: MenuItemsController = get_node_or_null(menu_controller_path)

## Handles the selection change, used as a signal handler
func handle_selection(item_index: int, item_node: Control, immediate: bool, mouse_input: bool = false) -> void:
	_mouse_input = mouse_input
	position_smoothing_enabled = _mouse_input
	#if immediate:
	#	global_position = selector.global_position


func _ready() -> void:
	SettingsManager.mouse_pressed.connect(_on_mouse_pressed)


func _physics_process(delta: float) -> void:
	if !_mouse_input:
		global_position = selector.global_position
	

func _on_mouse_pressed(index: MouseButton) -> void:
	if index != MOUSE_BUTTON_WHEEL_DOWN && index != MOUSE_BUTTON_WHEEL_UP:
		return
	if !menu_controller.focused:
		return
	
	_mouse_input = true
	position_smoothing_enabled = true
	
	position = position.clamp(
		Vector2(limit_left + 320, limit_top + 240),
		Vector2(limit_right - 320, limit_bottom - 240)
	)

	if index == MOUSE_BUTTON_WHEEL_DOWN:
		position.y += 40
	elif index == MOUSE_BUTTON_WHEEL_UP:
		position.y -= 40
