extends Control

@export var speed: float = 40

var _scroll_force: float
var _target_pos: float = position.y

func _ready() -> void:
	Thunder._connect(SettingsManager.mouse_pressed, func(index: MouseButton):
		match index:
			MOUSE_BUTTON_WHEEL_DOWN:
				_target_pos -= 40
			MOUSE_BUTTON_WHEEL_UP:
				_target_pos += 40
	)

func _physics_process(delta: float) -> void:
	_scroll_force = Input.get_axis(&"ui_down", &"ui_up") * 300
	
	var viewport_size_y = get_viewport_rect().size.y
	if position.y < -size.y:
		position.y += size.y + viewport_size_y
		_target_pos = position.y
		reset_physics_interpolation()
	elif position.y > viewport_size_y:
		position.y -= size.y + viewport_size_y
		_target_pos = position.y
		reset_physics_interpolation()
	
	_target_pos += _scroll_force * delta
	
	position.y = lerpf(position.y, _target_pos, 30.0 * delta)
	
	if _scroll_force:
		_scroll_force = 0.0
	else:
		_target_pos -= speed * delta
