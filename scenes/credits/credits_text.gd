extends Node2D

@export var speed: float = 25

@onready var first_pos: float = position.y
@onready var label_size: Vector2 = get_child(0).size
var _scroll_delay: float

func _ready() -> void:
	Thunder._connect(SettingsManager.mouse_pressed, func(index: MouseButton):
		match index:
			MOUSE_BUTTON_WHEEL_DOWN:
				_scroll_delay = 1.0
				position.y += 40
			MOUSE_BUTTON_WHEEL_UP:
				_scroll_delay = 1.0
				position.y -= 40
	)


func _physics_process(delta: float) -> void:
	if position.y < -label_size.y:
		position.y = first_pos
	elif position.y > label_size.y + 20:
		position.y = -label_size.y
	
	if Input.is_action_just_pressed(&"ui_down"):
		_scroll_delay = 1.0
		position.y += 40
	elif Input.is_action_just_pressed(&"ui_up"):
		_scroll_delay = 1.0
		position.y -= 40
	
	if _scroll_delay > 0.0:
		_scroll_delay -= delta
		return
	
	position.y -= speed * delta
