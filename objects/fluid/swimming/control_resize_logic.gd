@tool
extends Control

@export var border_color: Color = Color.BLUE
@onready var area: Area2D = $Area2D
@export var border_enabled: bool = true


func _ready() -> void:
	if Engine.is_editor_hint(): return
	assert(area, "[%s]: The child_area node is not set" % get_path())
	
	if !area: return
	
	resized.connect(_set_scale)
	_set_scale()

func _draw() -> void:
	if !Engine.is_editor_hint(): return
	if !border_enabled: return
	draw_set_transform(-global_position, rotation, Vector2.ONE)
	draw_rect(get_rect().abs(), border_color, false, 4)

func _set_scale() -> void:
	area.scale = get_rect().size
	area.position = get_rect().size / 2
