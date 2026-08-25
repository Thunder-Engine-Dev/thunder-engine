extends Control

@export var hide_bg: bool

@onready var _viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var _main_options: MenuItemsController = $SubViewportContainer/SubViewport/Options
@onready var _main_selector: MenuSelector = $SubViewportContainer/SubViewport/Selector


func _ready() -> void:
	reset_physics_interpolation()
	if hide_bg:
		$Bg.queue_free()
	reset_menus()


func reset_menus() -> void:
	for child in _viewport.get_children():
		if child is MenuItemsController:
			child.focused = false
			child.visible = child == _main_options
		elif child is MenuSelector:
			child.visible = child == _main_selector
	_main_options.visible = true
	_main_selector.visible = true
	var camera: Camera2D = _viewport.get_node_or_null("Camera2D")
	if camera:
		camera.menu_controller = _main_options
		camera.selector = _main_selector
		camera.position_smoothing_enabled = false
		camera.reset_physics_interpolation()


func unfocus_all_menus() -> void:
	for child in _viewport.get_children():
		if child is MenuItemsController:
			child.focused = false
